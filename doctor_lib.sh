#!/bin/bash
# =============================================================================
# Librería Compartida - Scripts Doctor
# Funciones comunes de verificación e instalación.
# Uso: source doctor_lib.sh (desde doctor_compresion.sh o doctor_analitica.sh)
# =============================================================================

# --- Colores y símbolos ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

PASS="${GREEN}[OK]${NC}"
FAIL="${RED}[FALLO]${NC}"
WARN="${YELLOW}[AVISO]${NC}"
MINOR="${CYAN}[NOTA]${NC}"
INFO="${CYAN}[INFO]${NC}"
FIXED="${GREEN}[INSTALADO]${NC}"
FIX_FAIL="${RED}[NO SE PUDO INSTALAR]${NC}"

# --- Niveles de alerta (un significado por nivel) ---
#   [OK]    presente.
#   [FALLO] necesario: el perfil no funciona sin esto. Cuenta para el exit code.
#   [AVISO] recomendado: funciona, pero degradado o con riesgo real. No bloquea.
#   [NOTA]  opcional: informativo; ningun perfil depende de esto. No bloquea.
# El exit code del doctor cuenta solo [FALLO]. Ver check_and_fix (FALLO),
# check_and_fix_warn (AVISO), check_and_fix_nota (NOTA).

# --- Contadores ---
total=0
passed=0
failed=0
warnings=0
minors=0
fixed=0

# --- Modo de operación ---
FIX_MODE=false
LOG_FILE=""

# --- Versiones de paquetes .deb (actualizar cuando cambien) ---
MONGODB_COMPASS_VERSION="1.49.15"
MONGODB_COMPASS_URL="https://downloads.mongodb.com/compass/mongodb-compass_${MONGODB_COMPASS_VERSION}_amd64.deb"
IPSCAN_VERSION="3.9.1"
IPSCAN_URL="https://github.com/angryip/ipscan/releases/download/${IPSCAN_VERSION}/ipscan_${IPSCAN_VERSION}_amd64.deb"
RUSTDESK_VERSION="1.2.3"
RUSTDESK_URL="https://github.com/rustdesk/rustdesk/releases/download/${RUSTDESK_VERSION}/rustdesk-${RUSTDESK_VERSION}-x86_64.deb"

# =============================================================================
# --- Parseo de argumentos ---
# =============================================================================
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --fix)
                FIX_MODE=true
                shift
                ;;
            *)
                echo "Uso: $0 [--fix]"
                echo "  --fix    Instala componentes faltantes automáticamente"
                exit 1
                ;;
        esac
    done

    if $FIX_MODE; then
        LOG_FILE="/tmp/doctor_fix_$(date '+%Y%m%d_%H%M%S').log"
        echo -e "${YELLOW}${BOLD}  Modo --fix activado. Se instalarán componentes faltantes.${NC}"
        echo -e "  Log de instalación: ${LOG_FILE}"
        echo ""

        # Solicitar sudo una vez al inicio
        if ! sudo -v 2>/dev/null; then
            echo -e "  ${RED}Se requiere sudo para --fix. Ejecuta con un usuario con permisos sudo.${NC}"
            exit 1
        fi

        # Actualizar índice de paquetes una vez
        echo -e "  ${INFO} Actualizando índice de paquetes..."
        sudo apt-get update >> "$LOG_FILE" 2>&1
    fi
}

# =============================================================================
# --- Funciones auxiliares ---
# =============================================================================
info() {
    echo -e "  ${INFO} $1"
}

