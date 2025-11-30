# Improved Guide for Setting Up Ubuntu Workstations with NVIDIA GPU

> **Last updated:** October 16, 2025

---

## Index

* [1. Pre-Installation Requirements](#1-pre-installation-requirements)
* [2. Ubuntu System Installation](#2-ubuntu-system-installation)
* [3. Initial Ubuntu System Preparation](#3-initial-ubuntu-system-preparation)
* [4. Installing NVIDIA Drivers on Ubuntu](#4-installing-nvidia-drivers-on-ubuntu)
* [5. Installing CUDA Toolkit](#5-installing-cuda-toolkit)
* [6. Specific Setup for Compression Workstations](#6-specific-setup-for-compression-workstations)
* [7. Specific Setup for Analytics Workstations](#7-specific-setup-for-analytics-workstations)
* [8. Managing the Graphical Interface](#8-managing-the-graphical-interface)
* [9. Common Network Issues with New Motherboards](#9-common-network-issues-with-new-motherboards)
* [10. Wake-on-LAN (WOL): Windows to Windows and Ubuntu to Windows](#10-wake-on-lan-wol-windows-to-windows-and-ubuntu-to-windows)
* [11. Post-Installation Script (Optional)](#11-post-installation-script-optional)
* [12. Security Best Practices (Optional)](#12-security-best-practices-optional)
* [FAQ: Frequently Asked Questions](#faq-frequently-asked-questions)
* [Annex A: Identifying NVIDIA GPUs](#annex-a-identifying-nvidia-gpus)
* [Annex B: Compatibility Verification](#annex-b-compatibility-verification)

---

> **Welcome!** This improved guide will help you install and configure Ubuntu with an NVIDIA GPU, optimizing each step and explaining the reasoning behind every action. All original commands and procedures are preserved, with added explanations, tips, and warnings for clarity.

---

## Visual Process Overview

`BIOS/UEFI` → `Ubuntu Installation` → `System Preparation` → `NVIDIA Drivers` → `CUDA Toolkit` → `Specific Configuration`

---

## 1. Pre-Installation Requirements

### What do you need before starting?

* **Bootable USB drive** Use Ventoy or BalenaEtcher to create it.
* **Ubuntu Desktop image** Download the recommended LTS version (22.04 or 24.04).
* **Purpose of the workstation** Decide if it will be used for Compression/Data or Analytics.

> **Tip:** Ubuntu Desktop is the most standard and compatible option for these setups.

---

## 2. Ubuntu System Installation

> **Note:** This guide assumes Ubuntu Desktop 24.04.1 LTS (the latest in 2025). If you use 22.04 LTS, the steps are similar, but check download links. Ensure you back up important data before proceeding, as installation will erase the disk.

### Step 1: Prepare the Bootable USB
You need a USB of at least 8GB with the Ubuntu ISO image.

1. **Download the ISO image:**
   - Go to [https://ubuntu.com/download/desktop](https://ubuntu.com/download/desktop).
   - Download Ubuntu 24.04.1 LTS (file ~4GB).
   - **Verification:** Calculate the SHA256 hash to confirm integrity:
     ```bash
     wget https://releases.ubuntu.com/24.04.1/SHA256SUMS
     sha256sum ubuntu-24.04.1-desktop-amd64.iso
     ```
     Compare with the value in SHA256SUMS.

2. **Install Ventoy (recommended for ease):**
   - Download Ventoy from [https://www.ventoy.net/](https://www.ventoy.net/).
   - Install on your current USB (it will erase data):
     ```bash
     wget https://github.com/ventoy/Ventoy/releases/download/v1.0.99/Ventoy-1.0.99-linux.tar.gz
     tar -xzf Ventoy-1.0.99-linux.tar.gz
     cd Ventoy-1.0.99
     sudo ./Ventoy2Disk.sh -i /dev/sdX  # Replace /dev/sdX with your USB (e.g., /dev/sdb). Be careful, it erases everything!
     ```
   - Copy the downloaded ISO to the USB (Ventoy will detect it automatically).

3. **Alternative: Use BalenaEtcher (if you prefer GUI):**
   - Download from [https://etcher.balena.io/](https://etcher.balena.io/).
   - Install: `sudo apt install balena-etcher-electron` (on an existing Linux system).
   - Flash the ISO to the USB.

**Verification:** Insert the USB into another PC and verify that the Ubuntu boot menu appears.

### Step 2: Access BIOS/UEFI
Restart your PC and enter the BIOS/UEFI setup by pressing the correct key during POST (initial screen). Common keys:
- F2, F8, F10, F11, F12, DEL, ESC, BACKSPACE.
- Consult your motherboard manual (search for "motherboard model BIOS setup" on Google).

**Example:** On ASUS ROG, press DEL. On MSI, F2.

### Step 3: Configure BIOS/UEFI
Once inside:
1. **Disable Secure Boot:**
   - Go to "Security" or "Boot" > "Secure Boot" > Set to "Disabled".
   - **Why:** Prevents conflicts with proprietary NVIDIA drivers.

2. **Disable TPM (if enabled):**
   - Look for "TPM" or "Trusted Platform Module" > "Disabled".
   - **Why:** May interfere with custom installations.

3. **Configure boot order:**
   - Go to "Boot" > Ensure USB is first (at the top of the list).

4. **(Optional for servers) Configure AC Power Loss:**
   - Go to "Power" > "AC Power Loss" > "Always On".
   - **Why:** Keeps the PC on after power outages.

5. **Save and exit:**
   - Press F10 (or the indicated key) to save and restart.

**Verification:** The PC should restart. If you don't enter, try again with another key.

### Step 4: Boot from USB
- Insert the prepared USB.
- Restart and select the USB in the boot menu (if not automatic).
- Choose "Try or Install Ubuntu" in the Ventoy/GRUB menu.

### Step 5: Edit Boot Parameters (Optional but Recommended)
If you have a new NVIDIA GPU, add `nomodeset` to avoid black screens.
- In the GRUB menu, press E to edit.
- Find the line starting with `linux` and add `nomodeset` at the end (after `---` if present).
- Press F10 to boot.

**Example edited line:**
```
linux /boot/vmlinuz-... nomodeset ---
```

**Why:** Disables generic graphics mode, preventing conflicts with unsupported GPUs.

### Step 6: Install Ubuntu
1. **Select language:** Choose Spanish or English (recommended for support).
2. **Configure keyboard:** Select your layout (e.g., Spanish).
3. **Connect to internet:** Recommended for updates during installation.
4. **Installation type:** Choose "Normal installation" (not minimal).
5. **Additional options:** Check "Install third-party software" and "Download updates during installation" for multimedia codecs and drivers.
6. **Partitioning:** Select "Erase disk and install Ubuntu" (erases everything; use manual partitions if dual-boot).
   - **Warning:** This erases ALL data. Confirm.
7. **Configure user:**
   - Name, username, password (use a strong one).
   - Time zone: Select automatically or manually.
8. **Finish:** Wait for completion (15-30 min). Do not remove the USB yet.

**Verification during installation:** If errors occur, note them for troubleshooting.

### Step 7: Post-Installation Initial
1. **Restart:** Remove the USB when the message appears.
2. **First boot:** Log in with your user.
3. **Basic checks:**
   - Open a terminal: `Ctrl+Alt+T`.
   - Ubuntu version: `lsb_release -a` (should show 24.04.1 LTS).
   - Internet connection: `ping -c 4 google.com`.
   - Disk space: `df -h`.

**If graphics issues:** If the screen looks bad, run `sudo apt update && sudo apt install ubuntu-drivers-common` and restart.

### Common Installation Troubleshooting
- **USB doesn't boot:** Verify Ventoy is installed correctly (`lsblk` for partitions). Try another USB or tool.
- **Black screen on boot:** Add `nomodeset` or try `acpi=off` in GRUB parameters.
- **Partitioning error:** Use GParted from live USB to prepare disks.
- **Secure Boot not disabled:** Some PCs require BIOS password; search manual.
- **Installation freezes:** Restart and disable overclock options in BIOS.
- **Dual-boot with Windows:** Use manual partitions; install Ubuntu after Windows for GRUB.

> **Note:** If you have BIOS doubts, search "motherboard model BIOS setup" on Google. For advanced support, consult Ubuntu forums.

---

## 3. Initial Ubuntu System Preparation

> **Note:** This section prepares Ubuntu for installing NVIDIA drivers and CUDA. Run commands in order. Assumes you just installed Ubuntu 24.04.1 LTS.

### Step 1: Configure GDM3 to Disable Wayland (Optional but Recommended)
Wayland may cause problems with proprietary NVIDIA drivers. Disable it to use Xorg.

```bash
sudo nano /etc/gdm3/custom.conf
```

- Find the line `#WaylandEnable=false`.
- Remove the `#` to uncomment (it will become `WaylandEnable=false`).
- Save: Ctrl+O, Enter, Ctrl+X.

**Verification:** Restart and run `echo $XDG_SESSION_TYPE` (should show `x11`, not `wayland`).

**Why:** Xorg is more compatible with NVIDIA GPUs.

### Step 2: Update the System
Update packages for security and compatibility.

```bash
sudo apt update && sudo apt upgrade -y
```

**Verification:**
- `apt list --upgradable` (should be empty if everything is updated).
- Restart: `sudo reboot`.

**Why:** Avoids conflicts with outdated versions.

### Step 3: Install Common Dependencies
Install essential tools for development, graphics, networking, and quality of life (like monitoring and troubleshooting).

```bash
sudo apt install -y build-essential dkms pkg-config libglvnd-dev libgl1-mesa-dev libegl1-mesa-dev libgles2-mesa-dev libx11-dev libxmu-dev libxi-dev libglu1-mesa-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev mesa-utils inxi net-tools openssh-server curl git wget htop ncdu tree traceroute nmap vim lm-sensors neofetch
```

**Verification:**
- `gcc --version` (should show installed version).
- `glxinfo | grep "OpenGL"` (verifies basic OpenGL).
- `traceroute google.com` (should show network route).
- `htop` (opens process monitor; press q to exit).

**Why:** These packages are necessary to compile drivers and CUDA/GPU tools. Extras improve experience: `htop` for monitoring, `traceroute` for network debugging, `vim` for editing, etc.

### Step 4: Configure Firewall for SSH (Optional)
Enable SSH and configure UFW for secure remote access (optional, if not using firewall, skip this step).

```bash
sudo ufw allow ssh
sudo ufw --force enable
```

**Verification (optional):**
- `sudo ufw status` (should show SSH allowed and status active).
- Test SSH from another device: `ssh user@your_pc_ip`.

**Why (optional):** SSH is useful for remote administration; UFW protects the system. If you don't enable it, ensure alternative security.

### Step 5: Specific Preparation by Ubuntu Version
Depending on your version, install additional dependencies.

* **For Ubuntu 22.04 LTS:**
  Install GCC/G++ 12 (necessary for CUDA in older versions).

  ```bash
  sudo apt update
  sudo apt install -y gcc-12 g++-12
  ```

  Register as alternatives:
  ```bash
  sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 120
  sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 120
  sudo update-alternatives --config gcc  # Select gcc-12 if prompted
  sudo update-alternatives --config g++
  ```

  **Verification:**
  ```bash
  gcc --version  # Should show gcc 12.x.x
  g++ --version
  ```

* **For Ubuntu 24.04 LTS:**
  Install `libtinfo5` (for compatibility with old tools).

  ```bash
  wget http://security.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2ubuntu0.1_amd64.deb
  sudo apt install ./libtinfo5_6.3-2ubuntu0.1_amd64.deb
  rm libtinfo5_6.3-2ubuntu0.1_amd64.deb
  ```

  **Verification:**
  ```bash
  dpkg -l | grep libtinfo5  # Should show installed
  ```

**Why:** Different Ubuntu versions have specific dependencies for NVIDIA/CUDA.

### Common Preparation Troubleshooting
- **Error in apt update:** Check connection: `ping -c 4 archive.ubuntu.com`. If fails, change mirrors in `/etc/apt/sources.list`.
- **GCC not installing:** Run `sudo apt --fix-broken install` if broken dependencies.
- **Wayland not disabling:** Edit `/etc/gdm3/custom.conf` manually and restart.
- **Firewall blocks connections:** `sudo ufw disable` temporarily for testing.
- **Missing packages:** `sudo apt search <package>` for exact names.

> **Warning:** Commands with `sudo` may alter the system.

---

## 4. Installing NVIDIA Drivers on Ubuntu

> **Note:** This section assumes Ubuntu 22.04 or 24.04 LTS. Ensure you have root access (sudo). If you use a different version, check compatibility in Annex B.

### Step 1: Identify Your NVIDIA GPU
Before installing, confirm the exact model of your GPU for downloading the correct driver.

```bash
lspci | grep -i nvidia
```

**Expected output example:**
```
01:00.0 VGA compatible controller: NVIDIA Corporation GA104 [GeForce RTX 3070] (rev a1)
```

- If no output, your GPU is not NVIDIA or not detected (check BIOS/UEFI).
- Note the model (e.g., RTX 3070) for the next step.

### Step 2: Check Compatibility
- Consult Annex B to confirm your GPU is compatible with recent drivers.
- Visit [https://www.nvidia.com/drivers/](https://www.nvidia.com/drivers/) and enter your model to see available drivers.
- **Recommendation:** Use drivers from the 550.x series or higher for Ubuntu 24.04 (e.g., 550.54.15 for CUDA 12.8 compatibility).

### Step 3: Remove Old Drivers (Mandatory)
If you have installed drivers previously (even from repositories), remove them to avoid conflicts.

```bash
sudo apt-get purge '^nvidia-.*' -y
sudo apt-get purge nvidia-* --autoremove -y
sudo apt-get autoremove -y
sudo reboot
```

**Verification:** After restart, run `lspci | grep -i nvidia` again. You shouldn't see loaded drivers (you can ignore the hardware line).

### Step 4: Download the Official Driver
- Go to [https://www.nvidia.com/drivers/](https://www.nvidia.com/drivers/).
- Select: Product Type: GeForce/Quadro/Tesla, Product Series: Your series (e.g., GeForce RTX 30 Series), Product: Your model, Operating System: Linux 64-bit, Language: English.
- Download the `.run` file (e.g., NVIDIA-Linux-x86_64-550.54.15.run).

**Download by terminal (example for RTX 30/40 Series on Ubuntu 24.04):**
```bash
wget https://us.download.nvidia.com/XFree86/Linux-x86_64/550.54/NVIDIA-Linux-x86_64-550.54.15.run
```

- If the link changes, search for the exact one on NVIDIA's website.
- **Verification:** List the downloaded file: `ls -la NVIDIA-Linux-x86_64-*.run`

### Step 5: Prepare Installation
Switch to text mode to avoid graphics conflicts (recommended, especially for servers).

```bash
sudo systemctl set-default multi-user.target
sudo reboot
```

After restart, log in in text mode and give execution permissions to the file:

```bash
sudo chmod +x NVIDIA-Linux-x86_64-550.54.15.run
```

**Verification:** Confirm permissions: `ls -la NVIDIA-Linux-x86_64-550.54.15.run` (should show -rwxr-xr-x).

### Step 6: Install the Driver
Run the installer with flags for compatibility and future updates.

```bash
sudo ./NVIDIA-Linux-x86_64-550.54.15.run --dkms --no-opengl-files --no-man-page --no-install-compat32-libs
```

**Responses to installer questions (press Enter for defaults, or respond as indicated):**
- `The distribution-provided pre-install script failed! Are you sure you want to continue?` → `Yes` (continue, it's common in Ubuntu).
- `Would you like to register the kernel module sources with DKMS?` → `Yes` (facilitates kernel updates).
- `Install NVIDIA's 32-bit compatibility libraries?` → `No` (unless using 32-bit apps).
- `Would you like to run nvidia-xconfig?` → `No` (we'll configure manually if necessary).
- `Would you like to enable nvidia-apply-extra-quirks?` → `Yes` (improves stability).

Installation will take a few minutes. If it fails, check logs in `/var/log/nvidia-installer.log`.

**Post-installation verification:**
```bash
nvidia-smi
```

**Expected output example:**
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

- If you see "NVIDIA-SMI has failed" or no output, the driver didn't install correctly.

### Step 7: Reactivate Graphical Environment (if you deactivated it)
If you installed in text mode, return to graphical mode:

```bash
sudo systemctl set-default graphical.target
sudo reboot
```

**Final verification:** After restart, open a terminal and run `nvidia-smi`. You should see your GPU info.

### Alternative Method: Installation from APT Repositories (Easier but Less Optimal)
If you prefer a simpler method without downloading .run, use Ubuntu repositories. This installs drivers from packages, but may be less updated than the official .run.

#### Step 1: Update and Add PPA (Optional for Newer Versions)
For more recent drivers, add the graphics-drivers PPA:
```bash
sudo add-apt-repository ppa:graphics-drivers/ppa -y
sudo apt update
```

#### Step 2: Install the Driver
List available versions:
```bash
ubuntu-drivers list
```

Install the recommended one (e.g., nvidia-driver-550):
```bash
sudo apt install -y nvidia-driver-550
```

**Verification:**
```bash
nvidia-smi
# Should show GPU info
```

#### Step 3: Restart
```bash
sudo reboot
```

**Advantages:** Easy, updatable with apt. **Disadvantages:** Versions may be older; not as optimized as official .run.

### Common NVIDIA Drivers Troubleshooting
- **Error: "The distribution-provided pre-install script failed"**: Ignore and continue; it's a non-critical warning.
- **Black screen after restart**: Restart in recovery mode (from GRUB, select "Advanced options" > recovery mode) and run `sudo apt-get purge nvidia-*` to uninstall.
- **Driver not detected**: Ensure Secure Boot is disabled in BIOS/UEFI. Run `dmesg | grep nvidia` for error logs.
- **Problems with new kernel**: If you update the kernel, run `sudo dkms autoinstall` to recompile modules.
- **If nothing works**: Try drivers from official repositories: `sudo apt install nvidia-driver-550` (but less optimal).

> **Tip:** If you have problems with the graphical environment, check section 8 on graphical interface management.

---

## 5. Installing CUDA Toolkit

> **Note:** CUDA Toolkit is essential for GPU development. Assumes NVIDIA drivers are installed (section 4). **Before installing, check the latest compatible version with your GPU and system at [https://developer.nvidia.com/cuda-downloads](https://developer.nvidia.com/cuda-downloads). The version 12.8 shown here is an example; use the most recent available for your hardware (e.g., 12.9 if released).** Consult Annex B for compatibility.

### Method 1: Installation via APT Repository (Recommended)

#### Step 1: Add NVIDIA Repository
Download and install the key for Ubuntu 24.04:

```bash
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
```

**Verification:** `apt search cuda` should show available packages.

#### Step 2: Install CUDA Toolkit
For the latest version:
```bash
sudo apt-get install -y cuda-toolkit
```

For specific version (e.g., 12.8):
```bash
sudo apt-get install -y cuda-toolkit-12-8
```

**Verification:** `nvcc --version` (should show CUDA 12.8).

#### Step 3: Configure Environment Variables
Edit `.bashrc`:
```bash
nano ~/.bashrc
```

Add at the end:
```bash
export PATH=/usr/local/cuda-12.8/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda-12.8/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
```

Save and reload:
```bash
source ~/.bashrc
```

**Verification:** `which nvcc` (should show /usr/local/cuda-12.8/bin/nvcc).

### Method 2: Manual Installation with .run File

#### Step 1: Download the Installer
Go to [https://developer.nvidia.com/cuda-downloads](https://developer.nvidia.com/cuda-downloads), select Linux/x86_64/Ubuntu/24.04/runfile.

Download:
```bash
wget https://developer.download.nvidia.com/compute/cuda/12.8.0/local_installers/cuda_12.8.0_550.54.15_linux.run
```

**Verification:** `ls -la cuda_*.run`

#### Step 2: Prepare the System
Switch to text mode:
```bash
sudo systemctl set-default multi-user.target
sudo reboot
```

Give permissions:
```bash
chmod +x cuda_12.8.0_550.54.15_linux.run
```

#### Step 3: Run the Installer
```bash
sudo sh cuda_12.8.0_550.54.15_linux.run
```

Responses:
- Accept EULA.
- DO NOT install driver (you already have one).
- Select: CUDA Toolkit (yes), Samples (optional), Documentation (optional).

#### Step 4: Configure Environment Variables
Same as Method 1.

#### Step 5: Verify and Reactivate Graphics
```bash
nvcc --version
nvidia-smi
sudo systemctl set-default graphical.target
sudo reboot
```

### Installing cuDNN (Optional - For Deep Learning)

cuDNN accelerates neural networks in CUDA. Install it after CUDA.

#### Step 1: Download cuDNN
Go to [https://developer.nvidia.com/cudnn](https://developer.nvidia.com/cudnn), download for CUDA 12.x (e.g., cuDNN 9.3 for CUDA 12.8).

For Ubuntu: Download local .deb (e.g., cudnn-local-repo-ubuntu2404-9.3.0_1.0-1_amd64.deb).

```bash
wget https://developer.download.nvidia.com/compute/cudnn/9.3.0/local_installers/cudnn-local-repo-ubuntu2404-9.3.0_1.0-1_amd64.deb
```

#### Step 2: Install cuDNN
```bash
sudo dpkg -i cudnn-local-repo-ubuntu2404-9.3.0_1.0-1_amd64.deb
sudo cp /var/cudnn-local-repo-ubuntu2404-9.3.0/cudnn-local-*-keyring.gpg /usr/share/keyrings/
sudo apt-get update
sudo apt-get install -y cudnn9-cuda-12-8
```

**Verification:**
```bash
dpkg -l | grep cudnn
# Should show cudnn9-cuda-12-8 installed
```

#### Step 3: Verify Integration with CUDA
Compile a sample:
```bash
cd /usr/local/cuda-12.8/samples/1_Utilities/deviceQuery
make
./deviceQuery
```

Should show GPU info and CUDA.

### Which Method to Choose?

| Feature | APT Repository | .run Installer |
|----------------|-----------------|-----------------|
| **Ease** | ⭐⭐⭐⭐⭐ Easy | ⭐⭐⭐ Moderate |
| **Updates** | ⭐⭐⭐⭐⭐ Automatic | ⭐⭐ Manual |
| **Control** | ⭐⭐⭐ Limited | ⭐⭐⭐⭐⭐ Total |
| **Recommended for** | General users | Developers |

> **Recommendation:** APT for simplicity. Install cuDNN after.

### CUDA/cuDNN Troubleshooting
- **nvcc not found:** Check PATH in `.bashrc`.
- **Compilation errors:** Ensure compatible GCC (see section 3).
- **cuDNN not installing:** Verify compatible version with CUDA.
- **GPU not detected:** `nvidia-smi` to check.

> **Warning:** Restart may be necessary. If conflicts, check section 4.

---

## 6. Specific Setup for Compression Workstations

> **Note:** This section installs tools for compression/data workstations, assuming Ubuntu 24.04.1 LTS with CUDA/drivers installed. Tools are optional; install only what's necessary. Check versions on official sites.

### Installing MongoDB (NoSQL Database)

#### Step 1: Add Repository
Import GPG key:
```bash
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg
```

Add repository (adjust `jammy` to `noble` if using Ubuntu 24.04):
```bash
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
```

#### Step 2: Install MongoDB
```bash
sudo apt-get update
sudo apt-get install -y mongodb-org
```

#### Step 3: Start and Enable Service
```bash
sudo systemctl start mongod
sudo systemctl enable mongod
```

**Verification:**
```bash
sudo systemctl status mongod
mongosh --eval "db.runCommand('ping')"
# Should show "ok": 1
```

### Installing MongoDB Compass (GUI for MongoDB)

#### Step 1: Download and Install
Download from [https://www.mongodb.com/try/download/compass](https://www.mongodb.com/try/download/compass):
```bash
wget https://downloads.mongodb.com/compass/mongodb-compass_1.43.4_amd64.deb
sudo apt install -y ./mongodb-compass_1.43.4_amd64.deb
```

If dependencies missing:
```bash
sudo apt --fix-broken install
```

#### Step 2: Run Compass
```bash
mongodb-compass &
```

**Verification:** Open the app and connect to `mongodb://localhost:27017`.

**Uninstallation (optional):**
```bash
sudo apt remove -y mongodb-compass
```

### Installing EMQX (MQTT Broker)

#### Step 1: Install from Repository
```bash
curl -sL https://assets.emqx.com/scripts/install-emqx-deb.sh | sudo bash
sudo apt-get install -y emqx
```

#### Step 2: Start and Enable
```bash
sudo systemctl start emqx
sudo systemctl enable emqx
```

**Verification:**
```bash
sudo systemctl status emqx
# Dashboard at http://localhost:18083 (user: admin, pass: public)
```

### Installing Golang

#### Step 1: Install with Snap
```bash
sudo snap install go --classic
```

**Verification:**
```bash
go version
# Should show installed version
```

### Installing Visual Studio Code

#### Step 1: Install with Snap
```bash
sudo snap install code --classic
```

**Verification:**
```bash
code --version
# Should show version
```

### Installing GStreamer and Plugins

#### Step 1: Install Plugins
```bash
sudo apt-get install -y gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 gstreamer1.0-qt5 gstreamer1.0-pulseaudio gstreamer1.0-rtsp
```

**Verification:**
```bash
gst-inspect-1.0 rtspclientsink
gst-inspect-1.0 nvh264enc
# Should show plugin info
```

### Installing Angry IP Scanner

#### Step 1: Download and Install
Download from [https://github.com/angryip/ipscan/releases](https://github.com/angryip/ipscan/releases):
```bash
wget https://github.com/angryip/ipscan/releases/download/3.9.1/ipscan_3.9.1_amd64.deb
sudo apt install -y ./ipscan_3.9.1_amd64.deb
```

**Verification:** Run `ipscan` from terminal or menu.

### Installing AnyDesk (Remote Support)

#### Step 1: Add Repository and Install
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

#### Step 2: Configure Firewall
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 6568/tcp
sudo ufw allow 50001:50003/udp
```

**Verification:** Run `anydesk` and note the ID.

### Installing RustDesk (Remote Support Alternative)

#### Step 1: Download and Install
Download from [https://github.com/rustdesk/rustdesk/releases](https://github.com/rustdesk/rustdesk/releases):
```bash
wget https://github.com/rustdesk/rustdesk/releases/download/1.2.3/rustdesk-1.2.3-x86_64.deb
sudo apt install -y ./rustdesk-1.2.3-x86_64.deb
```

**Verification:** Run `rustdesk` and configure ID/password.

### Configuring Ports for Compression Workstations (Optional)
If you enabled UFW in section 3, open necessary ports for apps to function correctly. If not using firewall, skip this section.

| Application | Ports | Protocol | Command to Open (Optional) |
|------------|---------|-----------|-------------------------------|
| MongoDB | 27017 | TCP | `sudo ufw allow 27017/tcp` |
| EMQX MQTT | 1883 | TCP | `sudo ufw allow 1883/tcp` |
| EMQX Dashboard | 18083 | TCP | `sudo ufw allow 18083/tcp` |
| GStreamer RTSP | 554 | TCP/UDP | `sudo ufw allow 554/tcp && sudo ufw allow 554/udp` |
| AnyDesk | 80, 443, 6568 | TCP | `sudo ufw allow 80/tcp && sudo ufw allow 443/tcp && sudo ufw allow 6568/tcp` |
| AnyDesk (UDP) | 50001-50003 | UDP | `sudo ufw allow 50001:50003/udp` |
| RustDesk | Dynamic (check logs) | TCP/UDP | Configure as needed |
| SSH (if using) | 22 (or custom) | TCP | `sudo ufw allow ssh` |

**General verification (optional):**
```bash
sudo ufw status
netstat -tlnp | grep LISTEN  # Lists open ports
```

**Tips (optional):**
- For remote access, open only necessary ports and from specific IPs: `sudo ufw allow from <IP> to any port 27017`.
- If using VPN, adjust rules.
- Check app logs for additional ports (e.g., `sudo journalctl -u emqx`).

### General Tips
- Check services: `sudo systemctl status <service>`.
- Configure unique passwords for remote access.
- Review plugins: Use `gst-inspect-1.0` for GStreamer.

### Troubleshooting
- **MongoDB not starting:** Check logs: `sudo journalctl -u mongod`.
- **EMQX failing:** Verify ports: `netstat -tlnp | grep 1883`.
- **GStreamer plugins missing:** `sudo apt install gstreamer1.0-plugins-*`.
- **AnyDesk/RustDesk not connecting:** Temporarily disable firewall for testing.

> **Additional Resources:**
> * [MongoDB Docs](https://www.mongodb.com/docs/)
> * [EMQX Docs](https://www.emqx.io/docs/)
> * [GStreamer Docs](https://gstreamer.freedesktop.org/documentation/)

---

## 7. Specific Setup for Analytics Workstations

> **Note:** This section installs tools for analytics/machine learning, assuming Ubuntu 24.04.1 LTS with CUDA installed. Install only what's necessary.

### Configuring MongoDB (Database and User)

#### Step 1: Access Console
```bash
mongosh
```

#### Step 2: Create Database and User
Replace placeholders:
```javascript
use DATABASE_NAME
db.createUser({
  user: "USERNAME",
  pwd: "PASSWORD",
  roles: [
    {
      role: "readWrite",
      db: "DATABASE_NAME"
    }
  ]
})
```

Exit with `exit`.

#### Step 3: Enable Authorization
Edit config:
```bash
sudo nano /etc/mongod.conf
```

Add under `security:`:
```yaml
security:
  authorization: enabled
```

Save and restart:
```bash
sudo systemctl restart mongod
```

**Verification:**
```bash
mongosh -u USERNAME -p PASSWORD --authenticationDatabase DATABASE_NAME
# Should connect
```

### Installing Node-RED

#### Step 1: Run Installation Script
```bash
bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered)
```

#### Step 2: Enable and Start Service
```bash
sudo systemctl enable nodered
sudo systemctl start nodered
```

**Verification:**
```bash
sudo systemctl status nodered
# Dashboard at http://localhost:1880
```

### Installing Python and Machine Learning Libraries

#### Step 1: Install Python and Pip
```bash
sudo apt install -y python3 python3-pip
```

#### Step 2: Upgrade Pip
```bash
pip3 install --upgrade pip
```

#### Step 3: Install Libraries
```bash
pip3 install pandas numpy scikit-learn paho-mqtt ultralytics
```

**Verification:**
```bash
python3 -c "import pandas, numpy, sklearn; print('Libraries OK')"
# Should print without errors
```

### Configuring Ports for Analytics Workstations (Optional)
If using firewall, open ports:

| Application | Ports | Protocol | Command |
|------------|---------|-----------|---------|
| MongoDB | 27017 | TCP | `sudo ufw allow 27017/tcp` |
| Node-RED | 1880 | TCP | `sudo ufw allow 1880/tcp` |

**Verification:**
```bash
sudo ufw status
```

### General Tips
- Use virtual environments: `python3 -m venv ml_env && source ml_env/bin/activate`.
- Upgrade libraries: `pip3 install --upgrade <lib>`.

### Troubleshooting
- **MongoDB auth failing:** Check config in `/etc/mongod.conf`.
- **Node-RED not starting:** Check logs: `sudo journalctl -u nodered`.
- **Pip installing slow:** Use mirror: `pip3 install --index-url https://pypi.org/simple <lib>`.

> **Additional Resources:**
> * [Node-RED Docs](https://nodered.org/docs/)
> * [MongoDB Docs](https://www.mongodb.com/docs/)
> * [Pandas Docs](https://pandas.pydata.org/docs/)

---

## 8. Managing the Graphical Interface

> **Note:** Ubuntu uses GDM3 as display manager. Manage graphical environment to free resources on servers or troubleshoot GPU issues.

### Check Current State
Before changing, check current target:
```bash
systemctl get-default  # Should show graphical.target or multi-user.target
who  # Shows active sessions
```

### Disable Graphical Environment (Text/Server Mode)
Useful for headless servers or troubleshooting.

#### Step 1: Disable GDM3
```bash
sudo systemctl disable gdm3
sudo systemctl set-default multi-user.target
```

#### Step 2: Restart
```bash
sudo reboot
```

**Verification:**
```bash
systemctl get-default  # multi-user.target
# You won't see graphical environment on boot
```

### Reactivate Graphical Environment
For normal desktop use.

#### Step 1: Enable GDM3
```bash
sudo systemctl enable gdm3
sudo systemctl set-default graphical.target
```

#### Step 2: Restart
```bash
sudo reboot
```

**Verification:**
```bash
systemctl get-default  # graphical.target
# You should see graphical login
```

### Alternatives and Tips
- **Change without restart:** Use `sudo systemctl isolate multi-user.target` (temporary).
- **Other DM:** If you prefer LightDM: `sudo apt install lightdm && sudo dpkg-reconfigure lightdm`.
- **GPU issues:** If black screen, force Xorg in `/etc/gdm3/custom.conf` (see section 3).

### Troubleshooting
- **GDM3 not starting:** Logs: `sudo journalctl -u gdm`.
- **Black screen:** Add `nomodeset` in GRUB (see section 2).
- **Target not changing:** `sudo systemctl daemon-reload` and retry.

> **Explanation:** Disabling frees RAM/CPU; reactivating for GUI apps. Use as needed.

---

## 9. Common Network Issues with New Motherboards

> **Note:** Network problems with new motherboards are usually due to incompatible drivers. Use `lspci | grep Network` to identify the chip. Restart after changes.

### Problems with Realtek RTL8125 (Ethernet)

#### Diagnosis
```bash
ip link show  # Look for ethX/enpXsY DOWN
lspci | grep RTL8125  # Confirm chip
```

#### Solution
1. Update system: `sudo apt update && sudo apt full-upgrade -y`
2. Add PPA: `sudo add-apt-repository ppa:kelebek333/rtl-kernel -y && sudo apt update`
3. Install driver: `sudo apt install r8125-dkms -y`
4. Block old one: `echo 'blacklist r8169' | sudo tee /etc/modprobe.d/blacklist-r8169.conf`
5. Update initramfs: `sudo update-initramfs -u`
6. Restart: `sudo reboot`

**Verification:** `ip link show` (should be UP), `lspci | grep -i ethernet`

### Problems with Intel Ethernet (e.g., I219, I225)

#### Diagnosis
```bash
lspci | grep Ethernet  # Look for Intel
dmesg | grep e1000e  # Errors?
```

#### Solution
1. Install updated driver: `sudo apt install -y backport-iwlwifi-dkms`
2. Or use PPA: `sudo add-apt-repository ppa:canonical-hwe-team/backport-iwlwifi -y && sudo apt update && sudo apt install backport-iwlwifi-dkms`
3. Restart: `sudo reboot`

**Verification:** `ip a` (IP assigned), `ping 8.8.8.8`

### Problems with Wi-Fi (Broadcom, etc.)

#### Diagnosis
```bash
iwconfig  # List Wi-Fi interfaces
lspci | grep Network  # Identify chip
```

#### Solution for Broadcom
1. Install bcmwl: `sudo apt install bcmwl-kernel-source`
2. Restart: `sudo reboot`

**Verification:** `iwconfig` (should show wlan0 UP)

### DNS Not Resolving Names

#### Diagnosis
```bash
nslookup google.com  # Failing?
cat /etc/resolv.conf  # Nameservers
```

#### Solution
1. Edit resolv.conf: `sudo nano /etc/resolv.conf`
2. Add: `nameserver 8.8.8.8` and `nameserver 1.1.1.1`
3. Or use systemd: `sudo systemctl restart systemd-resolved`

**Verification:** `nslookup google.com` (should resolve)

### Slow or Intermittent Connection

#### Diagnosis
```bash
speedtest-cli  # Speed
dmesg | grep -i network  # Errors
```

#### Solution
1. Disable IPv6: `sudo nano /etc/sysctl.conf` add `net.ipv6.conf.all.disable_ipv6=1`
2. Apply: `sudo sysctl -p`
3. Change MTU: `sudo ip link set dev enpXsY mtu 1450`

**Verification:** `speedtest-cli`, restart and test.

### Configure Static IP

#### Solution
1. Edit Netplan: `sudo nano /etc/netplan/01-netcfg.yaml`
2. Example:
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
3. Apply: `sudo netplan apply`

**Verification:** `ip a` (static IP), `ping google.com`

### Problems with VPN

#### Diagnosis
```bash
sudo systemctl status openvpn  # If using OpenVPN
journalctl -u openvpn  # Logs
```

#### Solution
1. Install OpenVPN: `sudo apt install openvpn`
2. Connect: `sudo openvpn config.ovpn`
3. For WireGuard: `sudo apt install wireguard` and configure.

**Verification:** `ip a` (tun interface), `curl ifconfig.me` (external IP changes)

### General Troubleshooting
- **Not connecting:** `sudo systemctl restart NetworkManager`
- **Missing drivers:** Search in repos: `sudo apt search <chip>`
- **Logs:** `sudo journalctl -u NetworkManager`
- **Reset:** `sudo nmcli networking off && sudo nmcli networking on`

> **Tip:** If nothing works, install drivers from manufacturer's site or use USB Ethernet.

---

## 10. Wake-on-LAN (WOL): Windows to Windows and Ubuntu to Windows

> **Note:** WOL wakes PCs by network sending a "magic packet". Requires Ethernet (not Wi-Fi). Configure BIOS and OS first.

### Configure WOL on Target PC (Windows/Ubuntu)

#### In BIOS/UEFI
1. Enter BIOS (F2/DEL).
2. Go to "Power Management" > "Wake on LAN" > "Enabled".
3. "AC Power Loss" > "Power On" (optional).
4. Save and exit.

#### In Windows
1. Run `powercfg /devicequery wake_armed` (lists devices that can wake).
2. In Device Manager > Network Adapter > Properties > Power Management > Check "Allow this device to wake the computer".
3. In Power Options > "Allow wake timers".

#### In Ubuntu
1. Install ethtool: `sudo apt install ethtool`
2. Enable WOL: `sudo ethtool -s enpXsY wol g` (replace enpXsY with interface, e.g., `ip link show`)
3. Verify: `sudo ethtool enpXsY | grep Wake-on`
4. For persistence: Create `/etc/systemd/system/wol.service` with:
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
   Enable: `sudo systemctl enable wol`

**Verification:** Turn off PC, wait 1 min, send packet from another device.

### Send WOL Packet from Windows (to Windows or Ubuntu)

#### PowerShell Script
Save as `Send-WOL.ps1` and run: `.\Send-WOL.ps1 -Mac AA:BB:CC:DD:EE:FF`

Works for waking Windows or Ubuntu PCs configured for WOL.

```powershell
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)] [string]$Mac,
  [string]$Broadcast = "255.255.255.255",
  [int]$Port = 9
)

$macClean = ($Mac -replace '[:-]','')
if ($macClean.Length -ne 12) { throw "Invalid MAC: $Mac" }

$macBytes = 0..5 | ForEach-Object { [Convert]::ToByte($macClean.Substring($_*2,2),16) }

$packet = New-Object byte[] (6 + 16*6)
for ($i=0; $i -lt 6; $i++) { $packet[$i] = 0xFF }
for ($i=0; $i -lt 16; $i++) { [Array]::Copy($macBytes, 0, $packet, 6 + $i*6, 6) }

$udp = New-Object System.Net.Sockets.UdpClient
$udp.EnableBroadcast = $true
[void]$udp.Send($packet, $packet.Length, $Broadcast, $Port)
$udp.Close()
Write-Host "WOL sent to $Mac via $Broadcast:$Port"
```

### Send WOL Packet from Ubuntu

#### Install tools
```bash
sudo apt install wakeonlan etherwake
```

#### Send packet
```bash
wakeonlan -i 192.168.1.255 AA:BB:CC:DD:EE:FF  # Your network broadcast IP
# or
sudo etherwake -i enpXsY AA:BB:CC:DD:EE:FF
```

**Verification:** Use Wireshark/tcpdump to see packet: `sudo tcpdump -i enpXsY port 9`

### Troubleshooting
- **Not waking:** Check BIOS, power settings, firewall blocking port 9.
- **Wrong MAC:** `ip link show` or `arp -a` to get it.
- **Broadcast IP:** Use `ip route | grep default` for subnet.
- **Persistence:** In Ubuntu, add to cron: `@reboot sudo ethtool -s enpXsY wol g`

> **Note:** WOL by Wi-Fi doesn't work. Use Ethernet. Test with PCs on same local network.

---

## 11. Post-Installation Script (Optional)

> **Note:** This script automates initial preparation (section 3). Update as needed. Run as root or with sudo.

### Improved `setup.sh` Script
Includes additional dependencies and options.

```bash
#!/bin/bash
# Script for initial Ubuntu system preparation
# Improved version with more tools

set -e  # Exit on error

echo "--- Updating system ---"
sudo apt update && sudo apt upgrade -y

echo "--- Installing common dependencies ---"
sudo apt install -y build-essential dkms pkg-config libglvnd-dev libgl1-mesa-dev libegl1-mesa-dev libgles2-mesa-dev libx11-dev libxmu-dev libxi-dev libglu1-mesa-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev mesa-utils inxi net-tools openssh-server curl git wget htop ncdu tree traceroute nmap vim lm-sensors neofetch

echo "--- Configuring GDM3 (disable Wayland) ---"
sudo sed -i 's/#WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf

echo "--- Configuring firewall (optional) ---"
read -p "Enable UFW with SSH? (y/n): " ufw_choice
if [[ $ufw_choice =~ ^[yY]$ ]]; then
  sudo ufw allow ssh
  sudo ufw --force enable
fi

echo "--- Verifications ---"
echo "GCC version: $(gcc --version | head -1)"
echo "Git version: $(git --version)"
echo "Firewall status: $(sudo ufw status | head -1)"

echo "--- Preparation completed. Restart recommended. ---"
read -p "Restart now? (y/n): " choice
case "$choice" in
  y|Y ) sudo reboot;;
  * ) echo "Run 'sudo reboot' manually.";;
esac
```

### How to Use It
1. Create file: `nano setup.sh`
2. Paste content and save.
3. Permissions: `chmod +x setup.sh`
4. Run: `./setup.sh` (or `sudo ./setup.sh` if needs root)

### Customization
- Add more installs: `sudo apt install -y <package>`
- Remove options: Comment lines with `#`
- Logging: Add `>> setup.log` to commands.

### Troubleshooting
- If fails: Check logs in terminal.
- Permissions: Ensure script has execution.
- Dependencies: Verify internet for apt.

---

## 12. Security Best Practices (Optional)

> **Note:** These measures strengthen Ubuntu, especially for remote access. Apply only what's necessary; more security may complicate use.

### Secure SSH

#### Change SSH Port
Reduce bot scans.

1. Edit config: `sudo nano /etc/ssh/sshd_config`
2. Change: `Port 22` to `Port 2222`
3. Restart SSH: `sudo systemctl restart ssh`
4. Firewall: `sudo ufw allow 2222/tcp && sudo ufw delete allow 22/tcp`

**Verification:** `ss -tlnp | grep 2222`

#### SSH Key Authentication
Disable passwords.

1. Generate local key: `ssh-keygen -t ed25519 -C "your_email"`
2. Copy to server: `ssh-copy-id -p 2222 user@server_ip`
3. Disable password: `sudo nano /etc/ssh/sshd_config` > `PasswordAuthentication no`
4. Restart: `sudo systemctl restart ssh`

**Verification:** Try login with password (should fail).

#### Disable Root Login
Prevent direct root access.

1. Edit: `sudo nano /etc/ssh/sshd_config` > `PermitRootLogin no`
2. Restart: `sudo systemctl restart ssh`

### Firewall and Monitoring

#### Install Fail2Ban
Block IPs with failed attempts.

1. Install: `sudo apt install fail2ban`
2. Enable: `sudo systemctl enable fail2ban`
3. Config: `sudo nano /etc/fail2ban/jail.local` (e.g., `[sshd]` with `port = 2222`)

**Verification:** `sudo fail2ban-client status sshd`

#### Automatic Updates
Keep system secure.

1. Install unattended-upgrades: `sudo apt install unattended-upgrades`
2. Config: `sudo dpkg-reconfigure unattended-upgrades`
3. Or cron: `sudo crontab -e` > `0 2 * * * apt update && apt upgrade -y`

**Verification:** `sudo unattended-upgrades --dry-run`

### Other Practices

- **Backups:** Use `rsync` or `borgbackup` for backups.
- **Antivirus:** Install `clamav` for scans: `sudo apt install clamav`
- **Logs:** Monitor with `journalctl` or `logwatch`.
- **VPN:** Use WireGuard for secure remote access.

### Troubleshooting
- **SSH not connecting:** Check port and firewall.
- **Fail2Ban blocking:** `sudo fail2ban-client unban <IP>`
- **Updates failing:** `sudo apt --fix-broken install`

> **Tip:** Use tools like `lynis` for audit: `sudo apt install lynis && sudo lynis audit system`

---

## FAQ: Frequently Asked Questions

* **What if NVIDIA driver doesn't install correctly?**
  * Check compatibility in Annex B and ensure old drivers are removed. Run `sudo apt purge nvidia*` and restart before reinstalling.

* **How do I know which CUDA version to install?**
  * Check official website and verify compatibility with your GPU and driver. For modern series (3000/4000/5000), use CUDA 12.8 with driver >=525.x.

* **Why doesn't Wake-on-LAN work?**
  * Check BIOS settings, power options, and ensure PC is connected by cable. Run `sudo ethtool enpXsY` to check WOL support.

* **Can I use this guide on Ubuntu variants?**
  * Yes, but minor differences may occur. Ubuntu Desktop is recommended. For Server, omit GUI sections.

* **How do I verify my GPU is compatible?**
  * Use `lspci -nn | grep VGA` for Device ID, then search in Annex A. Confirm with `nvidia-smi` after installing drivers.

* **What if CUDA doesn't recognize the GPU?**
  * Ensure drivers are installed correctly (`nvidia-smi`). Restart if necessary. Check compatibility in Annex B.

* **How do I install cuDNN after CUDA?**
  * Download .deb from NVIDIA, install with `sudo dpkg -i libcudnn*.deb`. Verify with `cat /usr/include/cudnn_version.h`.

* **Why does screen go black after installing drivers?**
  * Add `nomodeset` in GRUB (section 2). If using GDM3, force Xorg in `/etc/gdm3/custom.conf`.

* **How do I configure network on new motherboards?**
  * Identify chip with `lspci | grep Network`, install appropriate drivers (e.g., `sudo apt install r8168-dkms` for Realtek).

* **Can I use Docker with NVIDIA GPUs?**
  * Yes, install nvidia-docker2: `sudo apt install nvidia-docker2`. Run with `--gpus all`.

* **How do I free GPU memory for other apps?**
  * Disable graphical environment: `sudo systemctl set-default multi-user.target && sudo reboot`. Reactivate with `graphical.target`.

* **What if MongoDB or Node-RED don't start?**
  * Check logs: `sudo journalctl -u mongod` or `sudo journalctl -u nodered`. Verify ports with `sudo netstat -tlnp`.

* **How do I update kernel without breaking drivers?**
  * Update normally: `sudo apt update && sudo apt upgrade`. If issues, reinstall drivers after.

* **Is the post-install script safe?**
  * Review code before running. It makes backups and configures as per guide, but use cautiously in production.

* **Where do I find error logs?**
  * Drivers: `/var/log/nvidia-installer.log`. System: `sudo journalctl -xe`. CUDA: logs in `/var/log/cuda-installer.log`.

* **How do I uninstall everything NVIDIA to reinstall?**
  * Run `sudo apt purge nvidia* cuda* libcudnn*`, remove `/usr/local/cuda*`, restart and follow guide from start.

---

## Annex A: Identifying NVIDIA GPUs

> **Note:** To identify your GPU, run `lspci -nn | grep VGA` (shows Device ID in [xxxx:yyyy]). Search ID in tables below. If not found, use `nvidia-smi` if drivers installed.

### How to Identify
1. Run: `lspci -nn | grep VGA`
   - Example output: `01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GA104 [GeForce RTX 3070] [10de:2484]`
   - Device ID: `2484` (last 4 digits).
2. Search ID in tables.
3. If NVIDIA, confirm with `nvidia-smi` (driver version).

### Simple Identification Script
Create `identify_gpu.sh`:
```bash
#!/bin/bash
echo "Searching NVIDIA GPUs..."
lspci -nn | grep -i nvidia | while read line; do
  device_id=$(echo $line | grep -oP '\[10de:\K[0-9a-f]{4}')
  model=$(echo $line | sed -n 's/.*NVIDIA Corporation \([^[]*\).*/\1/p')
  echo "Model: $model | Device ID: $device_id"
done
```
Run: `chmod +x identify_gpu.sh && ./identify_gpu.sh`

# NVIDIA GeForce RTX Series 3000 - PCI Identification (Ampere)

| Series | Model      | Device ID (hex) |
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

# NVIDIA GeForce RTX Series 4000 - PCI Identification (Ada Lovelace)

| Series | Model            | Device ID (hex) |
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

# NVIDIA GeForce RTX Series 5000 - PCI Identification (Blackwell)

| Series | Model      | Device ID (hex) |
| ----- | ----------- | --------------- |
| 5000  | RTX 5090    | 2B80            |
| 5000  | RTX 5080    | 2B81            |
| 5000  | RTX 5070 Ti | 2B82            |
| 5000  | RTX 5070    | 2B83            |
| 5000  | RTX 5060 Ti | 2B84            |
| 5000  | RTX 5060    | 2B85            |

---

## Annex B: Compatibility Verification

> **Note:** Before installing drivers or CUDA, verify compatibility to avoid errors. Use commands to check installed versions. If incompatibilities, update or downgrade as needed.

### Check Installed Versions
Run these commands to confirm your current setup:

#### NVIDIA Driver
```bash
nvidia-smi  # Shows driver version, CUDA runtime, GPU
# Example output: Driver Version: 550.54.14
```

#### CUDA Toolkit
```bash
nvcc --version  # CUDA compiler version
# If not installed: "Command 'nvcc' not found"
```

#### cuDNN (if installed)
```bash
cat /usr/include/cudnn_version.h | grep CUDNN_MAJOR -A 2  # cuDNN version
# Example: #define CUDNN_MAJOR 9
```

#### Ubuntu Kernel and GCC
```bash
uname -r  # Kernel version (e.g., 6.8.0-40-generic)
gcc --version | head -1  # GCC version (e.g., gcc 11.4.0)
```

### Recommended Compatibility (November 2025)
Based on NVIDIA docs. Use latest compatible version with your GPU (series 3000/4000/5000).

#### NVIDIA Drivers and GPUs
| GPU Series | Architecture | Minimum Recommended Driver | Latest Driver |
|-----------|--------------|---------------------------|----------------|
| RTX 3000 (Ampere) | GA10x | 470.x | 550.x |
| RTX 4000 (Ada Lovelace) | AD10x | 525.x | 550.x |
| RTX 5000 (Blackwell) | GB20x | 550.x | 560.x (beta) |

**Note:** 550.x drivers support all modern series. For RTX 5000, use 560.x if available.

#### CUDA Toolkit and Drivers
| CUDA Version | Minimum Driver | Maximum Driver | Ubuntu Support |
|--------------|----------------|----------------|----------------|
| 12.8 | 525.60.13 | N/A | 22.04, 24.04 |
| 12.6 | 525.60.13 | N/A | 20.04, 22.04, 24.04 |
| 12.4 | 470.42.01 | N/A | 18.04, 20.04, 22.04 |
| 12.2 | 460.32.03 | N/A | 18.04, 20.04, 22.04 |

**Note:** CUDA 12.8 is latest; requires driver >=525.x. Do not install old versions unnecessarily.

#### cuDNN and CUDA
| cuDNN Version | Compatible CUDA | Notes |
|---------------|-----------------|-------|
| 9.3.x | 12.8 | Recommended for modern ML |
| 9.2.x | 12.6 | Compatible with 12.8 |
| 9.1.x | 12.4 | Legacy |
| 9.0.x | 12.2 | Legacy |

**Note:** Download cuDNN from [NVIDIA cuDNN](https://developer.nvidia.com/cudnn). Install after CUDA.

### How to Verify Compatibility Online
1. **For Drivers:** Go to [NVIDIA Drivers](https://www.nvidia.com/drivers/), select GPU and OS.
2. **For CUDA:** Go to [CUDA Downloads](https://developer.nvidia.com/cuda-downloads), choose OS and GPU.
3. **For cuDNN:** Consult [cuDNN Support Matrix](https://docs.nvidia.com/deeplearning/cudnn/support-matrix/index.html).

### Compatibility Troubleshooting
- **Driver too old for CUDA:** Update driver: `sudo apt update && sudo apt install nvidia-driver-550`.
- **CUDA doesn't recognize GPU:** Verify with `nvidia-smi`. If fails, reinstall drivers.
- **cuDNN error:** Confirm versions: `cat /usr/include/cudnn.h | grep CUDNN_VERSION`.
- **Kernel mismatch:** Update kernel: `sudo apt update && sudo apt upgrade`.
- **GCC incompatible:** Install correct version: `sudo apt install gcc-11 g++-11`.

### General Tips
- **Install in order:** Drivers → CUDA → cuDNN → Libraries (cuBLAS, etc.).
- **Test with samples:** After installing, run CUDA samples: `cd /usr/local/cuda/samples && make && ./bin/x86_64/linux/release/deviceQuery`.
- **If using Docker:** Use NVIDIA images: `nvidia-docker run --rm nvidia/cuda:12.8-base-ubuntu24.04 nvidia-smi`.
- **Backup before changes:** Create snapshot or backup of drivers.

> **Additional Resources:**
> * [NVIDIA CUDA Toolkit Release Notes](https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html)
> * [cuDNN Installation Guide](https://docs.nvidia.com/deeplearning/cudnn/install-guide/index.html)
> * [Ubuntu NVIDIA Drivers PPA](https://launchpad.net/~graphics-drivers/+archive/ubuntu/ppa)

### Key steps and recommendations

1. **Access the BIOS/UEFI** (common keys: F2, F8, F11, F12, DEL, BACKSPACE).

1. **Configure the BIOS/UEFI:**

* Disable Secure Boot and TPM.
* (Optional) Set AC Power Loss to Always On for servers.

1. **Save and reboot** (usually F10).

1. **Boot from USB** and select the Ubuntu image.

1. **Edit boot parameters:**

* Add `nomodeset` after `---` to avoid graphics conflicts.
* Explanation: This prevents issues with new GPUs not supported by generic drivers.

1. **Install Ubuntu:**

* Choose language, keyboard layout, normal installation, and check third-party and multimedia options.
* Set up user and timezone.
* **Warning:** "Erase disk and install Ubuntu" will delete all data on the selected disk.

1. **Reboot and remove the USB.**

> **Note:** If unsure about any BIOS option, consult your motherboard manual.

---

## 3. Initial Ubuntu System Preparation

* **GDM3 Configuration (Optional but Recommended for Graphical Installation):** If you plan to use the graphical interface, it's recommended to disable Wayland to avoid issues with proprietary drivers.

  Edit the configuration file:
  ```bash
  sudo nano /etc/gdm3/custom.conf
  ```
  Find the line `#WaylandEnable=false` and **remove the `#`** to uncomment it. It should read:
  ```
  WaylandEnable=false
  ```
  Save (Ctrl+O, Enter) and close (Ctrl+X).

### Before installing drivers, prepare the system

* **Update the system**

  ```bash
  sudo apt update && sudo apt upgrade -y
  ```

* **Reboot to apply updates**

  ```bash
  sudo reboot
  ```

* **Install common dependencies**

  ```bash
  sudo apt install -y build-essential dkms pkg-config libglvnd-dev libgl1-mesa-dev libegl1-mesa-dev libgles2-mesa-dev libx11-dev libxmu-dev libxi-dev libglu1-mesa-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev mesa-utils inxi net-tools openssh-server curl git wget
  ```

* **Configure GDM3 (optional):** Disable Wayland to avoid issues with proprietary GPU drivers.

* **Configure the firewall for SSH**

  ```bash
  sudo ufw allow ssh
  sudo ufw --force enable
  ```

* **Version-specific preparation**
  * **Ubuntu 22.04:** Install and configure GCC/G++ 12.
  
  GCC/G++ 12 (Ubuntu 22.04)
  - Install the compilers:
    ```bash
    sudo apt update
    sudo apt install -y gcc-12 g++-12
    ```
  - Register GCC/G++ 12 as alternatives and set them as default:
    ```bash
    # Register alternatives (priority 120)
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 120
    sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 120

    # Manual selection in case multiple versions are installed
    sudo update-alternatives --config gcc
    sudo update-alternatives --config g++
    ```
  - Verify:
    ```bash
    gcc --version
    g++ --version
    ```
  - (Optional) Ensure cc/c++ point to gcc/g++:
    ```bash
    sudo update-alternatives --install /usr/bin/cc cc /usr/bin/gcc 120
    sudo update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++ 120
    ```
  * **Ubuntu 24.04:** Install the `libtinfo5` dependency (needed for some older drivers/tools). You can download the package directly from the official repository:

    [Download libtinfo5 for Ubuntu 24.04 (noble)](http://security.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2ubuntu0.1_amd64.deb)

    ```bash
    wget http://security.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2ubuntu0.1_amd64.deb
    sudo apt install ./libtinfo5_6.3-2ubuntu0.1_amd64.deb
    rm libtinfo5_6.3-2ubuntu0.1_amd64.deb # Clean up the downloaded file
    ```

> **Warning:** Check driver and CUDA compatibility before installing. Commands with `sudo` can alter the system.

---

## 4. Installing NVIDIA Drivers on Ubuntu

* **Preparation for Installation:**
  Make sure the graphical environment (GDM) is not running or switch to text mode:
  ```bash
  sudo systemctl set-default multi-user.target
  sudo reboot
  ```
  Give execution permissions to the `.run` file:
  ```bash
  sudo chmod +x NVIDIA-Linux-x86_64-XXX.XX.run # Replace XXX.XX with the downloaded version number
  ```
* **Driver Installation:**
  Run the installer with `sudo` and the `--dkms` flag to facilitate kernel updates:
  ```bash
  sudo ./NVIDIA-Linux-x86_64-XXX.XX.run --dkms
  ```
  The installer will ask questions:
  - `The distribution-provided pre-install script failed! Are you sure you want to continue?` -> `Continue Installation`
  - `Would you like to register the kernel module sou...` -> `Yes` (if you used `--dkms`)
  - `Install NVIDIA's 32-bit compatibility libraries?` -> `Yes`
  - `Would you like to run nvidia-xconfig?` -> `No` (unless you have a specific X11 configuration)
  - `Would you like to enable nvidia-apply-extra-quirks?` -> `Yes` (if available)

### How to properly install the drivers?

* **Identify your GPU**

  ```bash
  lspci | grep -i nvidia
  ```

* **Check compatibility** Refer to the GPU table and Annex B.

* **Remove old drivers**

  ```bash
  sudo apt-get purge '^nvidia-.*'
  sudo apt-get purge nvidia-* --autoremove -y
  sudo apt-get autoremove -y
  sudo reboot
  ```

* **Download the official driver** from NVIDIA's website:

  [Official NVIDIA Drivers Page](https://www.nvidia.com/drivers/)

  Select your GPU, operating system, and version. Download the `.run` file manually from the web, or copy the direct link and download it via terminal with `wget`:

  ```bash
  wget https://us.download.nvidia.com/XFree86/Linux-x86_64/XXX.XX/NVIDIA-Linux-x86_64-XXX.XX.run
  # Replace XXX.XX with the version corresponding to your GPU and system
  ```

* **Prepare for installation**
  * Switch to text mode if needed.
  * Make the `.run` file executable.

* **Install the driver**
  * Use the `--dkms` flag for easier kernel updates.
  * Answer the installer questions as recommended.

* **Verify the installation**

  ```bash
  nvidia-smi
  ```
  * If you see your GPU information, everything is correct!

> **Tip:** If you have issues with the graphical environment, check the graphical interface management section.

---

## 5. Installing CUDA Toolkit

### Install CUDA safely and compatibly

> **Important:** Check compatibility in Annex B before installing. Make sure your GPU and NVIDIA driver are compatible with the desired CUDA version.

There are two main methods to install CUDA Toolkit: via APT repository (recommended for ease of updates) or manual installation with the `.run` file (greater control).

---

#### **Method 1: Installation via APT Repository (Recommended)**

This method facilitates updates and package management.

1. **Download and install the repository key:**

   For Ubuntu 24.04:
   ```bash
   wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
   sudo dpkg -i cuda-keyring_1.1-1_all.deb
   sudo apt-get update
   ```

   For Ubuntu 22.04:
   ```bash
   wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
   sudo dpkg -i cuda-keyring_1.1-1_all.deb
   sudo apt-get update
   ```

2. **Install CUDA Toolkit:**

   To install the latest available version:
   ```bash
   sudo apt-get install -y cuda-toolkit
   ```

   To install a specific version (example: CUDA 12.8):
   ```bash
   sudo apt-get install -y cuda-toolkit-12-8
   ```

3. **Configure environment variables:**

   Edit your `.bashrc` file:
   ```bash
   nano ~/.bashrc
   ```

   Add these lines at the end (adjust the version according to what was installed):
   ```bash
   export PATH=/usr/local/cuda-12.8/bin${PATH:+:${PATH}}
   export LD_LIBRARY_PATH=/usr/local/cuda-12.8/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
   ```

   Save (Ctrl+O, Enter) and close (Ctrl+X).

   Reload the `.bashrc` file:
   ```bash
   source ~/.bashrc
   ```

4. **Verify the installation:**

   ```bash
   nvcc --version
   ```

   You should see information about the installed CUDA version.

---

#### **Method 2: Manual Installation with .run file**

This method offers greater control over which components to install.

1. **Download the installer from the official website:**

   Visit [https://developer.nvidia.com/cuda-downloads](https://developer.nvidia.com/cuda-downloads) and select:
   - Operating System: Linux
   - Architecture: x86_64
   - Distribution: Ubuntu
   - Version: 22.04 or 24.04
   - Installer Type: **runfile (local)**

   Download with `wget` (example for CUDA 12.8):
   ```bash
   wget https://developer.download.nvidia.com/compute/cuda/12.8.0/local_installers/cuda_12.8.0_550.54.15_linux.run
   ```

2. **Prepare the system:**

   Switch to text mode (optional but recommended):
   ```bash
   sudo systemctl set-default multi-user.target
   sudo reboot
   ```

   Give execution permissions:
   ```bash
   chmod +x cuda_12.8.0_550.54.15_linux.run
   ```

3. **Run the installer:**

   ```bash
   sudo sh cuda_12.8.0_550.54.15_linux.run
   ```

   **During installation:**
   - Accept the EULA (End User License Agreement)
   - **DO NOT install the driver if you already have one installed** (uncheck that option)
   - Select the components you want to install:
     - CUDA Toolkit (mandatory)
     - CUDA Samples (optional)
     - CUDA Documentation (optional)

4. **Configure environment variables:**

   Edit your `.bashrc` file:
   ```bash
   nano ~/.bashrc
   ```

   Add these lines at the end:
   ```bash
   export PATH=/usr/local/cuda-12.8/bin${PATH:+:${PATH}}
   export LD_LIBRARY_PATH=/usr/local/cuda-12.8/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
   ```

   Save (Ctrl+O, Enter) and close (Ctrl+X).

   Reload the `.bashrc` file:
   ```bash
   source ~/.bashrc
   ```

5. **Verify the installation:**

   ```bash
   nvcc --version
   nvidia-smi
   ```

6. **Reactivate the graphical environment (if you disabled it):**

   ```bash
   sudo systemctl set-default graphical.target
   sudo reboot
   ```

---

### Which method to choose?

| Feature | APT Repository | .run Installer |
|---------|----------------|----------------|
| **Ease of installation** | ⭐⭐⭐⭐⭐ Very easy | ⭐⭐⭐ Moderate |
| **Updates** | ⭐⭐⭐⭐⭐ Automatic with `apt` | ⭐⭐ Manual |
| **Component control** | ⭐⭐⭐ Limited | ⭐⭐⭐⭐⭐ Complete |
| **Multiple versions** | ⭐⭐⭐ Possible but complex | ⭐⭐⭐⭐⭐ Easy |
| **Recommended for** | General users | Advanced developers |

> **Recommendation:** For most users, the APT repository method is more convenient and facilitates system maintenance.

> **Warning:** Installing CUDA may require rebooting the system. If you encounter conflicts with drivers, review section 4 on NVIDIA drivers.

> **Note:** For Ubuntu 24.04, CUDA 12.8 or higher is recommended. Always check compatibility in Annex B.

---

## 6. Specific Setup for Compression Workstations

* **MongoDB Installation:**
  Import the official GPG key:
  ```bash
  curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg
  ```
  Add the MongoDB repository (adjust `jammy` to `noble` if using Ubuntu 24.04):
  ```bash
  echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
  ```
  Update and install MongoDB:
  ```bash
  sudo apt-get update
  sudo apt-get install -y mongodb-org
  ```
  Start and enable the service:
  ```bash
  sudo systemctl start mongod
  sudo systemctl enable mongod
  ```
  (Optional) Check the status:
  ```bash
  sudo systemctl status mongod
  ```


MongoDB Compass (GUI) – .deb method (primary)
- Download the .deb installer from the official page:
  https://www.mongodb.com/try/download/compass
- If you have the direct link to a specific version, you can download with wget (replace <VERSION>):
  ```bash
  wget https://downloads.mongodb.com/compass/mongodb-compass_<VERSION>_amd64.deb
  # Example (hypothetical):
  # wget https://downloads.mongodb.com/compass/mongodb-compass_1.43.4_amd64.deb
  ```
- Install the package:
  ```bash
  sudo apt install -y ./mongodb-compass_<VERSION>_amd64.deb
  ```
- If missing dependencies appear:
  ```bash
  sudo apt --fix-broken install
  ```
  Then retry installing the .deb if necessary.
- Run Compass:
  ```bash
  mongodb-compass &
  ```
- Quick verification:
  - Open Compass and check that the connection screen appears.
  - Connect to your local instance if you installed MongoDB server:
    - URI: mongodb://localhost:27017
- Uninstall (optional):
  ```bash
  sudo apt remove -y mongodb-compass
  ```

### Recommended tools for compression/data

Below are the installations of additional tools for compression/data workstations.

* **EMQX Installation:**
  
  Add the repository and install:
  ```bash
  curl -sL https://assets.emqx.com/scripts/install-emqx-deb.sh | sudo bash
  sudo apt-get install emqx
  ```
  
  Start and enable the service:
  ```bash
  sudo systemctl start emqx
  sudo systemctl enable emqx
  ```
  
  (Optional) Check the status:
  ```bash
  sudo systemctl status emqx
  ```

* **Golang Installation (Snap):**
  
  ```bash
  sudo snap install go --classic
  ```

* **Visual Studio Code Installation (Snap):**
  
  ```bash
  sudo snap install code --classic
  ```

* **GStreamer and Plugins Installation:**
  
  Install the necessary plugins:
  ```bash
  sudo apt-get install -y gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 gstreamer1.0-qt5 gstreamer1.0-pulseaudio gstreamer1.0-rtsp
  ```
  
  Verify the installation of specific plugins:
  ```bash
  gst-inspect-1.0 rtspclientsink
  gst-inspect-1.0 nvh264enc
  ```

* **Angry IP Scanner Installation:**
  
  Download the `.deb` package from [Angry IP Scanner Releases](https://github.com/angryip/ipscan/releases) and install it:
  ```bash
  sudo apt install ./ipscan_<version>_amd64.deb
  # Replace <version> with the downloaded file
  ```

* **Anydesk Installation for remote support:**
  
  Add the official repository and install:
  ```bash
  sudo apt update
  sudo apt install ca-certificates curl apt-transport-https
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://keys.anydesk.com/repos/DEB-GPG-KEY -o /etc/apt/keyrings/keys.anydesk.com.asc
  sudo chmod a+r /etc/apt/keyrings/keys.anydesk.com.asc
  echo "deb [signed-by=/etc/apt/keyrings/keys.anydesk.com.asc] https://deb.anydesk.com all main" | sudo tee /etc/apt/sources.list.d/anydesk-stable.list > /dev/null
  sudo apt update
  sudo apt install anydesk
  ```
  
  Enable the required ports in the UFW firewall:
  ```bash
  # Recommended rules for AnyDesk:
  # TCP 80, 443, and 6568 are used for signaling/connection
  # UDP 50001-50003 is used for Discovery and connection optimization on LAN
  sudo ufw allow 80/tcp
  sudo ufw allow 443/tcp
  sudo ufw allow 6568/tcp
  sudo ufw allow 50001:50003/udp
  ```
  
  > **Important:** Take note of the Anydesk ID and set a unique password.

* **Rustdesk Installation for remote support:**
  
  Download the `.deb` package from [Rustdesk Releases](https://github.com/rustdesk/rustdesk/releases) (x86-64 version for Ubuntu) and install it:
  ```bash
  sudo apt install ./<package.deb>
  # Replace <package.deb> with the downloaded file name
  ```
  
  > **Important:** Take note of the Rustdesk ID, set a unique password, and check the box that allows direct IP connection.

* **Tips:**
  * Check service status after installation.
  * Set unique passwords for remote access.
  * Verify specific plugin installation with `gst-inspect-1.0`.

> **Additional Resources:**
> * [Official MongoDB Documentation](https://www.mongodb.com/docs/)
> * [Official EMQX Documentation](https://www.emqx.io/docs/)
> * [Official GStreamer Documentation](https://gstreamer.freedesktop.org/documentation/)

---

## 7. Specific Setup for Analytics Workstations

* **MongoDB Configuration (Database and User Creation):**
  Access the MongoDB console:
  ```bash
  mongosh
  ```
  Create the database and a user with read/write permissions (replace `DB_NAME`, `USER`, `PASSWORD` with your actual values):
  ```javascript
  use DB_NAME
  db.createUser({
    user: "USER",
    pwd: "PASSWORD",
    roles: [
      {
        role: "readWrite",
        db: "DB_NAME"
      }
    ]
  })
  ```
  Edit the MongoDB configuration to enable authorization:
  ```bash
  sudo nano /etc/mongod.conf
  ```
  Uncomment the `security:` section and add below (indenting 2 spaces):
  ```yaml
  security:
    authorization: enabled
  ```
  Save (Ctrl+O, Enter) and close (Ctrl+X).
  Restart the service to apply changes:
  ```bash
  sudo systemctl restart mongod
  ```

* **Node-RED Installation:**
  Run the installation script:
  ```bash
  bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered)
  ```
  (Optional) Enable the service manually if the script didn't do it:
  ```bash
  sudo systemctl enable nodered
  sudo systemctl start nodered
  ```
  (Optional) Check the status:
  ```bash
  sudo systemctl status nodered
  ```

### Recommended tools for analytics/machine learning

Below are the installations of additional tools for analytics workstations.

* **Python and Pip Installation:**
  
  ```bash
  sudo apt install -y python3 python3-pip
  ```

* **Python Libraries Installation for Machine Learning:**
  
  Update pip:
  ```bash
  pip3 install --upgrade pip
  ```
  
  Install the necessary libraries:
  ```bash
  pip3 install pandas numpy scikit-learn paho-mqtt ultralytics
  ```
  
  > **Note:** You can add more libraries according to your needs (matplotlib, tensorflow, pytorch, opencv-python, etc.).

> **Additional Resources:**
> * [Official Node-RED Documentation](https://nodered.org/docs/)
> * [MongoDB Documentation](https://www.mongodb.com/docs/)
> * [Pandas Documentation](https://pandas.pydata.org/docs/)
> * [Scikit-learn Documentation](https://scikit-learn.org/stable/)

> **Tip:** Update pip regularly and consider using virtual environments for specific projects.

---

## 8. Graphical Interface Management

To switch between login screen environments for graphical mode and console mode:

```bash
sudo dpkg-reconfigure gdm3
```

* Select **gdm3** for graphical environment (default).
* Select **lightdm** or other display manager if you prefer a different login screen.

### Stopping Graphical Mode (temporarily)

If you need to work in console mode (without the graphical environment, saves resources), run:

```bash
sudo systemctl stop gdm3
```

To start it again:

```bash
sudo systemctl start gdm3
```

### Disabling Graphical Mode at Startup (permanent change)

To set the system to boot in console mode (multi-user text mode):

```bash
sudo systemctl set-default multi-user.target
```

To re-enable graphical mode at startup:

```bash
sudo systemctl set-default graphical.target
```

> **Note:** If working in console mode, you can manually start the graphical interface with:
> ```bash
> startx
> ```
> Or switch to a graphical session using `Ctrl+Alt+F7` (or another function key like F1-F6 to return to console).

---

## 9. Network Issues with Realtek RTL8125 Controller

If you experience **network connectivity or stability issues** with the Realtek RTL8125 2.5G Ethernet controller (common on some motherboards like MSI B550), here's how to **update to the latest driver**:

### Step-by-Step Solution

1. **Download the latest driver:**
   
   Go to the official Realtek page or use this direct link to download the latest driver package for Linux:
   
   [Realtek RTL8125 Driver (Official)](https://www.realtek.com/Download/Index?type=network-ethernet)

   Alternatively, you can download the `r8125-9.013.02.tar.bz2` version directly (or the latest available).

2. **Extract the compressed file:**
   
   ```bash
   tar -xvjf r8125-9.013.02.tar.bz2
   ```

3. **Navigate to the extracted directory:**
   
   ```bash
   cd r8125-9.013.02
   ```

4. **Install necessary dependencies (if not already installed):**
   
   ```bash
   sudo apt install -y build-essential dkms linux-headers-$(uname -r)
   ```

5. **Compile and install the driver:**
   
   Within the extracted folder, run:
   ```bash
   sudo ./autorun.sh
   ```

6. **Reboot the system:**
   
   ```bash
   sudo reboot
   ```

7. **Verify the driver is loaded correctly:**
   
   After rebooting, check the driver version:
   ```bash
   ethtool -i enp6s0 | grep driver
   ethtool -i enp6s0 | grep version
   ```
   
   Replace `enp6s0` with your network interface name (check with `ip link` or `ifconfig`).

### Additional Considerations

* **DKMS (Dynamic Kernel Module Support):** If you want the driver to automatically rebuild when the kernel updates, copy the driver to the DKMS directory before running `autorun.sh`:
  ```bash
  sudo cp -r r8125-9.013.02 /usr/src/
  sudo dkms add -m r8125 -v 9.013.02
  sudo dkms build -m r8125 -v 9.013.02
  sudo dkms install -m r8125 -v 9.013.02
  ```

* **Common network interface names:**
  - `enp6s0`, `enp7s0`, `eno1`, `eth0`, etc.
  - Use `ip link show` to list all network interfaces.

> **Note:** This procedure is especially useful if the default driver included with Ubuntu (`r8169`) doesn't work correctly with the RTL8125 2.5G controller.

> **Additional Resources:**
> * [Official Realtek Downloads](https://www.realtek.com/Download/Index?type=network-ethernet)
> * [Ubuntu Forums - Network Issues](https://ubuntuforums.org/)

---

## 10. Wake-on-LAN Configuration

**Wake-on-LAN (WoL)** allows you to remotely power on a computer via the network. This is useful for remote management, scheduled maintenance, and resource optimization.

### Requirements

1. **BIOS/UEFI Support:**
   - Enable the **Wake-on-LAN** option in the BIOS/UEFI.
   - Common settings: **"Wake on PCIe"**, **"Wake on LAN"**, or **"Power On By PCI-E Device"**.

2. **Network Adapter Support:**
   - The network adapter must support Wake-on-LAN (most modern adapters do).

3. **Power Supply:**
   - The computer must remain connected to power (PSU).

### Linux Configuration (Target Computer)

1. **Install `ethtool`:**
   
   ```bash
   sudo apt install -y ethtool
   ```

2. **Check if Wake-on-LAN is enabled:**
   
   ```bash
   sudo ethtool enp6s0 | grep Wake-on
   ```
   
   Replace `enp6s0` with your network interface name (use `ip link` to list interfaces).
   
   * If `Wake-on: d`, it means **disabled**.
   * If `Wake-on: g`, it means **enabled** (magic packet).

3. **Enable Wake-on-LAN:**
   
   ```bash
   sudo ethtool -s enp6s0 wol g
   ```

4. **Make Wake-on-LAN persistent after reboot:**
   
   Create a systemd service to enable WoL on boot:
   
   ```bash
   sudo nano /etc/systemd/system/wol.service
   ```
   
   Paste the following content (replace `enp6s0` with your interface):
   
   ```ini
   [Unit]
   Description=Enable Wake-on-LAN for enp6s0
   After=network.target
   
   [Service]
   Type=oneshot
   ExecStart=/usr/sbin/ethtool -s enp6s0 wol g
   
   [Install]
   WantedBy=multi-user.target
   ```
   
   Save (Ctrl+O, Enter) and close (Ctrl+X).
   
   Enable and start the service:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable wol.service
   sudo systemctl start wol.service
   ```

5. **Get the MAC Address:**
   
   Note the MAC address of the network interface:
   ```bash
   ip link show enp6s0
   ```
   
   Example output: `link/ether 00:11:22:33:44:55`

### Sending Wake-on-LAN from Windows

You can send a magic packet from a Windows computer on the same network to wake up the Linux machine.

<details>
<summary><strong>Click here to view the PowerShell script</strong></summary>

Save the following script as `WakeOnLAN.ps1`:

```powershell
# WakeOnLAN.ps1
# Sends a magic packet to wake up a computer via Wake-on-LAN

param(
    [Parameter(Mandatory=$true)]
    [string]$MacAddress
)

# Remove separators (colons, dashes, dots) from the MAC address
$MacClean = $MacAddress -replace '[:-\.]', ''

# Validate that the MAC address has 12 hexadecimal characters
if ($MacClean.Length -ne 12 -or $MacClean -notmatch '^[0-9A-Fa-f]{12}$') {
    Write-Host "Error: Invalid MAC address. Use format XX:XX:XX:XX:XX:XX, XX-XX-XX-XX-XX-XX, or XXXXXXXXXXXX" -ForegroundColor Red
    exit 1
}

# Convert the MAC address to an array of bytes
$MacBytes = [byte[]]@()
for ($i = 0; $i -lt 12; $i += 2) {
    $MacBytes += [convert]::ToByte($MacClean.Substring($i, 2), 16)
}

# Build the magic packet: 6 bytes of 0xFF + 16 repetitions of the MAC address
$MagicPacket = [byte[]](,0xFF * 6) + ($MacBytes * 16)

# Create a UDP client and send the packet to the broadcast address on port 9
$UdpClient = New-Object System.Net.Sockets.UdpClient
try {
    $UdpClient.Connect("255.255.255.255", 9)
    $BytesSent = $UdpClient.Send($MagicPacket, $MagicPacket.Length)
    
    Write-Host "Magic packet sent successfully to MAC: $MacAddress ($BytesSent bytes)" -ForegroundColor Green
} catch {
    Write-Host "Error sending magic packet: $_" -ForegroundColor Red
} finally {
    $UdpClient.Close()
}
```

**Usage:**

```powershell
.\WakeOnLAN.ps1 -MacAddress "00:11:22:33:44:55"
```

Replace `00:11:22:33:44:55` with the MAC address of the target computer.

</details>

### Sending Wake-on-LAN from Linux

Use the `wakeonlan` tool (or alternatives like `etherwake`):

```bash
sudo apt install -y wakeonlan
wakeonlan 00:11:22:33:44:55
```

Replace `00:11:22:33:44:55` with the target MAC address.

### Troubleshooting

1. **Check BIOS/UEFI:** Ensure Wake-on-LAN is enabled.
2. **Check router/switch:** Some routers block broadcast packets; ensure they allow WoL magic packets.
3. **Verify Wake-on-LAN status:**
   ```bash
   sudo ethtool enp6s0 | grep Wake-on
   ```
   Should show `Wake-on: g`.
4. **Firewall:** Ensure UDP port 9 is not blocked.

> **Additional Resources:**
> * [Wake-on-LAN Wikipedia](https://en.wikipedia.org/wiki/Wake-on-LAN)
> * [Ubuntu WoL Guide](https://help.ubuntu.com/community/WakeOnLan)

> **Tip:** For remote WoL over the internet, configure port forwarding on your router (UDP port 9) and use a dynamic DNS service.

---

## 11. Post-Installation Bash Script (Optional)

For those who prefer to automate many of the steps described in this guide, below is a **Bash script** that:

- Updates and upgrades the system.
- Installs basic utilities (curl, wget, git, vim, net-tools, htop).
- Adds the graphics-drivers PPA repository and installs the NVIDIA driver (version 565 in this example).
- Installs CUDA 12.8 via the APT repository method.
- Installs MongoDB 8.0.
- Installs EMQX.
- Installs Golang (via Snap).
- Installs Visual Studio Code (via Snap).
- Installs GStreamer plugins.
- Installs Node-RED.
- Installs Python3, pip, and basic libraries for analytics.

> **Important:** This script is **illustrative** and should be reviewed before running. Adjust package versions, drivers, and configurations according to your specific needs.

```bash
#!/bin/bash
# post-installation.sh
# Post-installation script for Ubuntu 22.04/24.04 with NVIDIA drivers and CUDA.

set -e  # Exit on any error

echo "========================================="
echo " Ubuntu Post-Installation Script"
echo " NVIDIA + CUDA + Development Tools"
echo "========================================="

# 1. System Update
echo "[1/12] Updating the system..."
sudo apt update && sudo apt upgrade -y

# 2. Basic Utilities
echo "[2/12] Installing basic utilities..."
sudo apt install -y curl wget git vim net-tools htop build-essential

# 3. GCC/G++ 12 (for Ubuntu 24.04)
if lsb_release -r | grep -q "24.04"; then
  echo "[3/12] Installing GCC/G++ 12 for Ubuntu 24.04..."
  sudo apt install -y gcc-12 g++-12
  sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 100
  sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 100
else
  echo "[3/12] Skipping GCC/G++ 12 (not Ubuntu 24.04)."
fi

# 4. Reconfigure GDM3 and install libtinfo5 (for Ubuntu 24.04)
echo "[4/12] Configuring GDM3 and installing libtinfo5..."
sudo dpkg-reconfigure gdm3
if lsb_release -r | grep -q "24.04"; then
  sudo apt install -y libtinfo5
fi

# 5. NVIDIA Driver Installation
echo "[5/12] Adding graphics-drivers PPA and installing NVIDIA driver..."
sudo add-apt-repository -y ppa:graphics-drivers/ppa
sudo apt update
sudo apt install -y nvidia-driver-565

# 6. CUDA Toolkit Installation (APT Method)
echo "[6/12] Installing CUDA Toolkit 12.8..."
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt update
sudo apt install -y cuda-toolkit-12-8

# Add CUDA to PATH
if ! grep -q "/usr/local/cuda-12.8/bin" ~/.bashrc; then
  echo 'export PATH=/usr/local/cuda-12.8/bin:$PATH' >> ~/.bashrc
  echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.8/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
fi

# 7. MongoDB Installation
echo "[7/12] Installing MongoDB 8.0..."
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl enable mongod
sudo systemctl start mongod

# 8. EMQX Installation
echo "[8/12] Installing EMQX..."
curl -s https://assets.emqx.com/scripts/install-emqx-deb.sh | sudo bash
sudo apt install -y emqx
sudo systemctl enable emqx
sudo systemctl start emqx

# 9. Golang Installation (Snap)
echo "[9/12] Installing Golang..."
sudo snap install go --classic

# 10. Visual Studio Code Installation (Snap)
echo "[10/12] Installing Visual Studio Code..."
sudo snap install code --classic

# 11. GStreamer Installation
echo "[11/12] Installing GStreamer plugins..."
sudo apt install -y gstreamer1.0-tools gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav

# 12. Node-RED Installation
echo "[12/12] Installing Node-RED..."
bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered)
sudo systemctl enable nodered
sudo systemctl start nodered

# 13. Python and Libraries
echo "[13/13] Installing Python3, pip, and analytics libraries..."
sudo apt install -y python3 python3-pip
pip3 install --upgrade pip
pip3 install pandas numpy scikit-learn paho-mqtt ultralytics

echo "========================================="
echo " Installation Complete!"
echo " Reboot the system to apply all changes:"
echo " sudo reboot"
echo "========================================="
```

**Usage:**

1. Save the script as `post-installation.sh`:
   ```bash
   nano post-installation.sh
   ```
   Paste the content above, save (Ctrl+O, Enter), and close (Ctrl+X).

2. Make it executable:
   ```bash
   chmod +x post-installation.sh
   ```

3. Run the script:
   ```bash
   ./post-installation.sh
   ```

4. Reboot after completion:
   ```bash
   sudo reboot
   ```

> **Note:** This script is a **starting point**. Review each section and adjust versions, configurations, and tools according to your specific requirements. Some installations may require manual interaction (e.g., GDM3 reconfiguration, NVIDIA installer questions).

> **Tip:** For a fully automated installation, consider using configuration management tools like Ansible, Puppet, or Chef.

---

## 12. Security Best Practices

When setting up a workstation with NVIDIA drivers, CUDA, and development tools, it's essential to follow security best practices:

### 1. Keep the System Updated

Regularly update the system and packages:

```bash
sudo apt update && sudo apt upgrade -y
```

Enable automatic security updates:

```bash
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure unattended-upgrades
```

### 2. Configure a Firewall

Install and enable UFW (Uncomplicated Firewall):

```bash
sudo apt install -y ufw
sudo ufw enable
```

Allow only necessary services (example for SSH):

```bash
sudo ufw allow ssh
sudo ufw status
```

### 3. Secure SSH Access

If you use SSH to remotely access your workstation:

* Change the default SSH port (edit `/etc/ssh/sshd_config`):
  ```bash
  sudo nano /etc/ssh/sshd_config
  ```
  Change `#Port 22` to `Port 2222` (or another port), save, and restart SSH:
  ```bash
  sudo systemctl restart ssh
  ```

* Disable root login via SSH:
  ```bash
  sudo nano /etc/ssh/sshd_config
  ```
  Set `PermitRootLogin no`, save, and restart SSH.

* Use SSH keys instead of passwords:
  ```bash
  ssh-keygen -t ed25519 -C "your_email@example.com"
  ssh-copy-id user@remote_host
  ```

### 4. Create Strong Passwords

Use strong, unique passwords for all user accounts. Consider using a password manager.

### 5. Enable Automatic Backups

Set up automatic backups for critical data using tools like `rsync`, `timeshift`, or cloud services.

### 6. Monitor System Logs

Regularly check system logs for suspicious activity:

```bash
sudo journalctl -xe
sudo tail -f /var/log/syslog
```

### 7. Limit User Privileges

Grant sudo access only to trusted users. Avoid using the root account for daily tasks.

### 8. Install and Configure Fail2Ban

Protect against brute-force attacks:

```bash
sudo apt install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

Configure `/etc/fail2ban/jail.local` to customize ban rules for SSH and other services.

### 9. Use AppArmor or SELinux

AppArmor is enabled by default on Ubuntu and provides mandatory access control. Verify it's active:

```bash
sudo aa-status
```

### 10. Disable Unnecessary Services

Review and disable services that are not needed:

```bash
sudo systemctl list-unit-files --type=service
sudo systemctl disable <service_name>
```

> **Additional Resources:**
> * [Ubuntu Security Guide](https://ubuntu.com/security)
> * [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
> * [OWASP Top Ten](https://owasp.org/www-project-top-ten/)

> **Tip:** Regularly review security practices and stay informed about emerging threats and vulnerabilities.

---

## FAQ: Frequently Asked Questions

* **What if the NVIDIA driver doesn't install correctly?**
  * Check compatibility in Annex B and make sure old drivers are removed.

* **How do I know which CUDA version to install?**
  * Check the official website and verify compatibility with your GPU and driver.

* **Why doesn't Wake-on-LAN work?**
  * Check BIOS settings, power options, and ensure the PC is connected via cable.

* **Can I use this guide for Ubuntu variants?**
  * Yes, but there may be minor differences. Ubuntu Desktop is recommended.

---

## Annex A: Identifying NVIDIA GPUs

### How to identify your NVIDIA GPU?

To identify your NVIDIA GPU generation and model, run:

```bash
lspci | grep VGA
```

Then compare the hexadecimal Device ID with the following tables:

#### Series 3000 (Ampere)

| Series | Model      | Device ID (hex) |
| ------ | ---------- | --------------- |
| 3000   | RTX 3090   | 2204            |
| 3000   | RTX 3090 Ti| 22C6            |
| 3000   | RTX 3080   | 2206            |
| 3000   | RTX 3080 Ti| 2382            |
| 3000   | RTX 3070 Ti| 24C0            |
| 3000   | RTX 3070   | 2484            |
| 3000   | RTX 3060 Ti| 2489            |
| 3000   | RTX 3060   | 2503            |
| 3000   | RTX 3050 Ti| 2191            |
| 3000   | RTX 3050   | 25A0            |

#### Series 4000 (Ada Lovelace)

| Series | Model            | Device ID (hex) |
| ------ | ---------------- | --------------- |
| 4000   | RTX 4090         | 2684            |
| 4000   | RTX 4080 Super   | 2702            |
| 4000   | RTX 4080         | 2704            |
| 4000   | RTX 4070 Ti Super| 26B0            |
| 4000   | RTX 4070 Ti      | 2782            |
| 4000   | RTX 4070 Super   | 2788            |
| 4000   | RTX 4070         | 2786            |
| 4000   | RTX 4060 Ti      | 28A3            |
| 4000   | RTX 4060         | 2882            |
| 4000   | RTX 4050         | 28A1            |

#### Series 5000 (Blackwell)

| Series | Model      | Device ID (hex) |
| ------ | ---------- | --------------- |
| 5000   | RTX 5090   | 2B80            |
| 5000   | RTX 5080   | 2B81            |
| 5000   | RTX 5070 Ti| 2B82            |
| 5000   | RTX 5070   | 2B83            |
| 5000   | RTX 5060 Ti| 2B84            |
| 5000   | RTX 5060   | 2B85            |

---

## Annex B: Compatibility Verification

### How to verify compatibility between GPU, driver, and CUDA?

1. **GPU and NVIDIA Driver:**
   * Visit [https://www.nvidia.com/drivers/](https://www.nvidia.com/drivers/).
   * Select your GPU and operating system to see compatible drivers.

2. **NVIDIA Driver and CUDA Toolkit:**
   * Visit [https://developer.nvidia.com/cuda-downloads](https://developer.nvidia.com/cuda-downloads).
   * Look for the "CUDA Compatibility" or "CUDA Requirements" section.
   * Example: CUDA 12.8 requires NVIDIA driver >= 525.x.
   * Check your driver version with:

   ```bash
   nvidia-smi
   ```

   The version must be equal to or greater than the minimum required by CUDA.

3. **CUDA Toolkit and Ubuntu:**
   * The CUDA download page lists supported Ubuntu versions for each CUDA Toolkit version.

---
