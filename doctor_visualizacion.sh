#!/bin/bash
# =============================================================================
# Doctor de Verificación - Estaciones de Visualización
# Verifica que todos los componentes necesarios estén instalados correctamente.
# Basado en las secciones 3-6 de la guía de configuración (sin el stack de video).
#
# Uso (los --skip-* los pasa workstation-dependencies con los mismos flags de la instalación):
#   ./doctor_visualizacion.sh          Solo verificar
#   ./doctor_visualizacion.sh --fix    Verificar e instalar faltantes
# =============================================================================

set -uo pipefail

# --- Cargar librería compartida ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/doctor_lib.sh"

# --- Parsear argumentos ---
parse_args "$@"

# =============================================================================
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║     Doctor de Verificación - Estación de Visualización     ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "  Host:  $(hostname)"
# =============================================================================

# --- 1. Sistema Base ---
section "1. Sistema Operativo"

check_and_fix "Base Ubuntu detectada (Ubuntu o derivado directo, ej. Linux Mint)" \
    "ubuntu_base_version"

ubuntu_version=$(ubuntu_base_version 2>/dev/null || echo "desconocida")
distro_pretty=$(. /etc/os-release 2>/dev/null; echo "${PRETTY_NAME:-desconocida}")
info "Distribución: ${distro_pretty} (base Ubuntu ${ubuntu_version})"

check_and_fix "Kernel Linux" "uname -r"
info "Kernel: $(uname -r)"

check_and_fix "Arquitectura x86_64" "uname -m | grep -q x86_64"

# --- 2. Preparación del Sistema (Sección 3) ---
section "2. Preparación del Sistema" "nvidia-cuda-setup"

check_and_fix "build-essential instalado" \
    "pkg_installed build-essential" \
    "fix_apt build-essential"
check_and_fix "dkms instalado" \
    "pkg_installed dkms" \
    "fix_apt dkms"
check_and_fix "Headers del kernel en ejecución" \
    "check_running_kernel_headers" \
    "fix_apt linux-headers-$(uname -r) linux-headers-generic"
check_and_fix "pkg-config instalado" \
    "command -v pkg-config" \
    "fix_apt pkg-config"
check_and_fix "GCC disponible" \
    "command -v gcc" \
    "fix_apt gcc"

gcc_version=$(gcc --version 2>/dev/null | head -1 || echo "no instalado")
info "GCC: ${gcc_version}"

check_and_fix "Git instalado" "command -v git" "fix_apt git"
check_and_fix "curl instalado" "command -v curl" "fix_apt curl"
check_and_fix "wget instalado" "command -v wget" "fix_apt wget"
check_and_fix_nota "vim instalado" "command -v vim" "fix_apt vim"
check_and_fix_nota "htop instalado" "command -v htop" "fix_apt htop"
check_and_fix_nota "ncdu instalado" "command -v ncdu" "fix_apt ncdu"
check_and_fix_nota "tree instalado" "command -v tree" "fix_apt tree"
check_and_fix_nota "traceroute instalado" "command -v traceroute" "fix_apt traceroute"
check_and_fix_nota "nmap instalado" "command -v nmap" "fix_apt nmap"
check_and_fix_nota "inxi instalado" "command -v inxi" "fix_apt inxi"
check_and_fix_nota "net-tools instalado" "command -v ifconfig" "fix_apt net-tools"
check_and_fix_nota "lm-sensors instalado" "command -v sensors" "fix_apt lm-sensors"
check_and_fix_nota "neofetch instalado" "command -v neofetch" "fix_neofetch"
check_and_fix_nota "mesa-utils instalado" "command -v glxinfo" "fix_apt mesa-utils"

check_and_fix "Librerías OpenGL (libglvnd-dev)" \
    "pkg_installed libglvnd-dev" \
    "fix_apt libglvnd-dev"
check_and_fix "Librerías Mesa (libgl1-mesa-dev)" \
    "pkg_installed libgl1-mesa-dev" \
    "fix_apt libgl1-mesa-dev"