# $2 opcional: el instalador que arregla lo de esta sección. El doctor del
# perfil verifica la estación entera, y un rojo de CUDA o de puertos no se
# arregla reejecutando el perfil.
section() {
    local titulo="$1"
    [ -n "${2:-}" ] && titulo="$1  (→ $2)"
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  ${titulo}${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# --- Ejecutar fix y loggear ---
run_fix() {
    local fix_cmd="$1"
    echo ">>> $(date '+%H:%M:%S') Ejecutando: ${fix_cmd}" >> "$LOG_FILE" 2>&1
    eval "$fix_cmd" >> "$LOG_FILE" 2>&1
    return $?
}

# =============================================================================
# --- Funciones de verificación con auto-instalación ---
# =============================================================================

# check_and_fix <descripción> <comando_check> <comando_fix>
# Si el check falla y --fix está activo, ejecuta el fix y re-verifica.
check_and_fix() {
    local description="$1"
    local check_cmd="$2"
    local fix_cmd="${3:-}"
    total=$((total + 1))

    if eval "$check_cmd" > /dev/null 2>&1; then
        echo -e "  ${PASS} ${description}"
        passed=$((passed + 1))
        return 0
    fi

    # Check falló
    if $FIX_MODE && [ -n "$fix_cmd" ]; then
        echo -ne "  ${YELLOW}[INSTALANDO]${NC} ${description}..."
        if run_fix "$fix_cmd"; then
            # Re-verificar después de instalar
            if eval "$check_cmd" > /dev/null 2>&1; then
                echo -e "\r  ${FIXED} ${description}          "
                fixed=$((fixed + 1))
                passed=$((passed + 1))
                return 0
            fi
        fi
        echo -e "\r  ${FIX_FAIL} ${description}          "
        failed=$((failed + 1))
        return 1
    fi

    echo -e "  ${FAIL} ${description}"
    failed=$((failed + 1))
    return 1
}

# check_and_fix_warn - igual que check_and_fix pero cuenta como warning si falla
check_and_fix_warn() {
    local description="$1"
    local check_cmd="$2"
    local fix_cmd="${3:-}"
    total=$((total + 1))

    if eval "$check_cmd" > /dev/null 2>&1; then
        echo -e "  ${PASS} ${description}"
        passed=$((passed + 1))
        return 0
    fi

    # Check falló
    if $FIX_MODE && [ -n "$fix_cmd" ]; then
        echo -ne "  ${YELLOW}[INSTALANDO]${NC} ${description}..."
        if run_fix "$fix_cmd"; then
            if eval "$check_cmd" > /dev/null 2>&1; then
                echo -e "\r  ${FIXED} ${description}          "
                fixed=$((fixed + 1))
                passed=$((passed + 1))
                return 0
            fi
        fi
        echo -e "\r  ${FIX_FAIL} ${description} (recomendado)          "
        warnings=$((warnings + 1))
        return 1
    fi

    echo -e "  ${WARN} ${description} (recomendado)"
    warnings=$((warnings + 1))
    return 1
}

# check_and_fix_nota - [NOTA]: opcional. Se intenta instalar con --fix, pero que
# falte no bloquea ni avisa como riesgo. Cuenta en "Notas", no en "Avisos".
check_and_fix_nota() {
    local description="$1"
    local check_cmd="$2"
    local fix_cmd="${3:-}"
    total=$((total + 1))

    if eval "$check_cmd" > /dev/null 2>&1; then
        echo -e "  ${PASS} ${description}"
        passed=$((passed + 1))
        return 0
    fi

    if $FIX_MODE && [ -n "$fix_cmd" ]; then
        echo -ne "  ${YELLOW}[INSTALANDO]${NC} ${description}..."
        if run_fix "$fix_cmd"; then
            if eval "$check_cmd" > /dev/null 2>&1; then
                echo -e "\r  ${FIXED} ${description}          "
                fixed=$((fixed + 1))
                passed=$((passed + 1))
                return 0
            fi
        fi
        echo -e "\r  ${MINOR} ${description} (opcional, no instalado)          "
        minors=$((minors + 1))
        return 1
    fi

    echo -e "  ${MINOR} ${description} (opcional)"
    minors=$((minors + 1))
    return 1
}

# check_and_fix_minor - para verificaciones de baja prioridad (puertos, configs opcionales)
check_and_fix_minor() {
    local description="$1"
    local check_cmd="$2"
    local fix_cmd="${3:-}"
    total=$((total + 1))

    if eval "$check_cmd" > /dev/null 2>&1; then
        echo -e "  ${PASS} ${description}"
        passed=$((passed + 1))
        return 0
    fi

    # Check falló
    if $FIX_MODE && [ -n "$fix_cmd" ]; then
        echo -ne "  ${YELLOW}[CONFIGURANDO]${NC} ${description}..."
        if run_fix "$fix_cmd"; then
            if eval "$check_cmd" > /dev/null 2>&1; then
                echo -e "\r  ${GREEN}[CONFIGURADO]${NC} ${description}          "
                fixed=$((fixed + 1))
                passed=$((passed + 1))
                return 0
            fi
        fi
        echo -e "\r  ${MINOR} ${description} (no configurado)          "
        minors=$((minors + 1))
        return 1
    fi

    echo -e "  ${MINOR} ${description} (no configurado)"
    minors=$((minors + 1))
    return 1
}

# check_manual - para cosas que no se pueden automatizar
check_manual() {
    local description="$1"
    local check_cmd="$2"
    local manual_msg="$3"
    total=$((total + 1))

    if eval "$check_cmd" > /dev/null 2>&1; then
        echo -e "  ${PASS} ${description}"
        passed=$((passed + 1))
    else
        echo -e "  ${FAIL} ${description}"
        if $FIX_MODE; then
            echo -e "        ${YELLOW}→ Manual: ${manual_msg}${NC}"
        fi
        failed=$((failed + 1))
    fi
}

# =============================================================================
# --- Verificación de paquetes dpkg ---
# =============================================================================

# apt-mark hold cambia el estado en "dpkg -l" de "ii" a "hi" (primer carácter =
# acción deseada, segundo = estado real), así que grep '^ii' da falso negativo
# sobre paquetes en hold — por ejemplo dkms fijado al de noble para no tomar el
# del repo local de CUDA (Sección 14, cabos sueltos).
# Además "dpkg -l | grep -q" falla con set -o pipefail: grep -q corta el pipe,
# dpkg muere con SIGPIPE (141) y la condición evalúa falso aunque el paquete
# exista. dpkg-query evita las dos trampas. Acepta globs.
pkg_installed() {
    local out
    out=$(dpkg-query -W -f='${db:Status-Status}\n' "$1" 2>/dev/null || true)
    # Match de LINEA COMPLETA. dpkg-query tambien devuelve entradas
    # "not-installed" y "config-files", y "not-installed" contiene
    # "installed" como substring: comparar con *installed* da falso
    # positivo. Here-string, no pipeline, asi que pipefail no interfiere.
    grep -qx 'installed' <<<"$out"
}

# NOTA para futuros checks: si el valor de retorno de una función es un pipeline
# que termina en `grep -q`, con `set -o pipefail` puede dar falso. Capturá la
# salida en una variable y compará con `[[ "$out" == *patrón* ]]`.

# =============================================================================
# --- Verificaciones que el manual exige y no estaban cubiertas ---
# =============================================================================

# Rama del driver fijada por la Sección 4 / Anexo B
NVIDIA_BRANCH_EXPECTED="580"

check_nvidia_branch() {
    local v
    v=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1)
    [ -n "$v" ] || return 1
    [ "${v%%.*}" = "$NVIDIA_BRANCH_EXPECTED" ]
}

# El módulo debe venir del .run, no de APT (Secciones 3 y 4). Un equipo con
# nvidia-driver-* de APT pasaba todos los checks NVIDIA aunque el manual lo
# trate como error a purgar.
check_nvidia_not_from_apt() {
    local p
    for p in 'nvidia-*' 'libnvidia-*' 'cuda-drivers*'; do
        if pkg_installed "$p"; then
            return 1
        fi
    done
    return 0
}

# Módulo open/MIT-GPL, recomendado por la Sección 4 Paso 5 para RTX 20/30/40/50
check_nvidia_open_module() {
    local out
    out=$(modinfo nvidia 2>/dev/null || true)
    [[ "$out" == *"Dual MIT/GPL"* ]]
}

# Versión de CUDA que fija la Sección 5. Es la preferida, no la única válida: la
# página de descargas de NVIDIA sirve siempre la última release, así que en
# terreno aparecen equipos que llegaron con 13.1 o 13.4 puestos. Bajarlos de
# versión son varios GB por un enlace de campo y purgar un toolkit que anda, así
# que desde 2.9.0 el instalador .deb adopta la instalada en vez de forzar ésta y
# el doctor hace lo mismo. Lo que sí tiene que cumplirse está en
# check_cuda_coherente: que todas las fuentes apunten a la MISMA versión.
CUDA_VERSION_EXPECTED="13.0"

# --- Versión de CUDA según cada fuente. Vacío si esa fuente no dice nada. ---

# El nvcc del PATH: lo que ve el operador en su shell.
cuda_version_nvcc() {
    nvcc --version 2>/dev/null |
        awk 'match($0, /release [0-9]+\.[0-9]+/) {
               print substr($0, RSTART + 8, RLENGTH - 8); exit }'
}

