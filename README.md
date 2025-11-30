# Improved Guide for Configuring Ubuntu Workstations with NVIDIA GPUs

> **Last update:** October 16, 2025

---

## Table of Contents

* [1. Pre-Installation Requirements](#1-pre-installation-requirements)
* [2. Ubuntu System Installation](#2-ubuntu-system-installation)
* [3. Initial Ubuntu System Preparation](#3-initial-ubuntu-system-preparation)
* [4. Installing NVIDIA Drivers on Ubuntu](#4-installing-nvidia-drivers-on-ubuntu)
* [5. Installing CUDA Toolkit](#5-installing-cuda-toolkit)
* [6. Specific Configuration for Compression Stations](#6-specific-configuration-for-compression-stations)
* [7. Specific Configuration for Analytics Stations](#7-specific-configuration-for-analytics-stations)
* [8. Graphical Interface Management](#8-graphical-interface-management)
* [9. Troubleshooting Common Network Issues on New Motherboards](#9-troubleshooting-common-network-issues-on-new-motherboards)
* [10. Wake-on-LAN (WOL): Windows to Windows and Ubuntu to Windows](#10-wake-on-lan-wol-windows-to-windows-and-ubuntu-to-windows)
* [11. Post-Installation Script (Optional)](#11-post-installation-script-optional)
* [12. Security Best Practices (Optional)](#12-security-best-practices-optional)
* [FAQ: Frequently Asked Questions](#faq-frequently-asked-questions)
* [Appendix A: Identifying NVIDIA GPUs](#appendix-a-identifying-nvidia-gpus)
* [Appendix B: Compatibility Verification](#appendix-b-compatibility-verification)

---

> **Welcome!** This improved guide will help you install and configure Ubuntu with NVIDIA GPUs, optimizing each step and explaining the reasoning behind each action. The original commands and procedures are maintained intact, but explanations, tips, and warnings have been added to facilitate the process.

---

## Visual Summary of the Process

`BIOS/UEFI` → `Ubuntu Installation` → `System Preparation` → `NVIDIA Drivers` → `CUDA Toolkit` → `Specific Configuration`

---

## 1. Pre-Installation Requirements

### What do you need before starting?

* **Bootable USB drive** Use Ventoy or BalenaEtcher to create it.
* **Ubuntu Desktop image** Download the recommended LTS version (22.04 or 24.04).
* **Equipment purpose** Define if it will be for Compression/Data or Analytics.

> **Tip:** Ubuntu Desktop is the most standard and compatible option for this type of configurations.

---

## 2. Instalación del Sistema Ubuntu

> **Nota:** Esta guía asume Ubuntu Desktop 24.04.1 LTS (la más reciente en 2025). Si usas 22.04 LTS, los pasos son similares, pero verifica enlaces de descarga. Asegúrate de respaldar datos importantes antes de proceder, ya que la instalación borrará el disco.

### Paso 1: Prepara la USB Booteable
Necesitas una USB de al menos 8GB con la imagen ISO de Ubuntu.

1. **Descarga la imagen ISO:**
   - Ve a [https://ubuntu.com/download/desktop](https://ubuntu.com/download/desktop).
   - Descarga Ubuntu 24.04.1 LTS (archivo ~4GB).
   - **Verificación:** Calcula el hash SHA256 para confirmar integridad:
     ```bash
     wget https://releases.ubuntu.com/24.04.1/SHA256SUMS
     sha256sum ubuntu-24.04.1-desktop-amd64.iso
     ```
     Compara con el valor en SHA256SUMS.

2. **Instala Ventoy (recomendado para facilidad):**
   - Descarga Ventoy desde [https://www.ventoy.net/](https://www.ventoy.net/).
   - Instala en tu USB actual (borrará datos):
     ```bash
     wget https://github.com/ventoy/Ventoy/releases/download/v1.0.99/Ventoy-1.0.99-linux.tar.gz
     tar -xzf Ventoy-1.0.99-linux.tar.gz
     cd Ventoy-1.0.99
     sudo ./Ventoy2Disk.sh -i /dev/sdX  # Reemplaza /dev/sdX por tu USB (ej. /dev/sdb). ¡Cuidado, borra todo!
     ```
   - Copia la ISO descargada a la USB (Ventoy la detectará automáticamente).

3. **Alternativa: Usa BalenaEtcher (si prefieres GUI):**
   - Descarga desde [https://etcher.balena.io/](https://etcher.balena.io/).
   - Instala: `sudo apt install balena-etcher-electron` (en un sistema Linux existente).
   - Flashea la ISO a la USB.

**Verificación:** Inserta la USB en otro PC y verifica que aparezca el menú de boot de Ubuntu.

### Paso 2: Accede a la BIOS/UEFI
Reinicia tu PC y entra al setup de BIOS/UEFI presionando la tecla correcta durante el POST (pantalla inicial). Teclas comunes:
- F2, F8, F10, F11, F12, DEL, ESC, BACKSPACE.
- Consulta el manual de tu placa madre (busca por modelo en Google).

**Ejemplo:** En ASUS ROG, presiona DEL. En MSI, F2.

### Paso 3: Configura la BIOS/UEFI
Una vez dentro:
1. **Desactiva Secure Boot:**
   - Ve a "Security" o "Boot" > "Secure Boot" > Configúralo en "Disabled".
   - **Por qué:** Evita conflictos con drivers NVIDIA propietarios.

2. **Desactiva TPM (si está habilitado):**
   - Busca "TPM" o "Trusted Platform Module" > "Disabled".
   - **Por qué:** Puede interferir con instalaciones personalizadas.

3. **Configura el orden de boot:**
   - Ve a "Boot" > Asegúrate de que USB esté primero (arriba en la lista).

4. **(Opcional para servidores) Configura AC Power Loss:**
   - Ve a "Power" > "AC Power Loss" > "Always On".
   - **Por qué:** Mantiene el PC encendido tras cortes de energía.

5. **Guarda y sal:**
   - Presiona F10 (o la tecla indicada) para guardar y reiniciar.

**Verificación:** El PC debería reiniciar. Si no entraste, intenta de nuevo con otra tecla.

### Paso 4: Bootea desde la USB
- Inserta la USB preparada.
- Reinicia y selecciona la USB en el menú de boot (si no aparece automáticamente).
- Elige "Try or Install Ubuntu" en el menú de Ventoy/GRUB.

### Paso 5: Edita Parámetros de Arranque (Opcional pero Recomendado)
Si tienes una GPU NVIDIA nueva, agrega `nomodeset` para evitar pantallas negras.
- En el menú de GRUB, presiona E para editar.
- Busca la línea que comienza con `linux` y agrega `nomodeset` al final (después de `---` si hay).
- Presiona F10 para bootear.

**Ejemplo de línea editada:**
```
linux /boot/vmlinuz-... nomodeset ---
```

**Por qué:** Desactiva el modo gráfico genérico, previniendo conflictos con GPUs no soportadas.

### Paso 6: Instala Ubuntu
1. **Selecciona idioma:** Elige Español o English (recomendado para soporte).
2. **Configura teclado:** Selecciona tu layout (ej. Spanish).
3. **Conecta a internet:** Recomendado para actualizaciones durante instalación.
4. **Tipo de instalación:** Elige "Instalación normal" (no minimal).
5. **Opciones adicionales:** Marca "Instalar software de terceros" y "Instalar actualizaciones durante la instalación" para codecs multimedia y drivers.
6. **Particionamiento:** Selecciona "Borrar disco e instalar Ubuntu" (elimina todo; usa particiones manuales si dual-boot).
   - **Advertencia:** Esto borra TODOS los datos. Confirma.
7. **Configura usuario:**
   - Nombre, nombre de usuario, contraseña (usa una fuerte).
   - Zona horaria: Selecciona automáticamente o manual.
8. **Finaliza:** Espera a que termine (15-30 min). No retires la USB aún.

**Verificación durante instalación:** Si hay errores, anótalos para troubleshooting.

### Paso 7: Post-Instalación Inicial
1. **Reinicia:** Quita la USB cuando aparezca el mensaje.
2. **Primer boot:** Inicia sesión con tu usuario.
3. **Verificaciones básicas:**
   - Abre una terminal: `Ctrl+Alt+T`.
   - Versión de Ubuntu: `lsb_release -a` (debería mostrar 24.04.1 LTS).
   - Conexión a internet: `ping -c 4 google.com`.
   - Espacio en disco: `df -h`.

**Si hay problemas gráficos:** Si la pantalla se ve mal, ejecuta `sudo apt update && sudo apt install ubuntu-drivers-common` y reinicia.

### Troubleshooting Común en Instalación
- **USB no bootea:** Verifica que Ventoy esté instalado correctamente (`lsblk` para ver particiones). Prueba otra USB o herramienta.
- **Pantalla negra en boot:** Agrega `nomodeset` o prueba `acpi=off` en parámetros de GRUB.
- **Error de particionamiento:** Usa GParted desde live USB para preparar discos.
- **Secure Boot no se desactiva:** Algunos PCs requieren contraseña de BIOS; busca en manual.
- **Instalación se congela:** Reinicia y desactiva opciones de overclock en BIOS.
- **Dual-boot con Windows:** Usa particiones manuales; instala Ubuntu después de Windows para GRUB.

> **Nota:** Si tienes dudas sobre BIOS, busca "modelo placa madre BIOS setup" en Google. Para soporte avanzado, consulta foros de Ubuntu.

---

## 3. Preparación Inicial del Sistema Ubuntu

> **Nota:** Esta sección prepara Ubuntu para instalar drivers NVIDIA y CUDA. Ejecuta los comandos en orden. Asume que acabas de instalar Ubuntu 24.04.1 LTS.

### Paso 1: Configura GDM3 para Desactivar Wayland (Opcional pero Recomendado)
Wayland puede causar problemas con drivers NVIDIA propietarios. Desactívalo para usar Xorg.

```bash
sudo nano /etc/gdm3/custom.conf
```

- Busca la línea `#WaylandEnable=false`.
- Elimina el `#` para descomentarla (quedará `WaylandEnable=false`).
- Guarda: Ctrl+O, Enter, Ctrl+X.

**Verificación:** Reinicia y ejecuta `echo $XDG_SESSION_TYPE` (debería mostrar `x11`, no `wayland`).

**Por qué:** Xorg es más compatible con GPUs NVIDIA.

### Paso 2: Actualiza el Sistema
Actualiza paquetes para seguridad y compatibilidad.

```bash
sudo apt update && sudo apt upgrade -y
```

**Verificación:**
- `apt list --upgradable` (debería estar vacío si todo se actualizó).
- Reinicia: `sudo reboot`.

**Por qué:** Evita conflictos con versiones obsoletas.

### Paso 3: Instala Dependencias Comunes
Instala herramientas esenciales para desarrollo, gráficos, networking y calidad de vida (como monitoreo y troubleshooting).

```bash
sudo apt install -y build-essential dkms pkg-config libglvnd-dev libgl1-mesa-dev libegl1-mesa-dev libgles2-mesa-dev libx11-dev libxmu-dev libxi-dev libglu1-mesa-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev mesa-utils inxi net-tools openssh-server curl git wget htop ncdu tree traceroute nmap vim lm-sensors neofetch
```

**Verificación:**
- `gcc --version` (debería mostrar versión instalada).
- `glxinfo | grep "OpenGL"` (verifica OpenGL básico).
- `traceroute google.com` (debería mostrar ruta de red).
- `htop` (abre monitor de procesos; presiona q para salir).

**Por qué:** Estos paquetes son necesarios para compilar drivers y herramientas CUDA/GPU. Las adicionales mejoran la experiencia: `htop` para monitoreo, `traceroute` para debugging de red, `vim` para edición, etc.

### Paso 4: Configura el Firewall para SSH (Opcional)
Habilita SSH y configura UFW para acceso remoto seguro (opcional, si no usas firewall, omite este paso).

```bash
sudo ufw allow ssh
sudo ufw --force enable
```

**Verificación (opcional):**
- `sudo ufw status` (debería mostrar SSH allowed y status active).
- Prueba SSH desde otro dispositivo: `ssh usuario@ip_de_tu_pc`.

**Por qué (opcional):** SSH es útil para administración remota; UFW protege el sistema. Si no lo habilitas, asegúrate de seguridad alternativa.

### Paso 5: Preparación Específica por Versión de Ubuntu
Dependiendo de tu versión, instala dependencias adicionales.

* **Para Ubuntu 22.04 LTS:**
  Instala GCC/G++ 12 (necesario para CUDA en versiones antiguas).

  ```bash
  sudo apt update
  sudo apt install -y gcc-12 g++-12
  ```

  Registra como alternativas:
  ```bash
  sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 120
  sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 120
  sudo update-alternatives --config gcc  # Selecciona gcc-12 si pregunta
  sudo update-alternatives --config g++
  ```

  **Verificación:**
  ```bash
  gcc --version  # Debería mostrar gcc 12.x.x
  g++ --version
  ```

* **Para Ubuntu 24.04 LTS:**
  Instala `libtinfo5` (para compatibilidad con herramientas antiguas).

  ```bash
  wget http://security.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2ubuntu0.1_amd64.deb
  sudo apt install ./libtinfo5_6.3-2ubuntu0.1_amd64.deb
  rm libtinfo5_6.3-2ubuntu0.1_amd64.deb
  ```

  **Verificación:**
  ```bash
  dpkg -l | grep libtinfo5  # Debería mostrar instalado
  ```

**Por qué:** Diferentes versiones de Ubuntu tienen dependencias específicas para NVIDIA/CUDA.

### Troubleshooting Común en Preparación
- **Error en apt update:** Verifica conexión: `ping -c 4 archive.ubuntu.com`. Si falla, cambia mirrors en `/etc/apt/sources.list`.
- **GCC no se instala:** Ejecuta `sudo apt --fix-broken install` si hay dependencias rotas.
- **Wayland no se desactiva:** Edita `/etc/gdm3/custom.conf` manualmente y reinicia.
- **Firewall bloquea conexiones:** `sudo ufw disable` temporalmente para pruebas.
- **Paquetes faltan:** `sudo apt search <paquete>` para verificar nombres exactos.

> **Advertencia:** Verifica compatibilidad de drivers y CUDA antes de instalar. Los comandos con `sudo` pueden alterar el sistema.

---

## 4. Instalación de Drivers de NVIDIA en Ubuntu

> **Nota:** Esta sección asume Ubuntu 22.04 o 24.04 LTS. Asegúrate de tener acceso root (sudo). Si usas una versión diferente, verifica compatibilidad en el Anexo B.

### Paso 1: Identifica tu GPU NVIDIA
Antes de instalar, confirma el modelo exacto de tu GPU para descargar el driver correcto.

```bash
lspci | grep -i nvidia
```

**Ejemplo de salida esperada:**
```
01:00.0 VGA compatible controller: NVIDIA Corporation GA104 [GeForce RTX 3070] (rev a1)
```

- Si no ves salida, tu GPU no es NVIDIA o no está detectada (revisa BIOS/UEFI).
- Anota el modelo (ej. RTX 3070) para el siguiente paso.

### Paso 2: Verifica Compatibilidad
- Consulta el Anexo B para confirmar que tu GPU es compatible con drivers recientes.
- Visita [https://www.nvidia.com/drivers/](https://www.nvidia.com/drivers/) e ingresa tu modelo para ver drivers disponibles.
- **Recomendación:** Usa drivers de la serie 550.x o superior para Ubuntu 24.04 (ej. 550.54.15 para compatibilidad con CUDA 12.8).

### Paso 3: Elimina Drivers Antiguos (Obligatorio)
Si has instalado drivers previamente (incluso desde repositorios), elimínalos para evitar conflictos.

```bash
sudo apt-get purge '^nvidia-.*' -y
sudo apt-get purge nvidia-* --autoremove -y
sudo apt-get autoremove -y
sudo reboot
```

**Verificación:** Después del reinicio, ejecuta `lspci | grep -i nvidia` nuevamente. No deberías ver drivers cargados (puedes ignorar la línea de hardware).

### Paso 4: Descarga el Driver Oficial
- Ve a [https://www.nvidia.com/drivers/](https://www.nvidia.com/drivers/).
- Selecciona: Product Type: GeForce/Quadro/Tesla, Product Series: Tu serie (ej. GeForce RTX 30 Series), Product: Tu modelo, Operating System: Linux 64-bit, Language: English.
- Descarga el archivo `.run` (ej. NVIDIA-Linux-x86_64-550.54.15.run).

**Descarga por terminal (ejemplo para RTX 30/40 Series en Ubuntu 24.04):**
```bash
wget https://us.download.nvidia.com/XFree86/Linux-x86_64/550.54/NVIDIA-Linux-x86_64-550.54.15.run
```

- Si el enlace cambia, busca el exacto en la web de NVIDIA.
- **Verificación:** Lista el archivo descargado: `ls -la NVIDIA-Linux-x86_64-*.run`

### Paso 5: Prepara la Instalación
Cambia al modo texto para evitar conflictos gráficos (recomendado, especialmente en servidores).

```bash
sudo systemctl set-default multi-user.target
sudo reboot
```

Después del reinicio, inicia sesión en modo texto y da permisos de ejecución al archivo:

```bash
sudo chmod +x NVIDIA-Linux-x86_64-550.54.15.run
```

**Verificación:** Confirma permisos: `ls -la NVIDIA-Linux-x86_64-550.54.15.run` (debería mostrar -rwxr-xr-x).

### Paso 6: Instala el Driver
Ejecuta el instalador con flags para compatibilidad y actualizaciones futuras.

```bash
sudo ./NVIDIA-Linux-x86_64-550.54.15.run --dkms --no-opengl-files --no-man-page --no-install-compat32-libs
```

**Respuestas a las preguntas del instalador (presiona Enter para aceptar defaults, o responde como se indica):**
- `The distribution-provided pre-install script failed! Are you sure you want to continue?` → `Yes` (continúa, es común en Ubuntu).
- `Would you like to register the kernel module sources with DKMS?` → `Yes` (facilita actualizaciones de kernel).
- `Install NVIDIA's 32-bit compatibility libraries?` → `No` (a menos que uses aplicaciones 32-bit).
- `Would you like to run nvidia-xconfig?` → `No` (configuraremos manualmente si es necesario).
- `Would you like to enable nvidia-apply-extra-quirks?` → `Yes` (mejora estabilidad).

La instalación tomará unos minutos. Si falla, revisa logs en `/var/log/nvidia-installer.log`.

**Verificación post-instalación:**
```bash
nvidia-smi
```

**Ejemplo de salida esperada:**
```
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 550.54.15    Driver Version: 550.54.15    CUDA Version: 12.4     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|                               |                      |               MIG M. |
|===============================+======================+======================+
|   0  NVIDIA GeForce ...       Off                  | 00000000:01:00.0 Off |
...
+-----------------------------------------------------------------------------+
```

- Si ves "NVIDIA-SMI has failed" o no hay salida, el driver no se instaló correctamente.

### Paso 7: Reactiva el Entorno Gráfico (si lo desactivaste)
Si instalaste en modo texto, vuelve al modo gráfico:

```bash
sudo systemctl set-default graphical.target
sudo reboot
```

**Verificación final:** Después del reinicio, abre una terminal y ejecuta `nvidia-smi`. Deberías ver la info de tu GPU.

### Método Alternativo: Instalación desde Repositorios APT (Más Fácil pero Menos Óptimo)
Si prefieres un método más simple sin descargar .run, usa los repositorios de Ubuntu. Este instala drivers desde paquetes APT, pero puede ser menos actualizado que el .run oficial.

#### Paso 1: Actualiza y Agrega PPA (Opcional para Versiones Más Nuevas)
Para drivers más recientes, agrega el PPA de graphics-drivers:
```bash
sudo add-apt-repository ppa:graphics-drivers/ppa -y
sudo apt update
```

#### Paso 2: Instala el Driver
Busca versiones disponibles:
```bash
ubuntu-drivers list
```

Instala la recomendada (ej. nvidia-driver-550):
```bash
sudo apt install -y nvidia-driver-550
```

**Verificación:**
```bash
nvidia-smi
# Debería mostrar info de GPU
```

#### Paso 3: Reinicia
```bash
sudo reboot
```

**Ventajas:** Fácil, actualizable con apt. **Desventajas:** Versiones pueden ser más viejas; no tan optimizado como .run oficial.

### Troubleshooting Común para Drivers NVIDIA
- **Error: "The distribution-provided pre-install script failed"**: Ignóralo y continúa; es un warning no crítico.
- **Pantalla negra después del reinicio**: Reinicia en modo recovery (desde GRUB, selecciona "Advanced options" > recovery mode) y ejecuta `sudo apt-get purge nvidia-*` para desinstalar.
- **Driver no detectado**: Verifica que Secure Boot esté desactivado en BIOS/UEFI. Ejecuta `dmesg | grep nvidia` para logs de error.
- **Problemas con kernel nuevo**: Si actualizas el kernel, ejecuta `sudo dkms autoinstall` para recompilar módulos.
- **Si nada funciona**: Prueba drivers desde repositorios oficiales: `sudo apt install nvidia-driver-550` (pero menos óptimo que .run).

> **Tip:** Si tienes problemas con el entorno gráfico, revisa la sección 8 sobre gestión de la interfaz gráfica.

---

## 5. Instalación de CUDA Toolkit

> **Nota:** CUDA Toolkit es esencial para desarrollo GPU. Asume drivers NVIDIA instalados (sección 4). **Antes de instalar, verifica la versión más moderna compatible con tu GPU y sistema en [https://developer.nvidia.com/cuda-downloads](https://developer.nvidia.com/cuda-downloads). La versión 12.8 mostrada aquí es un ejemplo; usa la más reciente disponible para tu hardware (ej. 12.9 si sale).** Consulta el Anexo B para compatibilidad.

### Método 1: Instalación mediante Repositorio APT (Recomendado)

#### Paso 1: Agrega el Repositorio de NVIDIA
Descarga e instala la clave para Ubuntu 24.04:

```bash
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
```

**Verificación:** `apt search cuda` debería mostrar paquetes disponibles.

#### Paso 2: Instala CUDA Toolkit
Para la última versión:
```bash
sudo apt-get install -y cuda-toolkit
```

Para versión específica (ej. 12.8):
```bash
sudo apt-get install -y cuda-toolkit-12-8
```

**Verificación:** `nvcc --version` (debería mostrar CUDA 12.8).

#### Paso 3: Configura Variables de Entorno
Edita `.bashrc`:
```bash
nano ~/.bashrc
```

Agrega al final:
```bash
export PATH=/usr/local/cuda-12.8/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda-12.8/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
```

Guarda y recarga:
```bash
source ~/.bashrc
```

**Verificación:** `which nvcc` (debería mostrar /usr/local/cuda-12.8/bin/nvcc).

### Método 2: Instalación Manual con Archivo .run

#### Paso 1: Descarga el Instalador
Ve a [https://developer.nvidia.com/cuda-downloads](https://developer.nvidia.com/cuda-downloads), selecciona Linux/x86_64/Ubuntu/24.04/runfile.

Descarga:
```bash
wget https://developer.download.nvidia.com/compute/cuda/12.8.0/local_installers/cuda_12.8.0_550.54.15_linux.run
```

**Verificación:** `ls -la cuda_*.run`

#### Paso 2: Prepara el Sistema
Cambia a modo texto:
```bash
sudo systemctl set-default multi-user.target
sudo reboot
```

Da permisos:
```bash
chmod +x cuda_12.8.0_550.54.15_linux.run
```

#### Paso 3: Ejecuta el Instalador
```bash
sudo sh cuda_12.8.0_550.54.15_linux.run
```

Respuestas:
- Acepta EULA.
- NO instales driver (ya tienes uno).
- Selecciona: CUDA Toolkit (sí), Samples (opcional), Documentation (opcional).

#### Paso 4: Configura Variables de Entorno
Igual que en Método 1.

#### Paso 5: Verifica y Reactiva Gráfico
```bash
nvcc --version
nvidia-smi
sudo systemctl set-default graphical.target
sudo reboot
```

### Instalación de cuDNN (Opcional - Para Deep Learning)

cuDNN acelera redes neuronales en CUDA. Instálalo después de CUDA.

#### Paso 1: Descarga cuDNN
Ve a [https://developer.nvidia.com/cudnn](https://developer.nvidia.com/cudnn), descarga para CUDA 12.x (ej. cuDNN 9.3 para CUDA 12.8).

Para Ubuntu: Descarga .deb local (ej. cudnn-local-repo-ubuntu2404-9.3.0_1.0-1_amd64.deb).

```bash
wget https://developer.download.nvidia.com/compute/cudnn/9.3.0/local_installers/cudnn-local-repo-ubuntu2404-9.3.0_1.0-1_amd64.deb
```

#### Paso 2: Instala cuDNN
```bash
sudo dpkg -i cudnn-local-repo-ubuntu2404-9.3.0_1.0-1_amd64.deb
sudo cp /var/cudnn-local-repo-ubuntu2404-9.3.0/cudnn-local-*-keyring.gpg /usr/share/keyrings/
sudo apt-get update
sudo apt-get install -y cudnn9-cuda-12-8
```

**Verificación:**
```bash
dpkg -l | grep cudnn
# Debería mostrar cudnn9-cuda-12-8 instalado
```

#### Paso 3: Verifica Integración con CUDA
Compila un sample:
```bash
cd /usr/local/cuda-12.8/samples/1_Utilities/deviceQuery
make
./deviceQuery
```

Debería mostrar info de GPU y CUDA.

### ¿Qué Método Elegir?

| Característica | Repositorio APT | Instalador .run |
|----------------|-----------------|-----------------|
| **Facilidad** | ⭐⭐⭐⭐⭐ Fácil | ⭐⭐⭐ Moderado |
| **Actualizaciones** | ⭐⭐⭐⭐⭐ Automáticas | ⭐⭐ Manual |
| **Control** | ⭐⭐⭐ Limitado | ⭐⭐⭐⭐⭐ Total |
| **Recomendado para** | Usuarios generales | Desarrolladores |

> **Recomendación:** APT para simplicidad. Instala cuDNN después.

### Troubleshooting para CUDA/cuDNN
- **nvcc no encontrado:** Verifica PATH en `.bashrc`.
- **Errores de compilación:** Asegura GCC compatible (ver sección 3).
- **cuDNN no instala:** Verifica versión compatible con CUDA.
- **GPU no detectada:** `nvidia-smi` para check.

> **Advertencia:** Reinicio puede ser necesario. Si conflictos, revisa sección 4.

---

## 6. Configuración Específica para Estaciones de Compresión

> **Nota:** Esta sección instala herramientas para estaciones de compresión/data, asumiendo Ubuntu 24.04.1 LTS con CUDA/drivers instalados. Las herramientas son opcionales; instala solo lo necesario. Verifica versiones en sitios oficiales.

### Instalación de MongoDB (Base de Datos NoSQL)

#### Paso 1: Agrega el Repositorio
Importa la clave GPG:
```bash
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg
```

Agrega el repositorio (ajusta `jammy` por `noble` si usas Ubuntu 24.04):
```bash
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
```

#### Paso 2: Instala MongoDB
```bash
sudo apt-get update
sudo apt-get install -y mongodb-org
```

#### Paso 3: Inicia y Habilita el Servicio
```bash
sudo systemctl start mongod
sudo systemctl enable mongod
```

**Verificación:**
```bash
sudo systemctl status mongod
mongosh --eval "db.runCommand('ping')"
# Debería mostrar "ok": 1
```

### Instalación de MongoDB Compass (GUI para MongoDB)

#### Paso 1: Descarga e Instala
Descarga desde [https://www.mongodb.com/try/download/compass](https://www.mongodb.com/try/download/compass):
```bash
wget https://downloads.mongodb.com/compass/mongodb-compass_1.43.4_amd64.deb
sudo apt install -y ./mongodb-compass_1.43.4_amd64.deb
```

Si dependencias faltan:
```bash
sudo apt --fix-broken install
```

#### Paso 2: Ejecuta Compass
```bash
mongodb-compass &
```

**Verificación:** Abre la app y conecta a `mongodb://localhost:27017`.

**Desinstalación (opcional):**
```bash
sudo apt remove -y mongodb-compass
```

### Instalación de EMQX (Broker MQTT)

#### Paso 1: Instala desde Repositorio
```bash
curl -sL https://assets.emqx.com/scripts/install-emqx-deb.sh | sudo bash
sudo apt-get install -y emqx
```

#### Paso 2: Inicia y Habilita
```bash
sudo systemctl start emqx
sudo systemctl enable emqx
```

**Verificación:**
```bash
sudo systemctl status emqx
# Dashboard en http://localhost:18083 (usuario: admin, pass: public)
```

### Instalación de Golang

#### Paso 1: Instala con Snap
```bash
sudo snap install go --classic
```

**Verificación:**
```bash
go version
# Debería mostrar versión instalada
```

### Instalación de Visual Studio Code

#### Paso 1: Instala con Snap
```bash
sudo snap install code --classic
```

**Verificación:**
```bash
code --version
# Debería mostrar versión
```

### Instalación de GStreamer y Plugins

#### Paso 1: Instala Plugins
```bash
sudo apt-get install -y gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 gstreamer1.0-qt5 gstreamer1.0-pulseaudio gstreamer1.0-rtsp
```

**Verificación:**
```bash
gst-inspect-1.0 rtspclientsink
gst-inspect-1.0 nvh264enc
# Debería mostrar info del plugin
```

### Instalación de Angry IP Scanner

#### Paso 1: Descarga e Instala
Descarga desde [https://github.com/angryip/ipscan/releases](https://github.com/angryip/ipscan/releases):
```bash
wget https://github.com/angryip/ipscan/releases/download/3.9.1/ipscan_3.9.1_amd64.deb
sudo apt install -y ./ipscan_3.9.1_amd64.deb
```

**Verificación:** Ejecuta `ipscan` desde terminal o menú.

### Instalación de AnyDesk (Soporte Remoto)

#### Paso 1: Agrega Repositorio e Instala
```bash
sudo apt update
sudo apt install -y ca-certificates curl apt-transport-https
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://keys.anydesk.com/repos/DEB-GPG-KEY -o /etc/apt/keyrings/keys.anydesk.com.asc
sudo chmod a+r /etc/apt/keyrings/keys.anydesk.com.asc
echo "deb [signed-by=/etc/apt/keyrings/keys.anydesk.com.asc] https://deb.anydesk.com all main" | sudo tee /etc/apt/sources.list.d/anydesk-stable.list > /dev/null
sudo apt update
sudo apt install -y anydesk
```

#### Paso 2: Configura Firewall
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 6568/tcp
sudo ufw allow 50001:50003/udp
```

**Verificación:** Ejecuta `anydesk` y anota el ID.

### Instalación de RustDesk (Soporte Remoto Alternativo)

#### Paso 1: Descarga e Instala
Descarga desde [https://github.com/rustdesk/rustdesk/releases](https://github.com/rustdesk/rustdesk/releases):
```bash
wget https://github.com/rustdesk/rustdesk/releases/download/1.2.3/rustdesk-1.2.3-x86_64.deb
sudo apt install -y ./rustdesk-1.2.3-x86_64.deb
```

**Verificación:** Ejecuta `rustdesk` y configura ID/contraseña.

### Configuración de Puertos para Estaciones de Compresión (Opcional)
Si habilitaste UFW en la sección 3, abre los puertos necesarios para que las aplicaciones funcionen correctamente. Si no usas firewall, omite esta sección.

| Aplicación | Puertos | Protocolo | Comando para Abrir (Opcional) |
|------------|---------|-----------|-------------------------------|
| MongoDB | 27017 | TCP | `sudo ufw allow 27017/tcp` |
| EMQX MQTT | 1883 | TCP | `sudo ufw allow 1883/tcp` |
| EMQX Dashboard | 18083 | TCP | `sudo ufw allow 18083/tcp` |
| GStreamer RTSP | 554 | TCP/UDP | `sudo ufw allow 554/tcp && sudo ufw allow 554/udp` |
| AnyDesk | 80, 443, 6568 | TCP | `sudo ufw allow 80/tcp && sudo ufw allow 443/tcp && sudo ufw allow 6568/tcp` |
| AnyDesk (UDP) | 50001-50003 | UDP | `sudo ufw allow 50001:50003/udp` |
| RustDesk | Dinámicos (ver logs) | TCP/UDP | Configura según necesidad |
| SSH (si usas) | 22 (o custom) | TCP | `sudo ufw allow ssh` |

**Verificación general (opcional):**
```bash
sudo ufw status
netstat -tlnp | grep LISTEN  # Lista puertos abiertos
```

**Tips (opcional):**
- Para acceso remoto, abre solo puertos necesarios y desde IPs específicas: `sudo ufw allow from <IP> to any port 27017`.
- Si usas VPN, ajusta reglas.
- Revisa logs de apps para puertos adicionales (ej. `sudo journalctl -u emqx`).

### Tips Generales
- Verifica servicios: `sudo systemctl status <servicio>`.
- Configura contraseñas únicas para acceso remoto.
- Revisa plugins: Usa `gst-inspect-1.0` para GStreamer.

### Troubleshooting
- **MongoDB no inicia:** Revisa logs: `sudo journalctl -u mongod`.
- **EMQX falla:** Verifica puertos: `netstat -tlnp | grep 1883`.
- **GStreamer plugins faltan:** `sudo apt install gstreamer1.0-plugins-*`.
- **AnyDesk/RustDesk no conecta:** Desactiva firewall temporalmente para test.

> **Recursos Adicionales:**
> * [MongoDB Docs](https://www.mongodb.com/docs/)
> * [EMQX Docs](https://www.emqx.io/docs/)
> * [GStreamer Docs](https://gstreamer.freedesktop.org/documentation/)

---

## 7. Configuración Específica para Estaciones de Analítica

> **Nota:** Esta sección instala herramientas para analítica/machine learning, asumiendo Ubuntu 24.04.1 LTS con CUDA instalado. Instala solo lo necesario.

### Configuración de MongoDB (Base de Datos y Usuario)

#### Paso 1: Accede a la Consola
```bash
mongosh
```

#### Paso 2: Crea Base de Datos y Usuario
Reemplaza placeholders:
```javascript
use NOMBRE_BD
db.createUser({
  user: "USUARIO",
  pwd: "PASSWORD",
  roles: [
    {
      role: "readWrite",
      db: "NOMBRE_BD"
    }
  ]
})
```

Sal con `exit`.

#### Paso 3: Habilita Autorización
Edita config:
```bash
sudo nano /etc/mongod.conf
```

Agrega bajo `security:`:
```yaml
security:
  authorization: enabled
```

Guarda y reinicia:
```bash
sudo systemctl restart mongod
```

**Verificación:**
```bash
mongosh -u USUARIO -p PASSWORD --authenticationDatabase NOMBRE_BD
# Debería conectar
```

### Instalación de Node-RED

#### Paso 1: Ejecuta el Script de Instalación
```bash
bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered)
```

#### Paso 2: Habilita y Inicia el Servicio
```bash
sudo systemctl enable nodered
sudo systemctl start nodered
```

**Verificación:**
```bash
sudo systemctl status nodered
# Dashboard en http://localhost:1880
```

### Instalación de Python y Bibliotecas para Machine Learning

#### Paso 1: Instala Python y Pip
```bash
sudo apt install -y python3 python3-pip
```

#### Paso 2: Actualiza Pip
```bash
pip3 install --upgrade pip
```

#### Paso 3: Instala Bibliotecas
```bash
pip3 install pandas numpy scikit-learn paho-mqtt ultralytics
```

**Verificación:**
```bash
python3 -c "import pandas, numpy, sklearn; print('Bibliotecas OK')"
# Debería imprimir sin errores
```

### Configuración de Puertos para Estaciones de Analítica (Opcional)
Si usas firewall, abre puertos:

| Aplicación | Puertos | Protocolo | Comando |
|------------|---------|-----------|---------|
| MongoDB | 27017 | TCP | `sudo ufw allow 27017/tcp` |
| Node-RED | 1880 | TCP | `sudo ufw allow 1880/tcp` |

**Verificación:**
```bash
sudo ufw status
```

### Tips Generales
- Usa entornos virtuales: `python3 -m venv ml_env && source ml_env/bin/activate`.
- Actualiza bibliotecas: `pip3 install --upgrade <lib>`.

### Troubleshooting
- **MongoDB auth falla:** Verifica config en `/etc/mongod.conf`.
- **Node-RED no inicia:** Revisa logs: `sudo journalctl -u nodered`.
- **Pip instala lento:** Usa mirror: `pip3 install --index-url https://pypi.org/simple <lib>`.

> **Recursos Adicionales:**
> * [Node-RED Docs](https://nodered.org/docs/)
> * [MongoDB Docs](https://www.mongodb.com/docs/)
> * [Pandas Docs](https://pandas.pydata.org/docs/)

---

## 8. Gestión de la Interfaz Gráfica

> **Nota:** Ubuntu usa GDM3 como display manager. Gestiona el entorno gráfico para liberar recursos en servidores o solucionar issues con GPUs.

### Verificar Estado Actual
Antes de cambiar, checkea el target actual:
```bash
systemctl get-default  # Debería mostrar graphical.target o multi-user.target
who  # Muestra sesiones activas
```

### Desactivar Entorno Gráfico (Modo Texto/Servidor)
Útil para servidores headless o troubleshooting.

#### Paso 1: Deshabilita GDM3
```bash
sudo systemctl disable gdm3
sudo systemctl set-default multi-user.target
```

#### Paso 2: Reinicia
```bash
sudo reboot
```

**Verificación:**
```bash
systemctl get-default  # multi-user.target
# No verás entorno gráfico al bootear
```

### Reactivar Entorno Gráfico
Para uso desktop normal.

#### Paso 1: Habilita GDM3
```bash
sudo systemctl enable gdm3
sudo systemctl set-default graphical.target
```

#### Paso 2: Reinicia
```bash
sudo reboot
```

**Verificación:**
```bash
systemctl get-default  # graphical.target
# Deberías ver login gráfico
```

### Alternativas y Tips
- **Cambiar sin reinicio:** Usa `sudo systemctl isolate multi-user.target` (temporal).
- **Otro DM:** Si prefieres LightDM: `sudo apt install lightdm && sudo dpkg-reconfigure lightdm`.
- **Issues con GPUs:** Si pantalla negra, fuerza Xorg en `/etc/gdm3/custom.conf` (ver sección 3).

### Troubleshooting
- **GDM3 no inicia:** Logs: `sudo journalctl -u gdm`.
- **Pantalla negra:** Agrega `nomodeset` en GRUB (ver sección 2).
- **No cambia target:** `sudo systemctl daemon-reload` y reintenta.

> **Explicación:** Desactivar libera RAM/CPU; reactivar para apps GUI. Usa según necesidad.

---

## 9. Solución de Problemas Comunes con Redes en Placas Nuevas

> **Nota:** Problemas de red en placas nuevas suelen ser por drivers incompatibles. Usa `lspci | grep Network` para identificar el chip. Reinicia después de cambios.

### Problemas con Realtek RTL8125 (Ethernet)

#### Diagnóstico
```bash
ip link show  # Busca ethX/enpXsY DOWN
lspci | grep RTL8125  # Confirma chip
```

#### Solución
1. Actualiza sistema: `sudo apt update && sudo apt full-upgrade -y`
2. Agrega PPA: `sudo add-apt-repository ppa:kelebek333/rtl-kernel -y && sudo apt update`
3. Instala driver: `sudo apt install r8125-dkms -y`
4. Bloquea antiguo: `echo 'blacklist r8169' | sudo tee /etc/modprobe.d/blacklist-r8169.conf`
5. Actualiza initramfs: `sudo update-initramfs -u`
6. Reinicia: `sudo reboot`

**Verificación:** `ip link show` (debería estar UP), `lspci | grep -i ethernet`

### Problemas con Intel Ethernet (ej. I219, I225)

#### Diagnóstico
```bash
lspci | grep Ethernet  # Busca Intel
dmesg | grep e1000e  # Errores?
```

#### Solución
1. Instala driver actualizado: `sudo apt install -y backport-iwlwifi-dkms`
2. O usa PPA: `sudo add-apt-repository ppa:canonical-hwe-team/backport-iwlwifi -y && sudo apt update && sudo apt install backport-iwlwifi-dkms`
3. Reinicia: `sudo reboot`

**Verificación:** `ip a` (IP asignada), `ping 8.8.8.8`

### Problemas con Wi-Fi (Broadcom, etc.)

#### Diagnóstico
```bash
iwconfig  # Lista interfaces Wi-Fi
lspci | grep Network  # Identifica chip
```

#### Solución para Broadcom
1. Instala bcmwl: `sudo apt install bcmwl-kernel-source`
2. Reinicia: `sudo reboot`

**Verificación:** `iwconfig` (debería mostrar wlan0 UP)

### DNS No Resuelve Nombres

#### Diagnóstico
```bash
nslookup google.com  # Falla?
cat /etc/resolv.conf  # Nameservers
```

#### Solución
1. Edita resolv.conf: `sudo nano /etc/resolv.conf`
2. Agrega: `nameserver 8.8.8.8` y `nameserver 1.1.1.1`
3. O usa systemd: `sudo systemctl restart systemd-resolved`

**Verificación:** `nslookup google.com` (debería resolver)

### Conexión Lenta o Intermitente

#### Diagnóstico
```bash
speedtest-cli  # Velocidad
dmesg | grep -i network  # Errores
```

#### Solución
1. Desactiva IPv6: `sudo nano /etc/sysctl.conf` agrega `net.ipv6.conf.all.disable_ipv6=1`
2. Aplica: `sudo sysctl -p`
3. Cambia MTU: `sudo ip link set dev enpXsY mtu 1450`

**Verificación:** `speedtest-cli`, reinicia y testea.

### Configurar IP Estática

#### Solución
1. Edita Netplan: `sudo nano /etc/netplan/01-netcfg.yaml`
2. Ejemplo:
   ```yaml
   network:
     version: 2
     ethernets:
       enp0s3:
         dhcp4: no
         addresses: [192.168.1.100/24]
         gateway4: 192.168.1.1
         nameservers:
           addresses: [8.8.8.8, 1.1.1.1]
   ```
3. Aplica: `sudo netplan apply`

**Verificación:** `ip a` (IP estática), `ping google.com`

### Problemas con VPN

#### Diagnóstico
```bash
sudo systemctl status openvpn  # Si usas OpenVPN
journalctl -u openvpn  # Logs
```

#### Solución
1. Instala OpenVPN: `sudo apt install openvpn`
2. Conecta: `sudo openvpn config.ovpn`
3. Para WireGuard: `sudo apt install wireguard` y configura.

**Verificación:** `ip a` (tun interface), `curl ifconfig.me` (IP externa cambia)

### Troubleshooting General
- **No conecta:** `sudo systemctl restart NetworkManager`
- **Drivers faltan:** Busca en repos: `sudo apt search <chip>`
- **Logs:** `sudo journalctl -u NetworkManager`
- **Reset:** `sudo nmcli networking off && sudo nmcli networking on`

> **Tip:** Si nada funciona, instala drivers desde sitio del fabricante o usa USB Ethernet.

---

## 10. Wake-on-LAN (WOL): Windows a Windows y Ubuntu a Windows

> **Nota:** WOL despierta PCs por red enviando un "paquete mágico". Requiere Ethernet (no Wi-Fi). Configura BIOS y OS primero.

### Configurar WOL en el Equipo Destino (Windows/Ubuntu)

#### En BIOS/UEFI
1. Entra a BIOS (F2/DEL).
2. Busca "Power Management" > "Wake on LAN" > "Enabled".
3. "AC Power Loss" > "Power On" (opcional).
4. Guarda y sal.

#### En Windows
1. Ejecuta `powercfg /devicequery wake_armed` (lista dispositivos que pueden despertar).
2. En Device Manager > Network Adapter > Properties > Power Management > Marca "Allow this device to wake the computer".
3. En Power Options > "Allow wake timers".

#### En Ubuntu
1. Instala ethtool: `sudo apt install ethtool`
2. Habilita WOL: `sudo ethtool -s enpXsY wol g` (reemplaza enpXsY por interfaz, ej. `ip link show`)
3. Verifica: `sudo ethtool enpXsY | grep Wake-on`
4. Para persistencia: Crea `/etc/systemd/system/wol.service` con:
   ```
   [Unit]
   Description=Enable WOL
   After=network.target

   [Service]
   Type=oneshot
   ExecStart=/usr/sbin/ethtool -s enpXsY wol g

   [Install]
   WantedBy=multi-user.target
   ```
   Habilita: `sudo systemctl enable wol`

**Verificación:** Apaga el PC, espera 1 min, envía paquete desde otro dispositivo.

### Enviar Paquete WOL desde Windows (a Windows o Ubuntu)

#### Script PowerShell
Guarda como `Send-WOL.ps1` y ejecuta: `.\Send-WOL.ps1 -Mac AA:BB:CC:DD:EE:FF`

Funciona para despertar PCs Windows o Ubuntu configurados para WOL.

```powershell
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)] [string]$Mac,
  [string]$Broadcast = "255.255.255.255",
  [int]$Port = 9
)

$macClean = ($Mac -replace '[:-]','')
if ($macClean.Length -ne 12) { throw "MAC inválida: $Mac" }

$macBytes = 0..5 | ForEach-Object { [Convert]::ToByte($macClean.Substring($_*2,2),16) }

$packet = New-Object byte[] (6 + 16*6)
for ($i=0; $i -lt 6; $i++) { $packet[$i] = 0xFF }
for ($i=0; $i -lt 16; $i++) { [Array]::Copy($macBytes, 0, $packet, 6 + $i*6, 6) }

$udp = New-Object System.Net.Sockets.UdpClient
$udp.EnableBroadcast = $true
[void]$udp.Send($packet, $packet.Length, $Broadcast, $Port)
$udp.Close()
Write-Host "WOL enviado a $Mac via $Broadcast:$Port"
```

### Enviar Paquete WOL desde Ubuntu

#### Instala herramientas
```bash
sudo apt install wakeonlan etherwake
```

#### Envía paquete
```bash
wakeonlan -i 192.168.1.255 AA:BB:CC:DD:EE:FF  # Broadcast IP de tu red
# o
sudo etherwake -i enpXsY AA:BB:CC:DD:EE:FF
```

**Verificación:** Usa Wireshark/tcpdump para ver paquete: `sudo tcpdump -i enpXsY port 9`

### Troubleshooting
- **No despierta:** Verifica BIOS, cable Ethernet, firewall bloquea puerto 9.
- **MAC incorrecta:** `ip link show` o `arp -a` para obtener.
- **Broadcast IP:** Usa `ip route | grep default` para subnet.
- **Persistencia:** En Ubuntu, agrega a cron: `@reboot sudo ethtool -s enpXsY wol g`

> **Nota:** WOL por Wi-Fi no funciona. Usa Ethernet. Prueba con PCs en misma red local.

---

## 11. Script de Post-Instalación (Opcional)

> **Nota:** Este script automatiza la preparación inicial (sección 3). Actualízalo según tus necesidades. Ejecuta como root o con sudo.

### Script Mejorado `setup.sh`
Incluye dependencias adicionales y opciones.

```bash
#!/bin/bash
# Script para la preparación inicial del sistema Ubuntu
# Versión mejorada con más herramientas

set -e  # Salir en error

echo "--- Actualizando el sistema ---"
sudo apt update && sudo apt upgrade -y

echo "--- Instalando dependencias comunes ---"
sudo apt install -y build-essential dkms pkg-config libglvnd-dev libgl1-mesa-dev libegl1-mesa-dev libgles2-mesa-dev libx11-dev libxmu-dev libxi-dev libglu1-mesa-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev mesa-utils inxi net-tools openssh-server curl git wget htop ncdu tree traceroute nmap vim lm-sensors neofetch

echo "--- Configurando GDM3 (desactivar Wayland) ---"
sudo sed -i 's/#WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf

echo "--- Configurando firewall (opcional) ---"
read -p "¿Habilitar UFW con SSH? (s/n): " ufw_choice
if [[ $ufw_choice =~ ^[sS]$ ]]; then
  sudo ufw allow ssh
  sudo ufw --force enable
fi

echo "--- Verificaciones ---"
echo "GCC versión: $(gcc --version | head -1)"
echo "Git versión: $(git --version)"
echo "Firewall status: $(sudo ufw status | head -1)"

echo "--- Preparación completada. Reinicio recomendado. ---"
read -p "¿Reiniciar ahora? (s/n): " choice
case "$choice" in
  s|S ) sudo reboot;;
  * ) echo "Ejecuta 'sudo reboot' manualmente.";;
esac
```

### Cómo Usarlo
1. Crea el archivo: `nano setup.sh`
2. Pega el contenido y guarda.
3. Permisos: `chmod +x setup.sh`
4. Ejecuta: `./setup.sh` (o `sudo ./setup.sh` si necesita root)

### Personalización
- Agrega más installs: `sudo apt install -y <paquete>`
- Quita opciones: Comenta líneas con `#`
- Logging: Agrega `>> setup.log` a comandos.

### Troubleshooting
- Si falla: Revisa logs en terminal.
- Permisos: Asegura que el script tenga ejecución.
- Dependencias: Verifica internet para apt.

---

## 12. Buenas Prácticas de Seguridad (Opcional)

> **Nota:** Estas medidas fortalecen Ubuntu, especialmente para acceso remoto. Aplica solo lo necesario; más seguridad puede complicar uso.

### SSH Seguro

#### Cambiar Puerto SSH
Reduce escaneo de bots.

1. Edita config: `sudo nano /etc/ssh/sshd_config`
2. Cambia: `Port 22` a `Port 2222`
3. Reinicia SSH: `sudo systemctl restart ssh`
4. Firewall: `sudo ufw allow 2222/tcp && sudo ufw delete allow 22/tcp`

**Verificación:** `ss -tlnp | grep 2222`

#### Autenticación por Clave SSH
Deshabilita passwords.

1. Genera clave local: `ssh-keygen -t ed25519 -C "tu_email"`
2. Copia a servidor: `ssh-copy-id -p 2222 usuario@ip_servidor`
3. Deshabilita password: `sudo nano /etc/ssh/sshd_config` > `PasswordAuthentication no`
4. Reinicia: `sudo systemctl restart ssh`

**Verificación:** Intenta login con password (debe fallar).

#### Deshabilitar Root Login
Previene acceso directo como root.

1. Edita: `sudo nano /etc/ssh/sshd_config` > `PermitRootLogin no`
2. Reinicia: `sudo systemctl restart ssh`

### Firewall y Monitoreo

#### Instalar Fail2Ban
Bloquea IPs con intentos fallidos.

1. Instala: `sudo apt install fail2ban`
2. Habilita: `sudo systemctl enable fail2ban`
3. Config: `sudo nano /etc/fail2ban/jail.local` (ej. `[sshd]` con `port = 2222`)

**Verificación:** `sudo fail2ban-client status sshd`

#### Actualizaciones Automáticas
Mantén sistema seguro.

1. Instala unattended-upgrades: `sudo apt install unattended-upgrades`
2. Config: `sudo dpkg-reconfigure unattended-upgrades`
3. O cron: `sudo crontab -e` > `0 2 * * * apt update && apt upgrade -y`

**Verificación:** `sudo unattended-upgrades --dry-run`

### Otras Prácticas

- **Backups:** Usa `rsync` o `borgbackup` para backups.
- **Antivirus:** Instala `clamav` para scans: `sudo apt install clamav`
- **Logs:** Monitorea con `journalctl` o `logwatch`.
- **VPN:** Usa WireGuard para acceso remoto seguro.

### Troubleshooting
- **SSH no conecta:** Verifica puerto y firewall.
- **Fail2Ban bloquea:** `sudo fail2ban-client unban <IP>`
- **Updates fallan:** `sudo apt --fix-broken install`

> **Tip:** Usa herramientas como `lynis` para auditoría: `sudo apt install lynis && sudo lynis audit system`

---

## FAQ: Preguntas Frecuentes

* **¿Qué hago si el driver NVIDIA no se instala correctamente?**
  * Revisa la compatibilidad en el Anexo B y asegúrate de haber eliminado drivers antiguos. Ejecuta `sudo apt purge nvidia*` y reinicia antes de reinstalar.

* **¿Cómo sé qué versión de CUDA instalar?**
  * Consulta la web oficial y verifica la compatibilidad con tu GPU y driver. Para series modernas (3000/4000/5000), usa CUDA 12.8 con driver >=525.x.

* **¿Por qué no funciona Wake-on-LAN?**
  * Verifica configuración de BIOS, opciones de energía y que el equipo esté conectado por cable. Ejecuta `sudo ethtool enpXsY` para checkear soporte WOL.

* **¿Puedo usar esta guía en variantes de Ubuntu?**
  * Sí, pero puede haber diferencias menores. Se recomienda Ubuntu Desktop. Para Server, omite secciones GUI.

* **¿Cómo verifico si mi GPU es compatible?**
  * Usa `lspci -nn | grep VGA` para el Device ID, luego busca en Anexo A. Confirma con `nvidia-smi` después de instalar drivers.

* **¿Qué pasa si CUDA no reconoce la GPU?**
  * Asegúrate de que drivers estén instalados correctamente (`nvidia-smi`). Reinicia si es necesario. Verifica compatibilidad en Anexo B.

* **¿Cómo instalo cuDNN después de CUDA?**
  * Descarga el .deb desde NVIDIA, instala con `sudo dpkg -i libcudnn*.deb`. Verifica con `cat /usr/include/cudnn_version.h`.

* **¿Por qué la pantalla queda negra después de instalar drivers?**
  * Agrega `nomodeset` en GRUB (sección 2). Si usas GDM3, fuerza Xorg en `/etc/gdm3/custom.conf`.

* **¿Cómo configuro red en placas nuevas?**
  * Identifica el chip con `lspci | grep Network`, instala drivers apropiados (ej. `sudo apt install r8168-dkms` para Realtek).

* **¿Puedo usar Docker con NVIDIA GPUs?**
  * Sí, instala nvidia-docker2: `sudo apt install nvidia-docker2`. Ejecuta con `--gpus all`.

* **¿Cómo libero memoria GPU para otras apps?**
  * Desactiva entorno gráfico: `sudo systemctl set-default multi-user.target && sudo reboot`. Reactiva con `graphical.target`.

* **¿Qué hago si MongoDB o Node-RED no inician?**
  * Revisa logs: `sudo journalctl -u mongod` o `sudo journalctl -u nodered`. Verifica puertos con `sudo netstat -tlnp`.

* **¿Cómo actualizo el kernel sin romper drivers?**
  * Actualiza normalmente: `sudo apt update && sudo apt upgrade`. Si hay issues, reinstala drivers después.

* **¿Es seguro usar el script post-install?**
  * Revisa el código antes de ejecutar. Hace backups y configura según la guía, pero úsalo con precaución en producción.

* **¿Dónde encuentro logs de errores?**
  * Drivers: `/var/log/nvidia-installer.log`. Sistema: `sudo journalctl -xe`. CUDA: logs en `/var/log/cuda-installer.log`.

* **¿Cómo desinstalo todo NVIDIA para reinstalar?**
  * Ejecuta `sudo apt purge nvidia* cuda* libcudnn*`, elimina `/usr/local/cuda*`, reinicia y sigue la guía desde cero.

---

## Anexo A: Identificación de GPUs NVIDIA

> **Nota:** Para identificar tu GPU, ejecuta `lspci -nn | grep VGA` (muestra Device ID en [xxxx:yyyy]). Busca el ID en las tablas abajo. Si no encuentras, usa `nvidia-smi` si drivers están instalados.

### Cómo Identificar
1. Ejecuta: `lspci -nn | grep VGA`
   - Ejemplo salida: `01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GA104 [GeForce RTX 3070] [10de:2484]`
   - Device ID: `2484` (últimos 4 dígitos).
2. Busca el ID en las tablas.
3. Si es NVIDIA, confirma con `nvidia-smi` (versión driver).

### Script Simple para Identificación
Crea `identify_gpu.sh`:
```bash
#!/bin/bash
echo "Buscando GPUs NVIDIA..."
lspci -nn | grep -i nvidia | while read line; do
  device_id=$(echo $line | grep -oP '\[10de:\K[0-9a-f]{4}')
  model=$(echo $line | sed -n 's/.*NVIDIA Corporation \([^[]*\).*/\1/p')
  echo "Modelo: $model | Device ID: $device_id"
done
```
Ejecuta: `chmod +x identify_gpu.sh && ./identify_gpu.sh`

# NVIDIA GeForce RTX Serie 3000 - Identificación PCI (Ampere)

| Serie | Modelo      | Device ID (hex) |
| ----- | ----------- | --------------- |
| 3000  | RTX 3090    | 2204            |
| 3000  | RTX 3090 Ti | 22C6            |
| 3000  | RTX 3080    | 2206            |
| 3000  | RTX 3080 Ti | 2382            |
| 3000  | RTX 3070 Ti | 24C0            |
| 3000  | RTX 3070    | 2484            |
| 3000  | RTX 3060 Ti | 2489            |
| 3000  | RTX 3060    | 2503            |
| 3000  | RTX 3050 Ti | 2191            |
| 3000  | RTX 3050    | 25A0            |

# NVIDIA GeForce RTX Serie 4000 - Identificación PCI (Ada Lovelace)

| Serie | Modelo            | Device ID (hex) |
| ----- | ----------------- | --------------- |
| 4000  | RTX 4090          | 2684            |
| 4000  | RTX 4080 Super    | 2702            |
| 4000  | RTX 4080          | 2704            |
| 4000  | RTX 4070 Ti Super | 26B0            |
| 4000  | RTX 4070 Ti       | 2782            |
| 4000  | RTX 4070 Super    | 2788            |
| 4000  | RTX 4070          | 2786            |
| 4000  | RTX 4060 Ti       | 28A3            |
| 4000  | RTX 4060          | 2882            |
| 4000  | RTX 4050          | 28A1            |

# NVIDIA GeForce RTX Serie 5000 - Identificación PCI (Blackwell)

| Serie | Modelo      | Device ID (hex) |
| ----- | ----------- | --------------- |
| 5000  | RTX 5090    | 2B80            |
| 5000  | RTX 5080    | 2B81            |
| 5000  | RTX 5070 Ti | 2B82            |
| 5000  | RTX 5070    | 2B83            |
| 5000  | RTX 5060 Ti | 2B84            |
| 5000  | RTX 5060    | 2B85            |

---

## Anexo B: Verificación de Compatibilidad

> **Nota:** Antes de instalar drivers o CUDA, verifica compatibilidad para evitar errores. Usa comandos para checkear versiones instaladas. Si hay incompatibilidades, actualiza o downgradéa según necesidad.

### Verificar Versiones Instaladas
Ejecuta estos comandos para confirmar tu setup actual:

#### Driver NVIDIA
```bash
nvidia-smi  # Muestra versión driver, CUDA runtime, GPU
# Ejemplo salida: Driver Version: 550.54.14
```

#### CUDA Toolkit
```bash
nvcc --version  # Versión del compilador CUDA
# Si no está instalado: "Command 'nvcc' not found"
```

#### cuDNN (si instalado)
```bash
cat /usr/include/cudnn_version.h | grep CUDNN_MAJOR -A 2  # Versión cuDNN
# Ejemplo: #define CUDNN_MAJOR 9
```

#### Ubuntu Kernel y GCC
```bash
uname -r  # Versión kernel (ej. 6.8.0-40-generic)
gcc --version | head -1  # Versión GCC (ej. gcc 11.4.0)
```

### Compatibilidad Recomendada (Noviembre 2025)
Basado en NVIDIA docs. Usa la versión más reciente compatible con tu GPU (series 3000/4000/5000).

#### Drivers NVIDIA y GPUs
| Serie GPU | Arquitectura | Driver Mínimo Recomendado | Driver Más Reciente |
|-----------|--------------|---------------------------|---------------------|
| RTX 3000 (Ampere) | GA10x | 470.x | 550.x |
| RTX 4000 (Ada Lovelace) | AD10x | 525.x | 550.x |
| RTX 5000 (Blackwell) | GB20x | 550.x | 560.x (beta) |

**Nota:** Drivers 550.x soportan todas las series modernas. Para RTX 5000, usa 560.x si disponible.

#### CUDA Toolkit y Drivers
| CUDA Version | Driver Mínimo | Driver Máximo | Soporte Ubuntu |
|--------------|---------------|---------------|----------------|
| 12.8 | 525.60.13 | N/A | 22.04, 24.04 |
| 12.6 | 525.60.13 | N/A | 20.04, 22.04, 24.04 |
| 12.4 | 470.42.01 | N/A | 18.04, 20.04, 22.04 |
| 12.2 | 460.32.03 | N/A | 18.04, 20.04, 22.04 |

**Nota:** CUDA 12.8 es la más reciente; requiere driver >=525.x. No instales versiones antiguas innecesariamente.

#### cuDNN y CUDA
| cuDNN Version | CUDA Compatible | Notas |
|---------------|-----------------|-------|
| 9.3.x | 12.8 | Recomendado para ML moderno |
| 9.2.x | 12.6 | Compatible con 12.8 |
| 9.1.x | 12.4 | Legacy |
| 9.0.x | 12.2 | Legacy |

**Nota:** Descarga cuDNN desde [NVIDIA cuDNN](https://developer.nvidia.com/cudnn). Instala después de CUDA.

### Cómo Verificar Compatibilidad Online
1. **Para Drivers:** Ve a [NVIDIA Drivers](https://www.nvidia.com/drivers/), selecciona tu GPU y OS.
2. **Para CUDA:** Ve a [CUDA Downloads](https://developer.nvidia.com/cuda-downloads), elige tu OS y GPU.
3. **Para cuDNN:** Consulta [cuDNN Support Matrix](https://docs.nvidia.com/deeplearning/cudnn/support-matrix/index.html).

### Troubleshooting de Compatibilidades
- **Driver demasiado viejo para CUDA:** Actualiza driver: `sudo apt update && sudo apt install nvidia-driver-550`.
- **CUDA no reconoce GPU:** Verifica con `nvidia-smi`. Si falla, reinstala drivers.
- **cuDNN error:** Confirma versiones: `cat /usr/include/cudnn.h | grep CUDNN_VERSION`.
- **Kernel mismatch:** Actualiza kernel: `sudo apt update && sudo apt upgrade`.
- **GCC incompatible:** Instala versión correcta: `sudo apt install gcc-11 g++-11`.

### Tips Generales
- **Instala en orden:** Drivers → CUDA → cuDNN → Bibliotecas (cuBLAS, etc.).
- **Prueba con samples:** Después de instalar, ejecuta CUDA samples: `cd /usr/local/cuda/samples && make && ./bin/x86_64/linux/release/deviceQuery`.
- **Si usas Docker:** Usa imágenes NVIDIA: `nvidia-docker run --rm nvidia/cuda:12.8-base-ubuntu24.04 nvidia-smi`.
- **Backup antes de cambios:** Crea snapshot o backup de drivers.

> **Recursos Adicionales:**
> * [NVIDIA CUDA Toolkit Release Notes](https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html)
> * [cuDNN Installation Guide](https://docs.nvidia.com/deeplearning/cudnn/install-guide/index.html)
> * [Ubuntu NVIDIA Drivers PPA](https://launchpad.net/~graphics-drivers/+archive/ubuntu/ppa)