check_and_fix "Librerías EGL (libegl1-mesa-dev)" \
    "pkg_installed libegl1-mesa-dev" \
    "fix_apt libegl1-mesa-dev"
check_and_fix "Librerías GLES (libgles2-mesa-dev)" \
    "pkg_installed libgles2-mesa-dev" \
    "fix_apt libgles2-mesa-dev"
check_and_fix "Librerías X11 (libx11-dev)" \
    "pkg_installed libx11-dev" \
    "fix_apt libx11-dev"
check_and_fix "Librerías Xmu (libxmu-dev)" \
    "pkg_installed libxmu-dev" \
    "fix_apt libxmu-dev"
check_and_fix "Librerías Xi (libxi-dev)" \
    "pkg_installed libxi-dev" \
    "fix_apt libxi-dev"
check_and_fix "Librerías GLU (libglu1-mesa-dev)" \
    "pkg_installed libglu1-mesa-dev" \
    "fix_apt libglu1-mesa-dev"
check_and_fix "Librerías GStreamer dev" \
    "pkg_installed libgstreamer1.0-dev" \
    "fix_apt libgstreamer1.0-dev"
check_and_fix "Librerías GStreamer plugins base dev" \
    "pkg_installed libgstreamer-plugins-base1.0-dev" \
    "fix_apt libgstreamer-plugins-base1.0-dev"

# --- 3. Wayland/Xorg ---
section "3. Entorno Gráfico" "workstation-hardening"

session_type="${XDG_SESSION_TYPE:-desconocido}"
if [ "$session_type" = "x11" ]; then
    echo -e "  ${PASS} Sesión Xorg activa (Wayland desactivado)"
    total=$((total + 1))
    passed=$((passed + 1))
elif [ "$session_type" = "wayland" ]; then
    echo -e "  ${WARN} Sesión Wayland activa (se recomienda Xorg para NVIDIA)"
    total=$((total + 1))
    warnings=$((warnings + 1))
else
    echo -e "  ${INFO} Sesión gráfica: ${session_type} (modo texto o sin sesión gráfica)"
    total=$((total + 1))
    passed=$((passed + 1))
fi

target=$(systemctl get-default 2>/dev/null || echo "desconocido")
info "Target actual: ${target}"

# --- 4. SSH y Firewall ---
section "4. SSH y Firewall" "workstation-dependencies"

check_and_fix "OpenSSH Server instalado" \
    "pkg_installed openssh-server" \
    "fix_apt openssh-server"
check_and_fix_warn "Servicio SSH activo" "systemctl is-active ssh"
check_and_fix_warn "UFW instalado" "command -v ufw" "fix_apt ufw"

if command -v ufw > /dev/null 2>&1; then
    ufw_status=$(head -1 <<<"$(sudo ufw status 2>/dev/null)" || echo "no disponible")
    info "UFW: ${ufw_status}"
fi

# --- 5. Docker, ffmpeg y MQTTX (base común del instalador) ---
section "5. Docker, ffmpeg y MQTTX" "workstation-dependencies"

check_and_fix_warn "Docker instalado" \
    "command -v docker" \
    "fix_apt docker.io"
check_and_fix_warn "Servicio Docker activo" \
    "systemctl is-active docker" \
    "sudo systemctl enable --now docker"
check_and_fix_warn "Docker Compose disponible (docker compose)" \
    "docker compose version" \
    "fix_apt docker-compose-v2"
check_and_fix_warn "ffmpeg instalado" \
    "command -v ffmpeg" \
    "fix_apt ffmpeg"
check_and_fix_warn "MQTTX instalado" \
    "pkg_installed mqttx" \
    "fix_deb_url '${MQTTX_URL}'"

# --- 6. Kernel y red ---
section "6. Kernel y Red" "nvidia-cuda-setup"

if $SKIP_MONGODB; then
    info "MongoDB omitido (este equipo no usa MongoDB): el chequeo de kernel de MongoDB no aplica"
else
    check_manual "Kernel compatible con MongoDB 8 (fuera de 6.19-7.0.13)" \
        "check_kernel_mongodb_ok" \
        "Kernel $(uname -r) bloquea el arranque de mongod (SERVER-121912). Aplica la Sección 14 del README: arrancar en un kernel anterior a 6.19 (el 6.8 GA, o el 6.11/6.14 si el equipo ya lo tiene)."
