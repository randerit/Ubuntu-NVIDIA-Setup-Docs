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
for d in doctor_compresion.sh doctor_analitica.sh; do
  while IFS= read -r linea; do
    [[ "$linea" == 'section "1. Sistema Operativo"' ]] && continue
    grep -qE '^section "[^"]+" "workstation-(nvidia-setup|dependencies|workstation-hardening)"$' <<<"$linea" \
      || { echo "   FALLA: $d sin responsable: $linea"; fallos=$((fallos+1)); }
  done < <(grep -E '^section "' "$d")
done
for d in doctor_compresion.sh doctor_analitica.sh; do
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
t "[AVISO] ya no lleva '(opcional)'" 1 bash -c 'grep -E "check_and_fix_warn " doctor_compresion.sh doctor_analitica.sh | grep -q "opcional"'
t "ningun [AVISO] escrito a mano dice 'opcional'" 1 bash -c 'grep -E "WARN\}.*opcional" doctor_compresion.sh doctor_analitica.sh | grep -q .'
t "ningun [NOTA] escrito a mano dice 'recomendado'" 1 bash -c 'grep -E "MINOR\}.*recomendado" doctor_compresion.sh doctor_analitica.sh | grep -q .'
for d in doctor_compresion.sh doctor_analitica.sh; do
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
NOTA_ANALITICA=("pandas instalado" "numpy instalado" "scikit-learn instalado"
                "paho-mqtt instalado" "ultralytics instalado" "Node-RED instalado"
                "Servicio nodered activo" "Servicio nodered habilitado al inicio")
for d in doctor_compresion.sh doctor_analitica.sh; do
  extra=("${NOTA_COMPRESION[@]}")
  [[ "$d" == doctor_analitica.sh ]] && extra=("${NOTA_ANALITICA[@]}")
  for desc in "${NOTA_COMUN[@]}" "${extra[@]}"; do
    # Si la linea del check no existe, el grep falla y eso tambien es un fallo.
    grep -qF "check_and_fix_nota \"$desc" "$d" \
      || { echo "   FALLA: $d: '$desc' no es check_and_fix_nota"; fallos=$((fallos+1)); }
    grep -qF "check_and_fix \"$desc" "$d" \
      && { echo "   FALLA: $d: '$desc' sigue como [FALLO]"; fallos=$((fallos+1)); }
    grep -qF "check_and_fix_warn \"$desc" "$d" \
      && { echo "   FALLA: $d: '$desc' sigue como [AVISO]"; fallos=$((fallos+1)); }
  done
done
t "libtinfo5 ya no dice 'requerido en 24.04'" 1 grep -qF 'requerido en 24.04' doctor_compresion.sh doctor_analitica.sh

echo "11. --skip-* del perfil: lo que el instalador omitio no cuenta como [FALLO]"
# workstation-dependencies pasa a su doctor los mismos --skip-* con que se corrio.
# Sin esto, un equipo sin EMQX o sin MongoDB sale con fallos que no son suyos.
t "parse_args acepta --skip-emqx y --skip-mongodb" 0 bash -c 'source ./doctor_lib.sh >/dev/null 2>&1; parse_args --skip-emqx --skip-mongodb && [[ "$SKIP_EMQX" == true && "$SKIP_MONGODB" == true ]]'
t "parse_args acepta los demas --skip-* de los perfiles" 0 bash -c 'source ./doctor_lib.sh >/dev/null 2>&1; parse_args --skip-snaps --skip-ml --skip-nodered --skip-mongo-auth'
t "parse_args sigue rechazando un flag desconocido" 1 bash -c 'source ./doctor_lib.sh >/dev/null 2>&1; parse_args --skip-inventado'
t "doctor_lib define SKIP_EMQX y SKIP_MONGODB por defecto en false" 0 grep -qE '^SKIP_(EMQX|MONGODB)=false' doctor_lib.sh
t "compresion omite el bloque EMQX con --skip-emqx" 0 grep -qF 'if $SKIP_EMQX; then' doctor_compresion.sh
for d in doctor_compresion.sh doctor_analitica.sh; do
  t "$d omite el bloque MongoDB con --skip-mongodb" 0 grep -qF 'if $SKIP_MONGODB; then' "$d"
done

echo "12. libtinfo5: la etiqueta dice quien la instala"
# La corrida por defecto de nvidia-cuda-setup la instala en 24.04. La
# etiqueta vieja decia "solo si CUDA la pide", que no era lo que el instalador hace.
for d in doctor_compresion.sh doctor_analitica.sh; do
  t "$d: libtinfo5 nombra a nvidia-cuda-setup" 0 grep -qF 'nvidia-cuda-setup --libtinfo5' "$d"
  t "$d: libtinfo5 ya no dice 'solo si CUDA'" 1 grep -qF 'solo si CUDA' "$d"
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

if (( fallos == 0 )); then
  echo "OK: todos los self-checks pasaron"
else
  echo "FALLARON $fallos self-checks"
  exit 1
fi