# El symlink /usr/local/cuda: lo que ve TODO lo que corre bajo sudo o como
# servicio, que no lee ~/.bashrc. Lo registra cada cuda-toolkit-XX-Y-config-common
# con una prioridad derivada de su versión, así que en modo automático apunta
# siempre a la más nueva instalada, sin importar cuál fijó el manual.
cuda_version_symlink() {
    local destino
    destino=$(readlink -f /usr/local/cuda 2>/dev/null) || return 0
    case "$destino" in
        */cuda-[0-9]*) echo "${destino##*/cuda-}" ;;
    esac
}

# Las que sostiene dpkg. Puede haber más de una instalada a la vez.
cuda_versions_paquete() {
    dpkg-query -W -f='${Package} ${db:Status-Status}\n' 2>/dev/null |
        awk '$2 == "installed" && $1 ~ /^cuda-toolkit-[0-9]+-[0-9]+$/ {
               sub(/^cuda-toolkit-/, "", $1); sub(/-/, ".", $1); print $1 }'
}

# La que está en uso de verdad: manda el symlink. Un PATH puede estar bien en la
# sesión del operador y mal en todo lo demás; el symlink no.
cuda_version_en_uso() {
    local v
    v=$(cuda_version_symlink)
    [ -n "$v" ] || v=$(cuda_version_nvcc)
    echo "$v"
}

