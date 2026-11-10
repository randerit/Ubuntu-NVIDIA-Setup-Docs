#!/bin/bash
# Self-check de los chequeos de red de doctor_lib.sh (Sección 14 Caso C).
# No toca el sistema: arma árboles falsos en un tmpdir. Correr desde el repo:
#   ./self_check_doctor_lib.sh
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

# doctor_lib.sh define colores y contadores y espera FIX_MODE; solo se necesitan
# las funciones, así que se sourcea con lo mínimo.
# shellcheck disable=SC2034  # lo consume doctor_lib.sh, no este script
FIX_MODE=false
# shellcheck source=doctor_lib.sh
source ./doctor_lib.sh >/dev/null 2>&1 || true

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
fallos=0

t() {  # t <descripcion> <esperado 0|1> <comando...>
  local desc="$1" esperado="$2"; shift 2
  "$@" >/dev/null 2>&1
  local rc=$?
  (( rc == esperado )) || { echo "   FALLA: $desc (esperado rc=$esperado, obtenido $rc)"; fallos=$((fallos+1)); }
}

echo "1. check_nic_driver_bound"
mkdir -p "$TMP/pci/0000:07:00.0" "$TMP/pci/0000:00:1f.3"
echo 0x020000 >"$TMP/pci/0000:07:00.0/class"     # Ethernet sin driver
echo 0x040300 >"$TMP/pci/0000:00:1f.3/class"     # audio sin driver, no cuenta
t "Ethernet sin driver tiene que fallar" 1 check_nic_driver_bound "$TMP/pci"
mkdir -p "$TMP/drivers/r8125"
ln -s "$TMP/drivers/r8125" "$TMP/pci/0000:07:00.0/driver"
t "Ethernet con driver tiene que pasar" 0 check_nic_driver_bound "$TMP/pci"
t "equipo sin NIC PCI no puede dar error" 0 check_nic_driver_bound "$TMP/vacio"

echo "2. check_dkms_current_kernel"
STATUS_OK='nvidia/580.173.02, 6.8.0-138-generic, x86_64: installed
realtek-r8125/9.016.01, 6.8.0-138-generic, x86_64: installed'
STATUS_VIEJO='nvidia/580.173.02, 6.8.0-138-generic, x86_64: installed
realtek-r8125/9.016.01, 6.8.0-137-generic, x86_64: installed'
t "todos los módulos al día" 0 check_dkms_current_kernel "$STATUS_OK" 6.8.0-138-generic
t "r8125 solo para el kernel anterior" 1 check_dkms_current_kernel "$STATUS_VIEJO" 6.8.0-138-generic
t "sin DKMS instalado no es un error" 0 check_dkms_current_kernel " " 6.8.0-138-generic

echo "3. check_no_r8169_blacklist"
mkdir -p "$TMP/modprobe"
echo 'options r8169 foo=1' >"$TMP/modprobe/limpio.conf"
t "sin blacklist tiene que pasar" 0 check_no_r8169_blacklist "$TMP/modprobe"
echo 'blacklist   r8169' >"$TMP/modprobe/r8125.conf"
t "blacklist de r8169 tiene que fallar" 1 check_no_r8169_blacklist "$TMP/modprobe"

echo "4. ubuntu_base_version / ubuntu_base_codename"
# Cada caso es una raíz falsa con su /etc/os-release (y su upstream-release si
# la distro es un derivado). Mint no publica VERSION_ID de Ubuntu: 22.1 es la
# versión de Mint, así que la base tiene que salir de upstream-release.
distro() {  # distro <nombre> <os-release> [upstream-release]
  local d="$TMP/distros/$1"
  mkdir -p "$d/etc"
  printf '%s\n' "$2" >"$d/etc/os-release"
  if [ -n "${3:-}" ]; then
    mkdir -p "$d/etc/upstream-release"
    printf '%s\n' "$3" >"$d/etc/upstream-release/lsb-release"
  fi
  echo "$d"
}

to() {  # to <descripcion> <esperado> <comando...>
  local desc="$1" esperado="$2"; shift 2
  local obtenido
  obtenido=$("$@" 2>/dev/null)
  [ "$obtenido" = "$esperado" ] || { echo "   FALLA: $desc (esperado '$esperado', obtenido '$obtenido')"; fallos=$((fallos+1)); }
}