fi
check_manual "Pin del kernel persistente (bloquea 6.19+)" \
    "check_kernel_pin" \
    "Falta el pin. El kernel actual puede ser compatible, pero sin pin un apt upgrade futuro trae el HWE 7.0 y deja el equipo sin base de datos. Aplica el Paso 7 de la Sección 3."
check_manual "NIC Ethernet con driver activo (Sección 14 Caso C)" \
    "check_nic_driver_bound" \
    "Hay una NIC Ethernet sin driver: el del kernel no soporta ese chip. Con los paquetes 2.3.0+: sudo nic-driver-rescue. A mano, Caso C de la Sección 14."
check_and_fix_warn "Módulos DKMS construidos para el kernel en ejecución" \
    "check_dkms_current_kernel" \
    "sudo dkms autoinstall"
check_manual "Sin blacklist de r8169 (mata las RTL8168/8111)" \
    "check_no_r8169_blacklist" \
    "Hay un blacklist de r8169 en /etc/modprobe.d/. Sacalo: mata las RTL8168/8111 y no hace falta, porque el r8169 libera el device cuando no soporta la revision y ahi lo toma el r8125."

# --- 7. MongoDB ---
section "7. MongoDB" "workstation-dependencies"

check_bloque_mongodb

# --- 8. EMQX ---
section "8. EMQX (Broker MQTT)" "workstation-dependencies"

check_bloque_emqx

# --- 9. AnyDesk ---
section "9. AnyDesk (Acceso Remoto)" "workstation-dependencies"

check_bloque_anydesk

# --- 10. Golang ---
section "10. Golang" "workstation-dependencies"

if $SKIP_SNAPS; then
    info "Go omitido (--skip-snaps): este equipo no lo instala"
else
    check_and_fix_nota "Go instalado" "command -v go" "fix_snap go"

    if command -v go > /dev/null 2>&1; then
        go_version=$(go version 2>/dev/null || echo "desconocida")
        info "${go_version}"
    fi
fi

# --- 11. Visual Studio Code ---
section "11. Visual Studio Code" "workstation-dependencies"

if $SKIP_SNAPS; then
    info "VSCode omitido (--skip-snaps): este equipo no lo instala"
else
    check_and_fix_nota "VSCode instalado" "command -v code" "fix_snap code"

    if command -v code > /dev/null 2>&1; then
        code_version=$(code --version 2>/dev/null | head -1 || echo "desconocida")
        info "VSCode: ${code_version}"
    fi
fi

# --- 12. Puertos ---
section "12. Puertos y Conectividad" "workstation-hardening"

check_and_fix "Conexión a internet" "ping -c 1 -W 3 8.8.8.8"
check_and_fix "Resolución DNS" "host google.com"

ufw_capturar_estado
if ufw_esta_activo; then
    info "Verificando reglas de firewall..."
    check_puertos_ufw_base
    check_puertos_ufw_anydesk
else
    info "UFW no activo, omitiendo verificación de puertos"
fi

# --- 13. Versión de Ubuntu específica ---
section "13. Dependencias Específicas por Versión" "nvidia-cuda-setup"

if [[ "$ubuntu_version" == "24.04"* ]]; then
    check_and_fix_nota "libtinfo5 instalado (24.04: opcional; solo si CUDA o una herramienta antigua la pide. Se instala con nvidia-cuda-setup --libtinfo5)" \
        "pkg_installed libtinfo5" \
        "fix_libtinfo5"
elif [[ "$ubuntu_version" == "22.04"* ]]; then
    check_and_fix "GCC-12 instalado" "gcc-12 --version" "fix_gcc12"
    check_and_fix "G++-12 instalado" "g++-12 --version"
fi

# =============================================================================
print_summary "visualización"
# shellcheck disable=SC2154  # failed lo define y lo incrementa doctor_lib.sh
exit $((failed > 255 ? 1 : failed))