# ¿Es la versión que fija el manual? Se sigue publicando porque el instalador la
# usa y porque el resumen la nombra, pero ya no decide el [FALLO].
check_cuda_version() {
    [ "$(cuda_version_en_uso)" = "$CUDA_VERSION_EXPECTED" ]
}

# Lo que sí es un error: que las fuentes NO coincidan. Instalar un segundo
# toolkit mueve el symlink a la versión nueva y deja al operador con un nvcc en
# el PATH que dice una cosa y un /usr/local/cuda que dice otra — y todo lo que
# compile bajo sudo o desde un servicio va contra el segundo. Los builds salen
# contra headers de una versión y linkean contra las librerías de la otra.
check_cuda_coherente() {
    local nvcc_v sym_v en_uso v
    nvcc_v=$(cuda_version_nvcc)
    sym_v=$(cuda_version_symlink)

    # Sin ninguna fuente no hay nada que comparar: de eso ya se queja el check de
    # "nvcc disponible", y duplicar el rojo no agrega información.
    [ -n "${nvcc_v}${sym_v}" ] || return 1

    if [ -n "$nvcc_v" ] && [ -n "$sym_v" ] && [ "$nvcc_v" != "$sym_v" ]; then
        return 1
    fi

    # Y dpkg tiene que sostener la versión en uso: un árbol en /usr/local sin
    # paquete detrás es el resto de una purga a medias, y no recibe updates.
    en_uso=$(cuda_version_en_uso)
    for v in $(cuda_versions_paquete); do
        [ "$v" = "$en_uso" ] && return 0
    done
    return 1
}

# Pin del kernel persistente (Sección 3 Paso 7 / Sección 14). Verificar solo
# "uname -r" no alcanza: un equipo en un kernel compatible (cualquiera anterior
# a 6.19) pero sin pin salta al HWE 7.0 en el próximo apt upgrade y se queda sin
# base de datos.
check_kernel_pin() {
    [ -f /etc/apt/preferences.d/99-no-hwe-kernel ] || return 1
    [ -f /etc/apt/apt.conf.d/51-block-hwe-kernel ] || return 1
    local out
    out=$(apt-cache policy linux-generic-hwe-24.04 2>/dev/null || true)
    [[ "$out" == *"Candidate: (none)"* ]]
}

# NIC Ethernet con driver activo (Sección 14 Caso C). No hace falta cable: si el
# driver del kernel toma el dispositivo y falla el probe —el r8169 con un
# RTL8125D muere en "unknown chip XID 688"— el dispositivo queda sin driver y sin
# interfaz, y eso se ve en sysfs. Clase 0x0200xx = Ethernet.
# El primer argumento existe para poder probar la función contra un árbol falso.
check_nic_driver_bound() {
    local base="${1:-/sys/bus/pci/devices}"
    local d rc=0
    for d in "$base"/*; do
        case "$(cat "$d/class" 2>/dev/null)" in 0x0200*) ;; *) continue ;; esac
        [ -e "$d/driver" ] || rc=1
    done
    return $rc
}

# Todo módulo DKMS con build para el kernel en ejecución. Un r8125 construido
# solo para el kernel anterior deja el equipo sin red después del próximo
# reinicio, y el momento de verlo es ahora, con red.
check_dkms_current_kernel() {
    local out="${1:-}" k="${2:-$(uname -r)}"
    [ -n "$out" ] || out=$(dkms status 2>/dev/null || true)
    [ -n "$out" ] || return 0
    awk -v k="$k" '
        NF == 0 { next }
        { m=$1; sub(/[,/].*/,"",m); mods[m]=1; if (index($0,k)) ok[m]=1 }
        END { for (m in mods) if (!(m in ok)) exit 1 }' <<<"$out"
}

# El blacklist de r8169 es un reflejo común y acá hace daño: las RTL8168/8111
# (10ec:8168) dependen de él, y en placas de dos puertos suele ser el único
# enlace que funciona. Tampoco hace falta: los dos módulos declaran el alias del
# 10ec:8125 y el device se lo queda el primero cuyo probe funcione. El r8169
# rechaza las revisiones que no soporta y libera el device, así que el r8125 lo
# toma sin ayuda. Se captura la salida en vez de pipear a grep -q, que mata a
# grep -rls con SIGPIPE.
check_no_r8169_blacklist() {
    local dir="${1:-/etc/modprobe.d}" hits
    hits=$(grep -rls 'blacklist[[:space:]]\+r8169' "$dir" 2>/dev/null || true)
    [ -z "$hits" ]
}

# MongoDB 8.0 requiere THP habilitado, al revés que 7.0 y anteriores
check_thp_enabled() {
    local f=/sys/kernel/mm/transparent_hugepage/enabled
    [ -f "$f" ] || return 0
    ! grep -q '\[never\]' "$f"
}