UBUNTU2404=$(distro ubuntu2404 'ID=ubuntu
VERSION_ID="24.04"
UBUNTU_CODENAME=noble')
UBUNTU2204=$(distro ubuntu2204 'ID=ubuntu
VERSION_ID="22.04"
UBUNTU_CODENAME=jammy')
MINT221=$(distro mint221 'ID=linuxmint
ID_LIKE="ubuntu debian"
VERSION_ID="22.1"
UBUNTU_CODENAME=noble' 'DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=24.04
DISTRIB_CODENAME=noble')
MINT_SIN_UPSTREAM=$(distro mint_sin_upstream 'ID=linuxmint
ID_LIKE="ubuntu debian"
VERSION_ID="22.1"
UBUNTU_CODENAME=noble')
LMDE6=$(distro lmde6 'ID=linuxmint
ID_LIKE=debian
VERSION_ID="6"' 'DISTRIB_ID=Debian
DISTRIB_RELEASE=12')
DEBIAN12=$(distro debian12 'ID=debian
VERSION_ID="12"')

to "Ubuntu 24.04 se reporta tal cual" "24.04" ubuntu_base_version "$UBUNTU2404"
to "Ubuntu 22.04 se reporta tal cual" "22.04" ubuntu_base_version "$UBUNTU2204"
to "Mint 22.1 tiene que dar la base 24.04, no 22.1" "24.04" ubuntu_base_version "$MINT221"
to "Mint sin upstream-release cae en UBUNTU_CODENAME" "24.04" ubuntu_base_version "$MINT_SIN_UPSTREAM"
t "LMDE (base Debian) no es base Ubuntu" 1 ubuntu_base_version "$LMDE6"
t "Debian puro no es base Ubuntu" 1 ubuntu_base_version "$DEBIAN12"
to "el codename de Mint 22.x es noble, no wilma" "noble" ubuntu_base_codename "$MINT221"
to "el codename de Ubuntu 22.04 es jammy" "jammy" ubuntu_base_codename "$UBUNTU2204"
t "sin base Ubuntu no hay codename" 1 ubuntu_base_codename "$DEBIAN12"

echo
echo "5. check_nvidia_gpu (por sysfs, sin lspci)"
# El bug que esto fija: "lspci | grep -qi nvidia" contesta "no hay GPU" en
# cuanto lspci escribe mas de un bloque de 4 KB, porque grep -q corta el pipe y
# pipefail propaga el SIGPIPE. Driver andando, nvidia-smi feliz, y el doctor
# marcando la GPU como ausente. Sysfs no tiene pipe ni depende de pciutils.
gpu_root() {  # gpu_root <nombre> <vendor...>
  local dir="$TMP/$1" n=0 v
  shift
  for v in "$@"; do
    mkdir -p "$dir/sys/bus/pci/devices/0000:0$n:00.0"
    printf '%s\n' "$v" >"$dir/sys/bus/pci/devices/0000:0$n:00.0/vendor"
    n=$((n + 1))
  done
  mkdir -p "$dir/sys/bus/pci/devices"
  printf '%s\n' "$dir"
}
# nvidia-smi no debe entrar como fallback en estos casos: se anula.
nvidia-smi() { return 1; }

t "vendor 0x10de presente = hay GPU" 0 check_nvidia_gpu "$(gpu_root solo_nvidia 0x10de)"
t "0x10de entre otras placas = hay GPU" 0 check_nvidia_gpu "$(gpu_root entre_otras 0x8086 0x1002 0x10de)"
t "sin 0x10de = no hay GPU" 1 check_nvidia_gpu "$(gpu_root sin_nvidia 0x8086 0x10ec)"
t "sysfs vacio = no hay GPU" 1 check_nvidia_gpu "$(gpu_root vacio)"

echo
echo "6. unblock_snapd (Linux Mint)"
# Mint trae /etc/apt/preferences.d/nosnap.pref y sin sacarlo apt deja snapd sin
# candidato: cualquier "snap install" muere con un "command not found". El
# doctor --fix lo saca, pero con respaldo: revertir tiene que ser un mv.
sudo() { "$@"; }            # el self-check no eleva privilegios
apt-get() { :; }            # ni toca los índices de apt
NOSNAP_PREF="$TMP/nosnap/etc/apt/preferences.d/nosnap.pref"
NOSNAP_BACKUP="$TMP/nosnap/var/backups/nosnap.pref.bak"
mkdir -p "$(dirname "$NOSNAP_PREF")"
printf 'Package: snapd\nPin: release a=*\nPin-Priority: -10\n' >"$NOSNAP_PREF"

t "quitar el bloqueo de snapd sale 0" 0 unblock_snapd
t "nosnap.pref ya no está" 1 test -f "$NOSNAP_PREF"
t "quedó el respaldo, para poder revertir" 0 test -s "$NOSNAP_BACKUP"
t "idempotente: sin el archivo no falla" 0 unblock_snapd
to "el respaldo es el archivo original" "Pin-Priority: -10" tail -1 "$NOSNAP_BACKUP"

echo
echo "7. libtinfo5_url"
# El pool de security borra las versiones superadas: la URL fija a
# 6.3-2ubuntu0.1 dio 404 cuando salió la 0.3 y el --fix no instalaba nada.
wget() {  # índice falso del pool; solo responde a la descarga del índice
  case "$*" in *qO-*) printf '%b' "$INDICE" ;; esac
}
INDICE='<a href="libtinfo5_6.2-0ubuntu2.1_amd64.deb">x</a>\n'
INDICE+='<a href="libtinfo5_6.3-2_amd64.deb">x</a>\n'
INDICE+='<a href="libtinfo5_6.3-2ubuntu0.3_amd64.deb">x</a>\n'
INDICE+='<a href="libtinfo5_6.3-2ubuntu0.3_i386.deb">x</a>\n'
to "toma la última 6.3-2 amd64" \
   "$LIBTINFO5_POOL/libtinfo5_6.3-2ubuntu0.3_amd64.deb" libtinfo5_url
INDICE=''
t "sin índice falla en vez de devolver una URL vacía" 1 libtinfo5_url
unset -f wget
t "ninguna URL de libtinfo5 con versión fija" 1 \
  grep -qE 'libtinfo5_[0-9][0-9.a-z~+-]*_amd64\.deb' doctor_lib.sh

echo
echo "8. cada sección nombra el instalador que la arregla"
# En terreno el doctor del perfil mostró rojos de CUDA y de puertos, que no son
# del perfil, y no había forma de saber qué reejecutar.
to "section muestra el responsable" "  6. CUDA Toolkit  (→ nvidia-cuda-setup)" \
   bash -c 'source ./doctor_lib.sh >/dev/null 2>&1; BOLD=; NC=; section "6. CUDA Toolkit" nvidia-cuda-setup | sed -n 3p'
to "section sin responsable queda igual" "  1. Sistema Operativo" \
   bash -c 'source ./doctor_lib.sh >/dev/null 2>&1; BOLD=; NC=; section "1. Sistema Operativo" | sed -n 3p'
for d in doctor_compresion.sh doctor_analitica.sh doctor_visualizacion.sh; do
  while IFS= read -r linea; do
    [[ "$linea" == 'section "1. Sistema Operativo"' ]] && continue
    grep -qE '^section "[^"]+" "workstation-(nvidia-setup|dependencies|workstation-hardening)"$' <<<"$linea" \
      || { echo "   FALLA: $d sin responsable: $linea"; fallos=$((fallos+1)); }
  done < <(grep -E '^section "' "$d")
done
for d in doctor_compresion.sh doctor_analitica.sh doctor_visualizacion.sh; do
  grep -qxF 'section "4. SSH y Firewall" "workstation-dependencies"' "$d" \
    || { echo "   FALLA: $d section 4 debe ser workstation-dependencies"; fallos=$((fallos+1)); }
done

echo
echo "9. cuatro niveles de alerta: significado unico"
# Cada nivel tiene un simbolo, una etiqueta y un destino en el contador. El exit
# del doctor cuenta solo lo necesario ([FALLO]); recomendados y opcionales no
# bloquean. Antes [AVISO] decia "(opcional)" y el resumen lo llamaba "criticos".
nivel() {  # nivel <funcion> <simbolo> <etiqueta> <contadores esperados>
  local fn="$1" sym="$2" etq="$3" esperado="$4" out
  out=$(bash -c "source ./doctor_lib.sh >/dev/null 2>&1; $fn 'X' false; echo \"CNT f=\$failed w=\$warnings m=\$minors\"" 2>&1)
  if ! grep -q "\[$sym\]" <<<"$out" || ! grep -qF "$etq" <<<"$out" || ! grep -qF "$esperado" <<<"$out"; then
    echo "   FALLA: $fn no sale como [$sym] '$etq' con $esperado: $(tr '\n' ' ' <<<"$out")"
    fallos=$((fallos+1))
  fi
}
nivel check_and_fix        FALLO  ""             "CNT f=1 w=0 m=0"
nivel check_and_fix_warn   AVISO  "(recomendado)" "CNT f=0 w=1 m=0"
nivel check_and_fix_nota   NOTA   "(opcional)"    "CNT f=0 w=0 m=1"
t "check_and_fix_nota existe" 0 grep -q '^check_and_fix_nota()' doctor_lib.sh
t "resumen usa 'Recomendadas ([AVISO])'" 0 grep -qF 'Recomendadas ([AVISO])' doctor_lib.sh
t "resumen usa 'Opcionales ([NOTA])'" 0 grep -qF 'Opcionales ([NOTA])' doctor_lib.sh
t "resumen ya no dice 'criticos'" 1 grep -qi 'criticos' doctor_lib.sh
t "leyenda de los cuatro niveles" 0 bash -c 'grep -q necesario doctor_lib.sh && grep -q recomendado doctor_lib.sh && grep -q opcional doctor_lib.sh'
t "[AVISO] ya no lleva '(opcional)'" 1 bash -c 'grep -E "check_and_fix_warn " doctor_compresion.sh doctor_analitica.sh doctor_visualizacion.sh | grep -q "opcional"'
t "ningun [AVISO] escrito a mano dice 'opcional'" 1 bash -c 'grep -E "WARN\}.*opcional" doctor_compresion.sh doctor_analitica.sh doctor_visualizacion.sh | grep -q .'
t "ningun [NOTA] escrito a mano dice 'recomendado'" 1 bash -c 'grep -E "MINOR\}.*recomendado" doctor_compresion.sh doctor_analitica.sh doctor_visualizacion.sh | grep -q .'
for d in doctor_compresion.sh doctor_analitica.sh doctor_visualizacion.sh; do
  t "$d sale con el conteo de fallos, no de avisos" 0 grep -qF 'exit $((failed > 255 ? 1 : failed))' "$d"
done

echo "10. clasificacion por perfil: cada check en su nivel"
# Contrato: lo que el perfil no necesita no puede contar como [FALLO]. Las
# descripciones se buscan por prefijo, con la funcion exacta que las verifica.
NOTA_COMUN=("htop instalado" "ncdu instalado" "tree instalado" "traceroute instalado"
            "nmap instalado" "inxi instalado" "net-tools instalado" "lm-sensors instalado"
            "neofetch instalado" "mesa-utils instalado" "vim instalado"
            "libtinfo5 instalado")
NOTA_COMPRESION=("Go instalado" "VSCode instalado" "Angry IP Scanner instalado"
                 "RustDesk instalado" "MongoDB Compass")
NOTA_VISUALIZACION=("Go instalado" "VSCode instalado" "MongoDB Compass")
NOTA_ANALITICA=("pandas instalado" "numpy instalado" "scikit-learn instalado"
                "paho-mqtt instalado" "ultralytics instalado" "Node-RED instalado"
                "Servicio nodered activo" "Servicio nodered habilitado al inicio")
for d in doctor_compresion.sh doctor_analitica.sh doctor_visualizacion.sh; do
  extra=("${NOTA_COMPRESION[@]}")
  [[ "$d" == doctor_analitica.sh ]] && extra=("${NOTA_ANALITICA[@]}")
  [[ "$d" == doctor_visualizacion.sh ]] && extra=("${NOTA_VISUALIZACION[@]}")
  for desc in "${NOTA_COMUN[@]}" "${extra[@]}"; do
    # Si la linea del check no existe, el grep falla y eso tambien es un fallo.
    # Los bloques compartidos (Compass, EMQX...) viven en doctor_lib.sh.
    grep -qF "check_and_fix_nota \"$desc" "$d" doctor_lib.sh \
      || { echo "   FALLA: $d: '$desc' no es check_and_fix_nota"; fallos=$((fallos+1)); }
    grep -qF "check_and_fix \"$desc" "$d" doctor_lib.sh \
      && { echo "   FALLA: $d: '$desc' sigue como [FALLO]"; fallos=$((fallos+1)); }
    grep -qF "check_and_fix_warn \"$desc" "$d" doctor_lib.sh \
      && { echo "   FALLA: $d: '$desc' sigue como [AVISO]"; fallos=$((fallos+1)); }
  done
done
t "libtinfo5 ya no dice 'requerido en 24.04'" 1 grep -qF 'requerido en 24.04' doctor_compresion.sh doctor_analitica.sh doctor_visualizacion.sh

echo "11. --skip-* del perfil: lo que el instalador omitio no cuenta como [FALLO]"
# workstation-dependencies pasa a su doctor los mismos --skip-* con que se corrio.
# Sin esto, un equipo sin EMQX o sin MongoDB sale con fallos que no son suyos.
t "parse_args acepta --skip-emqx y --skip-mongodb" 0 bash -c 'source ./doctor_lib.sh >/dev/null 2>&1; parse_args --skip-emqx --skip-mongodb && [[ "$SKIP_EMQX" == true && "$SKIP_MONGODB" == true ]]'
t "parse_args acepta los demas --skip-* de los perfiles" 0 bash -c 'source ./doctor_lib.sh >/dev/null 2>&1; parse_args --skip-snaps --skip-ml --skip-nodered --skip-mongo-auth'
t "parse_args sigue rechazando un flag desconocido" 1 bash -c 'source ./doctor_lib.sh >/dev/null 2>&1; parse_args --skip-inventado'
t "doctor_lib define SKIP_EMQX y SKIP_MONGODB por defecto en false" 0 grep -qE '^SKIP_(EMQX|MONGODB)=false' doctor_lib.sh
t "doctor_lib omite el bloque EMQX con --skip-emqx" 0 grep -qF 'if $SKIP_EMQX; then' doctor_lib.sh
for d in doctor_compresion.sh doctor_visualizacion.sh; do
  t "$d usa el bloque EMQX compartido" 0 grep -qxF 'check_bloque_emqx' "$d"
done
for d in doctor_compresion.sh doctor_analitica.sh doctor_visualizacion.sh; do
  t "$d omite el bloque MongoDB con --skip-mongodb" 0 grep -qF 'if $SKIP_MONGODB; then' "$d"
done

echo "12. libtinfo5: la etiqueta dice que es opcional y como se instala"
# libtinfo5 es opcional (manual). La corrida por defecto ya no la instala: la
# etiqueta nombra el flag y dice que solo hace falta si CUDA o una herramienta
# antigua la pide. No debe presentarla como requisito del equipo.
for d in doctor_compresion.sh doctor_analitica.sh doctor_visualizacion.sh; do
  t "$d: libtinfo5 nombra el flag --libtinfo5" 0 grep -qF 'nvidia-cuda-setup --libtinfo5' "$d"
  t "$d: libtinfo5 dice que es opcional" 0 grep -qF 'opcional' "$d"
  t "$d: libtinfo5 no se presenta como requisito" 1 grep -qiE 'requerid|obligator' <(grep 'libtinfo5 instalado' "$d")
done

echo "13. respuesta guardada sobre MongoDB: el doctor la lee sin preguntar"
# workstation-dependencies pregunta una vez por equipo si usa MongoDB y guarda la
# respuesta en /etc/workstation/mongodb (si|no), igual que el perfil. El doctor la
# lee: "no" saltea los chequeos de MongoDB; "si" o ausente los corre.
# WORKSTATION_CONF_DIR permite apuntar a un directorio de prueba.
TMP_CONF=$(mktemp -d)
trap 'rm -rf "$TMP_CONF"' EXIT
# estado_mongo <respuesta|-> [flags...]: escribe la respuesta (o la borra con -)
# y devuelve SKIP_MONGODB tal como lo deja parse_args en un doctor nuevo.
estado_mongo() {
  local respuesta="$1"; shift
  if [[ "$respuesta" == "-" ]]; then rm -f "$TMP_CONF/mongodb"; else printf '%s\n' "$respuesta" >"$TMP_CONF/mongodb"; fi
  WORKSTATION_CONF_DIR="$TMP_CONF" bash -c 'source ./doctor_lib.sh >/dev/null 2>&1; parse_args "$@"; echo "$SKIP_MONGODB"' _ "$@" 2>/dev/null
}

[[ "$(estado_mongo no)" == true ]] || { echo "   FALLA: respuesta 'no' no salta MongoDB"; fallos=$((fallos+1)); }
[[ "$(estado_mongo si)" == false ]] || { echo "   FALLA: respuesta 'si' no corre MongoDB"; fallos=$((fallos+1)); }
[[ "$(estado_mongo -)" == false ]] || { echo "   FALLA: sin respuesta guardada no corre MongoDB"; fallos=$((fallos+1)); }
[[ "$(estado_mongo si --skip-mongodb)" == true ]] || { echo "   FALLA: --skip-mongodb no gana sobre una respuesta 'si'"; fallos=$((fallos+1)); }
t "doctor_lib lee la ruta con WORKSTATION_CONF_DIR" 0 grep -qF 'WORKSTATION_CONF_DIR:-/etc/workstation' doctor_lib.sh
t "doctor_lib lee el archivo mongodb" 0 grep -qF '/mongodb"' doctor_lib.sh

echo "14. doctor_visualizacion.sh: solo lo que el perfil instala, con --skip-* honrados"
# Perfil visualizacion: abre las interfaces web y mira el software. Lleva base,
# MongoDB + Compass, EMQX, AnyDesk con override X11, Go y VS Code (snap). No lleva
# GStreamer (runtime), RustDesk, Angry IP, stack ML ni Node-RED, ni abre RTSP/1880.
# Se corre el doctor entero con sudo/ufw/ping/host falsos: sin root, sin red.
t "doctor_visualizacion.sh existe" 0 test -f doctor_visualizacion.sh
t "doctor_visualizacion.sh pasa bash -n" 0 bash -n doctor_visualizacion.sh
STUBS="$TMP/stubs"
mkdir -p "$STUBS"
printf '#!/bin/sh\nexec "$@"\n' >"$STUBS/sudo"
printf '#!/bin/sh\nexit 0\n' >"$STUBS/ping"
cp "$STUBS/ping" "$STUBS/host"
printf '#!/bin/sh\necho "Status: active"\nfor p in 22 27017 1883 18083 554 1880 80 443 6568 50001:50003; do echo "$p ALLOW Anywhere"; done\n' >"$STUBS/ufw"
chmod +x "$STUBS"/*
# doctor_salida <doctor> [flags...]: salida sin colores y el exit code en la ultima linea
doctor_salida() {
  local d="$1"; shift
  PATH="$STUBS:$PATH" WORKSTATION_CONF_DIR="$TMP/sin_conf" timeout 120 bash "$d" "$@" </dev/null 2>&1 \
    | sed 's/\x1b\[[0-9;]*m//g'
  echo "RC=${PIPESTATUS[0]}"
}
VIZ_FULL=$(doctor_salida doctor_visualizacion.sh)
VIZ_SKIP=$(doctor_salida doctor_visualizacion.sh --skip-mongodb --skip-emqx --skip-snaps)
tiene() {  # tiene <esperado 0|1> <descripcion> <texto> <patron fijo>
  local esperado="$1" desc="$2" texto="$3" patron="$4" rc=0
  grep -qF -- "$patron" <<<"$texto" || rc=1
  (( rc == esperado )) || { echo "   FALLA: $desc ('$patron')"; fallos=$((fallos+1)); }
}
for c in "Servicio mongod activo" "MongoDB Compass" "EMQX instalado" "Go instalado" \
         "VSCode instalado" "AnyDesk con override X11" "Docker" "ffmpeg" "MQTTX"; do
  tiene 0 "sin flags el doctor verifica" "$VIZ_FULL" "$c"
done
tiene 0 "--skip-mongodb avisa que omite MongoDB" "$VIZ_SKIP" "MongoDB omitido"
tiene 0 "--skip-emqx avisa que omite EMQX" "$VIZ_SKIP" "EMQX omitido (--skip-emqx)"
tiene 0 "--skip-snaps avisa que omite Go y VS Code" "$VIZ_SKIP" "(--skip-snaps)"
for c in "Servicio mongod activo" "MongoDB Compass" "EMQX instalado" "Go instalado" "VSCode instalado"; do
  tiene 1 "con --skip-* no se verifica" "$VIZ_SKIP" "$c"
done
tiene 0 "con --skip-* AnyDesk se sigue verificando" "$VIZ_SKIP" "AnyDesk con override X11"
for c in "gst-launch" "RTSP" "Plugin base" "RustDesk" "Angry IP" "Node-RED" "pandas" "ultralytics" "(554)" "(1880)"; do
  tiene 1 "visualizacion no verifica lo de otros perfiles" "$VIZ_FULL" "$c"
done
for c in "(22)" "(27017)" "(1883)" "(18083)" "(80)" "(443)" "(6568)" "(50001-50003)"; do
  tiene 0 "puerto del perfil verificado" "$VIZ_FULL" "$c"
done
# Contrato de exit code: cantidad de [FALLO] (tope 1 si pasa de 255).
for v in FULL SKIP; do
  salida_v="VIZ_$v"
  n=$(grep -c '^  \[FALLO\]' <<<"${!salida_v}")
  rc_v=$(sed -n 's/^RC=//p' <<<"${!salida_v}")
  (( n > 255 )) && n=1
  [[ "$rc_v" == "$n" ]] || { echo "   FALLA: visualizacion ($v) sale con rc=$rc_v y tiene $n [FALLO]"; fallos=$((fallos+1)); }
done
t "visualizacion rechaza un flag desconocido" 1 bash doctor_visualizacion.sh --skip-inventado
# Lo compartido con compresion se movio a doctor_lib.sh: compresion no cambia.
COMP_FULL=$(doctor_salida doctor_compresion.sh)
for c in "(554)" "(50001-50003)" "AnyDesk con override X11" "EMQX instalado" "MongoDB Compass"; do
  tiene 0 "compresion conserva sus checks compartidos" "$COMP_FULL" "$c"
done

echo "15. UFW: puertos de lo omitido y deteccion del firewall activo"
# Dos defectos del bloque de puertos: (1) --skip-mongodb / --skip-emqx dejaban el
# doctor verificando (y con --fix abriendo) 27017/1883/18083 de un componente que
# el equipo no tiene; (2) "grep -q active" tambien acepta "Status: inactive", y
# con el idioma del sistema en espanol ufw dice "Estado: activo", asi que un
# firewall activo tampoco se reconocia; (3) si sudo no podia correr ufw, la captura
# quedaba vacia y el doctor decia "UFW no activo" en silencio. ufw se consulta con
# "LC_ALL=C sudo ufw status": sudo conserva LC_* por su tabla env_check, y el comando
# que sudo compara con el sudoers sigue siendo ufw (con "sudo env" seria env). El
# test se ancla a la linea de estado.
STUBS15="$TMP/stubs15"
mkdir -p "$STUBS15"
# sudo falso como el de un sudoers que solo permite ufw: rechaza cualquier otro
# comando y no toca el entorno (LC_ALL=C llega a ufw). ufw falso: responde en
# espanol salvo bajo LC_ALL=C y registra cada regla que se le pide abrir.
printf '#!/bin/sh\n[ "$1" = ufw ] || exit 1\nexec "$@"\n' >"$STUBS15/sudo"
cat >"$STUBS15/ufw" <<'EOF'
#!/bin/sh
case "$1" in
  status)
    if [ "$UFW_FAKE" = inactive ]; then
      [ "$LC_ALL" = C ] && echo "Status: inactive" || echo "Estado: inactivo"
      exit 0
    fi
    [ "$LC_ALL" = C ] && echo "Status: active" || echo "Estado: activo"
    for p in 22 27017 1883 18083 554 1880 80 443 6568 50001:50003; do echo "$p ALLOW Anywhere"; done
    ;;
  *) echo "$*" >>"$UFW_LOG" ;;
esac
EOF
cp "$STUBS/ping" "$STUBS15/ping"; cp "$STUBS/ping" "$STUBS15/host"
chmod +x "$STUBS15"/*

# puertos_base <skip_mongodb> <skip_emqx>: check_puertos_ufw_base con --fix y un
# UFW_STATUS vacio (falta todo). Imprime la salida y, despues, las reglas que se
# intentaron abrir.
puertos_base() {
  local log="$TMP/ufw15.log"; : >"$log"
  PATH="$STUBS15:$PATH" UFW_LOG="$log" bash -c '
    source ./doctor_lib.sh >/dev/null 2>&1
    SKIP_MONGODB=$1; SKIP_EMQX=$2; FIX_MODE=true; LOG_FILE=/dev/null
    UFW_STATUS=""
    check_puertos_ufw_base' _ "$1" "$2" 2>&1 | sed 's/\x1b\[[0-9;]*m//g'
  echo "ABIERTOS: $(tr '\n' ' ' <"$log")"
}
B_NADA=$(puertos_base false false)
B_MONGO=$(puertos_base true false)
B_EMQX=$(puertos_base false true)
B_AMBOS=$(puertos_base true true)
tiene 0 "sin skips se verifica y abre 27017" "$B_NADA" "allow 27017/tcp"
tiene 0 "sin skips se verifica y abre 1883" "$B_NADA" "allow 1883/tcp"
tiene 0 "sin skips se verifica y abre 18083" "$B_NADA" "allow 18083/tcp"
tiene 1 "--skip-mongodb no verifica 27017" "$B_MONGO" "(27017)"
tiene 1 "--skip-mongodb no abre 27017" "$B_MONGO" "27017"
tiene 0 "--skip-mongodb sigue con EMQX 1883" "$B_MONGO" "allow 1883/tcp"
tiene 0 "--skip-mongodb sigue con EMQX 18083" "$B_MONGO" "allow 18083/tcp"
tiene 1 "--skip-emqx no verifica 1883" "$B_EMQX" "(1883)"
tiene 1 "--skip-emqx no verifica 18083" "$B_EMQX" "(18083)"
tiene 1 "--skip-emqx no abre 1883" "$B_EMQX" "allow 1883/tcp"
tiene 1 "--skip-emqx no abre 18083" "$B_EMQX" "allow 18083/tcp"
tiene 0 "--skip-emqx sigue con MongoDB 27017" "$B_EMQX" "allow 27017/tcp"
tiene 0 "ambos skips: SSH 22 se sigue verificando" "$B_AMBOS" "(22)"
tiene 0 "ambos skips: SSH 22 se sigue abriendo" "$B_AMBOS" "allow ssh"
tiene 1 "ambos skips: ningun puerto de MongoDB/EMQX" "$B_AMBOS" "(27017)"
tiene 1 "ambos skips: ni 1883" "$B_AMBOS" "1883"
tiene 1 "ambos skips: ni 18083" "$B_AMBOS" "18083"

# ufw_esta_activo: solo la linea de estado "Status: active" vale.
activo() {  # activo <estado>
  bash -c 'source ./doctor_lib.sh >/dev/null 2>&1; UFW_STATUS=$1; ufw_esta_activo' _ "$1" >/dev/null 2>&1
}
activo $'Status: active\n22 ALLOW Anywhere'    || { echo "   FALLA: 'Status: active' no se reconoce como activo"; fallos=$((fallos+1)); }
activo $'Status: active (logging on)\nx'       || { echo "   FALLA: 'Status: active' con sufijo no se reconoce como activo"; fallos=$((fallos+1)); }
! activo "Status: inactive"                    || { echo "   FALLA: 'Status: inactive' se toma por activo"; fallos=$((fallos+1)); }
! activo ""                                    || { echo "   FALLA: un estado vacio se toma por activo"; fallos=$((fallos+1)); }
! activo $'Status: inactive\n22 ALLOW active'  || { echo "   FALLA: 'active' en otra linea se toma por activo"; fallos=$((fallos+1)); }

# ufw_capturar_estado: en un sistema en espanol (LANG/LANGUAGE en es, LC_ALL sin
# fijar) igual tiene que leer "Status: active". sudo falso: solo deja pasar ufw.
ES='env -u LC_ALL LANG=es_ES.UTF-8 LANGUAGE=es'
t "ufw_capturar_estado lee el estado en C aunque el sistema este en espanol" 0 \
  $ES PATH="$STUBS15:$PATH" bash -c 'source ./doctor_lib.sh >/dev/null 2>&1; ufw_capturar_estado; ufw_esta_activo'
t "ufw_capturar_estado con firewall inactivo no lo da por activo" 1 \
  $ES PATH="$STUBS15:$PATH" UFW_FAKE=inactive bash -c 'source ./doctor_lib.sh >/dev/null 2>&1; ufw_capturar_estado; ufw_esta_activo'
# sudo que rechaza todo (no puede correr ufw): la captura queda vacia.
STUBS15F="$TMP/stubs15f"
mkdir -p "$STUBS15F"
cp "$STUBS15"/* "$STUBS15F"/
printf '#!/bin/sh\nexit 1\n' >"$STUBS15F/sudo"
t "ufw_capturar_estado con sudo fallido deja la captura vacia" 0 \
  env PATH="$STUBS15F:$PATH" bash -c 'source ./doctor_lib.sh >/dev/null 2>&1; ufw_capturar_estado; [ -z "$UFW_STATUS" ]'

# ufw_informar_no_activo: solo con ufw instalado y la captura vacia avisa que no
# pudo leer; el resto es el "UFW no activo" de siempre. Sin ufw: PATH sin nada.
informar() {  # informar <PATH> <UFW_STATUS>: salida y contadores
  env PATH="$1" "$BASH" -c '
    source ./doctor_lib.sh >/dev/null 2>&1
    UFW_STATUS=$1; ufw_informar_no_activo
    echo "WARNINGS=$warnings TOTAL=$total"' _ "$2" 2>&1 | sed 's/\x1b\[[0-9;]*m//g'
}
mkdir -p "$TMP/vacio"
I_SIN_UFW=$(informar "$TMP/vacio" "")
I_VACIA=$(informar "$STUBS15:$PATH" "")
I_INACT=$(informar "$STUBS15:$PATH" "Status: inactive")
tiene 0 "sin ufw instalado: UFW no activo" "$I_SIN_UFW" "UFW no activo"
tiene 1 "sin ufw instalado: no avisa de lectura" "$I_SIN_UFW" "No se pudo leer"
tiene 0 "sin ufw instalado: no cuenta aviso" "$I_SIN_UFW" "WARNINGS=0"
tiene 0 "ufw sin captura: avisa que no pudo leer" "$I_VACIA" "[AVISO] No se pudo leer el estado de UFW"
tiene 1 "ufw sin captura: no dice UFW no activo" "$I_VACIA" "UFW no activo"
tiene 0 "ufw sin captura: cuenta un aviso" "$I_VACIA" "WARNINGS=1 TOTAL=1"
tiene 0 "ufw inactivo: UFW no activo" "$I_INACT" "UFW no activo"
tiene 1 "ufw inactivo: no avisa de lectura" "$I_INACT" "No se pudo leer"

# Los tres doctores completos, con ufw/sudo falsos en espanol.
doctor_es() { ( unset LC_ALL; export LANG=es_ES.UTF-8 LANGUAGE=es; doctor_salida "$@" ); }
STUBS_ANT="$STUBS"; STUBS="$STUBS15"
for d in doctor_compresion.sh doctor_analitica.sh doctor_visualizacion.sh; do
  S_ACT=$(doctor_es "$d")
  tiene 0 "$d: firewall activo (sistema en espanol) verifica los puertos" "$S_ACT" "Verificando reglas de firewall"
  tiene 1 "$d: firewall activo no dice 'UFW no activo'" "$S_ACT" "UFW no activo"
  tiene 1 "$d: firewall activo no avisa que no pudo leer" "$S_ACT" "No se pudo leer el estado de UFW"
  S_INA=$(UFW_FAKE=inactive doctor_es "$d")
  tiene 0 "$d: firewall inactivo omite los puertos" "$S_INA" "UFW no activo"
  tiene 1 "$d: firewall inactivo no verifica puertos" "$S_INA" "Verificando reglas de firewall"
  STUBS="$STUBS15F"
  S_SUDO=$(doctor_salida "$d")
  STUBS="$STUBS15"
  tiene 0 "$d: sudo sin poder correr ufw avisa que no pudo leer" "$S_SUDO" "[AVISO] No se pudo leer el estado de UFW"
  tiene 1 "$d: sudo sin poder correr ufw no dice 'UFW no activo'" "$S_SUDO" "UFW no activo"
  tiene 1 "$d: sudo sin poder correr ufw no verifica puertos" "$S_SUDO" "Verificando reglas de firewall"
done
A_SKIP=$(doctor_salida doctor_analitica.sh --skip-mongodb)
tiene 1 "analitica con --skip-mongodb no verifica el puerto 27017" "$A_SKIP" "(27017)"
tiene 0 "analitica con --skip-mongodb sigue verificando 1880" "$A_SKIP" "(1880)"
C_SKIP=$(doctor_salida doctor_compresion.sh --skip-mongodb --skip-emqx)
for p in "(27017)" "(1883)" "(18083)"; do
  tiene 1 "compresion con --skip-mongodb --skip-emqx no verifica" "$C_SKIP" "$p"
done
tiene 0 "compresion con skips sigue verificando RTSP 554" "$C_SKIP" "(554)"
STUBS="$STUBS_ANT"

if (( fallos == 0 )); then
  echo "OK: todos los self-checks pasaron"
else
  echo "FALLARON $fallos self-checks"
  exit 1
fi