# Headers del kernel en ejecución: sin ellos DKMS no recompila el módulo NVIDIA
# en el próximo cambio de kernel (Sección 3 Paso 4).
check_running_kernel_headers() {
    pkg_installed "linux-headers-$(uname -r)"
}

# Override de systemd de AnyDesk (Sección 6 Paso 2). El manual lo declara
# obligatorio en estaciones de compresión: sin él AnyDesk crashea y congela
# GNOME con gnome-shell al 70-100% de CPU.
check_anydesk_override() {
    local out
    out=$(systemctl cat anydesk 2>/dev/null || true)
    [[ "$out" == *LIBGL_ALWAYS_SOFTWARE* ]]
}

# =============================================================================
# --- Detección de CUDA desde filesystem ---
# =============================================================================

# Verificar si CUDA está configurado en el sistema (profile.d, bashrc, etc.)
check_cuda_configured() {
    # Verificar en ~/.bashrc
    grep -q 'export PATH=.*cuda' ~/.bashrc 2>/dev/null && return 0
    # Verificar en /etc/profile.d/ (método APT)
    ls /etc/profile.d/cuda*.sh > /dev/null 2>&1 && return 0
    # Verificar en /etc/environment
    grep -qi 'cuda' /etc/environment 2>/dev/null && return 0
    # Verificar en /etc/profile
    grep -qi 'cuda' /etc/profile 2>/dev/null && return 0
    return 1
}

detect_cuda_from_system() {
    # Si nvcc ya está en el PATH, no hacer nada
    if command -v nvcc > /dev/null 2>&1; then
        return 0
    fi

    # Buscar nvcc directamente en el filesystem
    local cuda_bin=""
    local cuda_lib=""

    # Buscar en rutas estándar de CUDA (más reciente primero)
    for dir in /usr/local/cuda/bin /usr/local/cuda-*/bin; do
        if [ -x "${dir}/nvcc" ] 2>/dev/null; then
            cuda_bin="$dir"
            break
        fi
    done

    if [ -n "$cuda_bin" ]; then
        export PATH="${cuda_bin}:${PATH}"
        info "nvcc encontrado en filesystem: ${cuda_bin}/nvcc"

        # Buscar lib64 correspondiente
        local cuda_base="${cuda_bin%/bin}"
        if [ -d "${cuda_base}/lib64" ]; then
            cuda_lib="${cuda_base}/lib64"
            export LD_LIBRARY_PATH="${cuda_lib}:${LD_LIBRARY_PATH:-}"
            info "LD_LIBRARY_PATH cargado: ${cuda_lib}"
        fi
    fi

    # Verificar si CUDA está configurado en algún lugar del sistema
    if check_cuda_configured; then
        info "Configuración CUDA detectada en el sistema"
    else
        if [ -n "$cuda_bin" ]; then
            echo -e "  ${WARN} CUDA encontrado pero NO configurado en el sistema"
            if $FIX_MODE; then
                echo -e "        ${YELLOW}→ Agregar manualmente a ~/.bashrc:${NC}"
                echo -e "        ${YELLOW}  export PATH=${cuda_bin}\${PATH:+:\${PATH}}${NC}"
                if [ -n "$cuda_lib" ]; then
                    echo -e "        ${YELLOW}  export LD_LIBRARY_PATH=${cuda_lib}\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}${NC}"
                fi
            fi
        fi
    fi
}

# =============================================================================
# --- Detección de módulos NVIDIA en kernel ---
# =============================================================================

# Verificar si NVIDIA está funcionando en el kernel (módulos open o propietarios)
# Nada de "lsmod | grep -qi": lsmod son ~10 KB, grep -q sale al primer match,
# lsmod muere con SIGPIPE al escribir el resto y pipefail propaga el 141. El
# módulo está cargado y la respuesta es "no". Se captura en variable.
check_nvidia_kernel_module() {
    local mods
    mods=$(lsmod 2>/dev/null || true)
    # Verificar módulos clásicos y open
    grep -qi 'nvidia' <<<"$mods" && return 0
    # Verificar vía /proc (funciona con módulos open y propietarios)
    [ -f /proc/driver/nvidia/version ] && return 0
    # Verificar si nvidia-smi funciona (prueba definitiva)
    nvidia-smi > /dev/null 2>&1 && return 0
    return 1
}

# Verificar si hay GPU NVIDIA en el sistema
# Se lee sysfs y no "lspci | grep -qi nvidia": ese pipeline responde "no hay
# GPU" en cuanto lspci escribe más de un bloque de 4 KB (equipos con muchos
# dispositivos PCI) por el SIGPIPE que provoca grep -q. Sysfs además no depende
# de que lspci esté en el PATH ni de que pci.ids conozca el modelo: vendor
# 0x10de es NVIDIA y ya.
# shellcheck disable=SC2120  # el self-check le pasa una raíz alternativa
check_nvidia_gpu() {
    # $1: raíz alternativa para los self-checks; vacío = el sistema real
    local root="${1:-}" f
    for f in "$root"/sys/bus/pci/devices/*/vendor; do
        [ -r "$f" ] || continue
        [ "$(cat "$f")" = "0x10de" ] && return 0
    done
    # Fallback: si nvidia-smi funciona, hay GPU
    nvidia-smi > /dev/null 2>&1 && return 0
    return 1
}

# =============================================================================
# --- Verificación de kernel para MongoDB 8 ---
# =============================================================================

# MongoDB 8 se niega a arrancar en kernels 6.19 - 7.0.13 (SERVER-121912).
# El guard de MongoDB lee el string de uname, no el sublevel upstream real, así que
# comparamos exactamente lo mismo que mira MongoDB. Ver Sección 14 del README.
# ponytail: dpkg --compare-versions en vez de parseo propio de versiones
# Compatible es cualquier kernel anterior a 6.19, no solo el GA 6.8: los HWE
# 6.11, 6.14 y 6.17 arrancan mongod igual, y Mint 22.2 viene con 6.14. Un equipo
# ahí no se baja a 6.8; lo que hace falta es el pin para que no suba.
check_kernel_mongodb_ok() {
    local kver="${1:-$(uname -r)}"
    kver="${kver%%-*}"                                  # 7.0.0-28-generic -> 7.0.0
    dpkg --compare-versions "$kver" lt 6.19
}

# =============================================================================
# --- Verificación de paquetes Python ---
# =============================================================================

# Verificar paquete Python usando pip3 show (más robusto que import)
check_pip_package() {
    local package="$1"
    pip3 show "$package" > /dev/null 2>&1 && return 0
    # Fallback: intentar import
    python3 -c "import ${package}" > /dev/null 2>&1 && return 0
    return 1
}

# =============================================================================
# --- Funciones de instalación específicas ---
# =============================================================================

# Instalar paquete(s) apt
fix_apt() {
    # --no-upgrade: instalar lo ausente sin tocar lo presente. Sin esto, un
    # paquete en hold (dkms) hace abortar todo con
    # "Held packages were changed and -y was used".
    sudo apt-get install -y --no-upgrade "$@"
}

# Quitar el bloqueo de snapd de Linux Mint
# Mint trae /etc/apt/preferences.d/nosnap.pref con Pin-Priority negativa: apt
# deja snapd sin candidato y cualquier "snap install" muere con un "command not
# found" que no explica nada. Se respalda el archivo antes de sacarlo, así que
# revertir es un mv. Las rutas son variables para que el self-check las apunte a
# una raíz falsa.
NOSNAP_PREF="${NOSNAP_PREF:-/etc/apt/preferences.d/nosnap.pref}"
NOSNAP_BACKUP="${NOSNAP_BACKUP:-/var/backups/nosnap.pref.omnifish}"

unblock_snapd() {
    [ -f "$NOSNAP_PREF" ] || return 0
    sudo install -d -m 755 "$(dirname "$NOSNAP_BACKUP")"
    if ! sudo cp -a "$NOSNAP_PREF" "$NOSNAP_BACKUP"; then
        echo "    No se pudo respaldar $NOSNAP_PREF; no se toca la política de snapd."
        return 1
    fi
    sudo rm -f "$NOSNAP_PREF"
    # El pin cambió: sin releer índices, snapd sigue sin candidato.
    sudo apt-get update >/dev/null 2>&1 || true
    echo "    Política nosnap.pref quitada (copia en $NOSNAP_BACKUP)."
    echo "    Para volver a bloquear snapd:  sudo mv $NOSNAP_BACKUP $NOSNAP_PREF"
}

# Instalar paquete snap
fix_snap() {
    # Si la distro bloquea snapd (Mint), primero se saca el bloqueo y se instala
    # snapd; recién después tiene sentido el snap install.
    unblock_snapd || return 1
    if ! command -v snap >/dev/null 2>&1; then
        sudo apt-get install -y --no-upgrade snapd || {
            echo "    No se pudo instalar snapd. Instalá $1 por apt, .deb oficial o tarball."
            return 1
        }
    fi
    sudo snap install "$1" --classic
}

# Instalar .deb desde URL
# Compass al dia: presencia + version. Con "command -v" a secas, un equipo que
# quedo en la 1.43.4 pasaba el chequeo en verde mientras el operador peleaba con
# el manejo de conexiones viejo.
compass_al_dia() {
    command -v mongodb-compass > /dev/null 2>&1 || return 1
    local v
    v=$(dpkg-query -W -f='${Version}' mongodb-compass 2>/dev/null || true)
    dpkg --compare-versions "$v" ge "$MONGODB_COMPASS_VERSION"
}

fix_deb_url() {
    local url="$1"
    local deb_file="/tmp/$(basename "$url")"
    wget -q -O "$deb_file" "$url" && \
    sudo apt-get install -y "$deb_file" && \
    rm -f "$deb_file"
}

# Instalar paquete(s) pip
fix_pip() {
    pip3 install --break-system-packages "$@"
}

# --- Base de Ubuntu (Linux Mint y otros derivados directos) ---
# Mint 22.x es noble reempaquetado, pero lsb_release contesta "Linuxmint" y
# "22.1": ese numero no es una version de Ubuntu, y "lsb_release -cs" devuelve
# el codename de Mint (wilma, xia), que no existe en los repos de terceros. La
# base real esta en /etc/upstream-release/lsb-release, y como respaldo en el
# UBUNTU_CODENAME de /etc/os-release.
ubuntu_base_version() {
    # $1: raíz alternativa para los self-checks; vacío = el sistema real
    local root="${1:-}" id="" ver="" codename="" up_id up_rel
    if [ -r "$root/etc/os-release" ]; then
        id=$(. "$root/etc/os-release" 2>/dev/null; echo "${ID:-}")
        ver=$(. "$root/etc/os-release" 2>/dev/null; echo "${VERSION_ID:-}")
        codename=$(. "$root/etc/os-release" 2>/dev/null; echo "${UBUNTU_CODENAME:-}")
    fi
    if [ "$id" = "ubuntu" ] && [ -n "$ver" ]; then
        echo "$ver"
        return 0
    fi
    if [ -r "$root/etc/upstream-release/lsb-release" ]; then
        up_id=$(awk -F= '$1 == "DISTRIB_ID" {print tolower($2)}' "$root/etc/upstream-release/lsb-release")
        up_rel=$(awk -F= '$1 == "DISTRIB_RELEASE" {print $2}' "$root/etc/upstream-release/lsb-release")
        if [ "$up_id" = "ubuntu" ] && [ -n "$up_rel" ]; then
            echo "$up_rel"
            return 0
        fi
    fi
    case "$codename" in
        noble) echo "24.04"; return 0 ;;
        jammy) echo "22.04"; return 0 ;;
    esac
    return 1
}

# shellcheck disable=SC2120  # el self-check le pasa una raíz alternativa
ubuntu_base_codename() {
    case "$(ubuntu_base_version "$@" 2>/dev/null)" in
        24.04*) echo "noble" ;;
        22.04*) echo "jammy" ;;
        *) return 1 ;;
    esac
}

# --- Repositorio MongoDB ---
fix_mongodb_repo_and_install() {
    local codename
    # Nunca lsb_release -cs: en Mint devuelve wilma/xia y la URL de MongoDB no
    # existe con ese codename.
    codename=$(ubuntu_base_codename || echo "noble")
    curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg 2>/dev/null
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu ${codename}/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list > /dev/null
    sudo apt-get update && sudo apt-get install -y mongodb-org
}

# --- Servicio MongoDB ---
fix_mongodb_service() {
    sudo systemctl start mongod && sudo systemctl enable mongod
}

# --- Repositorio EMQX ---
fix_emqx_repo_and_install() {
    curl -sL https://assets.emqx.com/scripts/install-emqx-deb.sh | sudo bash
    sudo apt-get install -y emqx
}

# --- /etc/emqx/acl.conf ---
# EMQX 5 no arranca sin ese archivo, y dpkg trata un conffile ausente como
# decision del admin: no lo repone ni en un reinstall normal. --force-confmiss
# es lo unico que lo devuelve. Sintoma: paquete instalado, servicio muerto.
fix_emqx_acl() {
    sudo apt-get install -y --reinstall -o Dpkg::Options::=--force-confmiss emqx
}

# --- Servicio EMQX ---
fix_emqx_service() {
    [ -f /etc/emqx/acl.conf ] || fix_emqx_acl
    sudo systemctl start emqx && sudo systemctl enable emqx
}

# --- Repositorio AnyDesk ---
fix_anydesk_repo_and_install() {
    sudo apt-get install -y ca-certificates curl apt-transport-https
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://keys.anydesk.com/repos/DEB-GPG-KEY -o /etc/apt/keyrings/keys.anydesk.com.asc
    sudo chmod a+r /etc/apt/keyrings/keys.anydesk.com.asc
    echo "deb [signed-by=/etc/apt/keyrings/keys.anydesk.com.asc] https://deb.anydesk.com all main" | sudo tee /etc/apt/sources.list.d/anydesk-stable.list > /dev/null
    sudo apt-get update && sudo apt-get install -y anydesk
    # Sin el override AnyDesk crashea y congela GNOME (Sección 6 Paso 2).
    fix_anydesk_override
}
# --- Override de AnyDesk para NVIDIA/X11 (Sección 6 Paso 2) ---
fix_anydesk_override() {
    sudo mkdir -p /etc/systemd/system/anydesk.service.d
    sudo tee /etc/systemd/system/anydesk.service.d/override.conf > /dev/null << 'EOFOVERRIDE'
[Service]
Environment=DISPLAY=:0
Environment=XAUTHORITY=/run/user/1000/gdm/Xauthority
Environment=LIBGL_ALWAYS_SOFTWARE=1
ExecStartPre=/bin/sleep 5
EOFOVERRIDE
    sudo systemctl daemon-reload
    sudo systemctl enable anydesk
    sudo systemctl restart anydesk
}


# --- Node-RED ---
fix_nodered() {
    bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered) --confirm-install --confirm-pi --no-init
}

# --- Servicio Node-RED ---
fix_nodered_service() {
    sudo systemctl enable nodered && sudo systemctl start nodered
}

# --- Neofetch ---
fix_neofetch() {
    sudo apt-get install -y neofetch
}

# --- libtinfo5 para Ubuntu 24.04 ---
# noble no lo publica: se trae el de jammy (6.3-2*) del pool de security. El
# pool borra las versiones superadas, así que una URL con versión fija da 404 al
# siguiente parche (pasó con la 6.3-2ubuntu0.1 cuando salió la 0.3). Se toma la
# última que liste el índice.
LIBTINFO5_POOL="http://security.ubuntu.com/ubuntu/pool/universe/n/ncurses"
libtinfo5_url() {
    local deb
    deb=$(wget -qO- "$LIBTINFO5_POOL/" 2>/dev/null |
          grep -o 'libtinfo5_6\.3-2[^"<>/]*_amd64\.deb' | sort -u -t_ -k2,2V | tail -n1) || true
    [ -n "$deb" ] || return 1
    printf '%s/%s\n' "$LIBTINFO5_POOL" "$deb"
}

fix_libtinfo5() {
    local url
    url=$(libtinfo5_url) && \
    wget -q -O /tmp/libtinfo5.deb "$url" && \
    sudo apt-get install -y /tmp/libtinfo5.deb && \
    rm -f /tmp/libtinfo5.deb
}

# --- GCC-12 para Ubuntu 22.04 ---
fix_gcc12() {
    sudo apt-get install -y gcc-12 g++-12 && \
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 120 && \
    sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 120
}

# =============================================================================
# --- Resumen final ---
# =============================================================================
print_summary() {
    local station_type="$1"
    section "RESUMEN"

    echo ""
    echo -e "  Total de verificaciones:  ${BOLD}${total}${NC}"
    echo -e "  Correctas:                ${GREEN}${passed}${NC}"
    echo -e "  Necesarias ([FALLO]):     ${RED}${failed}${NC}"
    echo -e "  Recomendadas ([AVISO]):   ${YELLOW}${warnings}${NC}"
    echo -e "  Opcionales ([NOTA]):      ${CYAN}${minors}${NC}"
    if $FIX_MODE; then
        echo -e "  Instalados con --fix:     ${GREEN}${fixed}${NC}"
    fi
    echo ""
    echo -e "  Niveles: ${RED}[FALLO]${NC} necesario · ${YELLOW}[AVISO]${NC} recomendado · ${CYAN}[NOTA]${NC} opcional (no bloquea)"
    echo ""

    if [ "$failed" -eq 0 ] && [ "$warnings" -eq 0 ]; then
        echo -e "  ${GREEN}${BOLD}Estado: SALUDABLE${NC}"
        echo -e "  Todos los componentes de ${station_type} están instalados correctamente."
        if [ "$minors" -gt 0 ]; then
            echo -e "  ${CYAN}Hay ${minors} nota(s) opcional(es): no bloquean el perfil.${NC}"
        fi
    elif [ "$failed" -eq 0 ]; then
        echo -e "  ${YELLOW}${BOLD}Estado: SALUDABLE CON AVISOS${NC}"
        echo -e "  Lo necesario está OK. Revisa los avisos recomendados."
    elif [ "$failed" -le 3 ]; then
        echo -e "  ${YELLOW}${BOLD}Estado: ATENCIÓN REQUERIDA${NC}"
        echo -e "  Algunos componentes faltan. Revisa los fallos indicados."
    else
        echo -e "  ${RED}${BOLD}Estado: REQUIERE INTERVENCIÓN${NC}"
        echo -e "  Múltiples componentes faltan. Revisa la guía de instalación."
    fi

    if $FIX_MODE; then
        echo ""
        echo -e "  Log completo: ${LOG_FILE}"
        if [ "$fixed" -gt 0 ]; then
            echo -e "  ${GREEN}Se instalaron ${fixed} componente(s) exitosamente.${NC}"
        fi
    elif [ "$failed" -gt 0 ]; then
        echo ""
        echo -e "  ${CYAN}Tip: Ejecuta con --fix para instalar componentes faltantes automáticamente.${NC}"
    fi

    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}
