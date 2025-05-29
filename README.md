# Guia Ubuntu+NVIDIA
***Hecho por Joaquin Osorio Valenzuela***
---
## 1.- Requisitos previos a la instalación

* Se debe tener una unidad flash booteable (Se puede utilizar Ventoy o BalenaEtcher)
* Se debe descargar previamente la versión de Ubuntu que se desea utilizar:
  - Esta puede ser Ubuntu (22.04 LTS o 24.04 LTS).
  - Puede ser cualquiera de sus variantes (Mantener versionado):
    - Kubuntu
    - Xubuntu
    - Ubuntu Cinnamon
    - Lubuntu
  - También funciona con Linux Mint (21.x equivale a Ubuntu 22 y 22.x equivale a Ubuntu 24)
* Se debe tener claro qué propósito cumplirá el equipo, normalmente se utilizan para Compresión/Data o Analítica. Ya que más adelante se hacen instalaciones específicas dependiendo del uso del equipo
---

## 2.- Instalación del sistema Ubuntu

1. Para lograr tener una instalación limpia, lo primero que debemos hacer es entrar a la BIOS del equipo y configurar ciertos parámetros:
   1. Para acceder a la BIOS en caso de que el equipo sea completamente nuevo es sencillo ya que lo hará directamente.
   2. En el caso de que se vaya a reutilizar un equipo, se debe reiniciar el equipo y presionar una de las siguientes teclas:
      - BACKSPACE
      - DEL/SUPR
      - F2
      - F8
      - F11
      - F12
2. Una vez dentro de la BIOS, debemos cambiar los siguientes parámetros:
   - AC Power Loss: Always Off -> Always On
   - Secure Boot: Enabled -> Disabled
   - TPM: Enabled -> Disabled
3. Ahora, navegamos al apartado de 'Save & Exit', guardamos los cambios y reiniciamos.
4. Cuando se esté reiniciando el equipo, conectamos la unidad flash al equipo y al momento de bootear, debería aparecer el inicio de Ventoy.
5. Elegimos la versión de Ubuntu que queremos instalar navegando con las flechas del teclado para luego presionar la tecla 'Enter'.
6. Luego seleccionamos 'Boot in normal mode' y volvemos a presionar la tecla 'Enter'.
7. Se abrirá el menú de inicio de GRUB, nos aparecerán varias opciones de las cuales debemos seleccionar 'Try or Install Ubuntu', pero en vez de presionar 'Enter' presionamos la tecla 'E'. Se abrirá un editor de texto con varios parámetros, con las flechas navegamos hasta la línea que aparecen 3 guiones seguidos '---', nos corremos 1 espacio y escribimos 'nomodeset' y luego presionamos Ctrl+X para cerrar el editor de texto. La pantalla se congelará un instante mientras guarda la nueva configuración de arranque y luego debería bootear con Ubuntu y también aparecerá el asistente de instalación del sistema.
8. Ahora que estamos dentro de Ubuntu, seguimos el paso a paso considerando lo siguiente:
   - Idioma del sistema: Español
   - Opciones de accesibilidad: Siguiente
   - Idioma del teclado: Español Latinoamericano
   - Seleccionamos instalación interactiva
   - Selección ampliada
   - Marcamos las opciones de 'Instalar software de terceros para gráficos y dispositivos de Wifi', como también 'Descargar e instalar compatibilidad para más formatos multimedia'
   - En el apartado de disco, elegimos 'Borrar disco e Instalar Ubuntu'
9. Una vez hecha esta configuración inicial, viene el apartado de las credenciales del equipo, aquí se hace una diferencia dependiendo si el equipo será de Compresión o de Analítica:
    - Es importante que desmarquemos la opción de 'Solicitar mi contraseña para acceder' y seguimos con el proceso de instalación.
10. Para finalizar la instalación de Ubuntu, seleccionamos el uso horario de Santiago y en la pestaña siguiente chequeamos que estén todos los datos correctos y presionamos 'Instalar'.
11. Dejamos que se instale todo correctamente, cuando finalice la instalación aparecerá una ventana pidiéndonos reiniciar el equipo, por lo que presionamos el botón de Reiniciar que aparece en la ventana y dejamos que el equipo se reinicie para que aplique la instalación.
12. Cuando esté reiniciando en pantalla nos arrojará un mensaje de sacar la unidad flash con la que booteamos inicialmente y luego presionamos la tecla 'Enter'. Con esto damos por finalizada la instalación del sistema operativo Ubuntu.
---

## 3.- Instalaciones y configuraciones necesarias para Ubuntu

1. Lo primero que debemos hacer es actualizar las librerías y dependencias que actualmente tiene el sistema, por lo que ocuparemos la siguiente línea de código por terminal:

```bash
sudo apt update && sudo apt upgrade
```
2. Cuando el sistema recopile todas las actualizaciones se nos pedirá confirmar escribiendo una 'Y' y luego presionando la tecla 'Enter'.
3. Una vez finalizada la descarga e instalación de las actualizaciones, debemos reiniciar el sistema por lo que utilizamos:

```bash
sudo reboot
```
4. Cuando nos encontremos de vuelta en el sistema, es momento de instalar las dependencias necesarias para instalar los drivers de NVIDIA:
```bash
sudo apt install -y g++ freeglut3-dev build-essential libx11-dev libxmu-dev libxi-dev libglu1-mesa libglu1-mesa-dev pkg-config libglvnd-dev libgl1-mesa-dev libegl1-mesa-dev dkms mesa-utils inxi libgl1-mesa-glx libgl1-mesa-dri libglx-mesa0 xserver-xorg-core net-tools openssh-server ffmpeg
```
5. Confirmamos la instalación con 'Y' y presionando la tecla 'Enter'.
6. Una vez finalizada la instalación de estas librerías y dependencias, debemos cambiar la configuración de arranque de visualización de la siguiente manera:
   1. Lo que tenemos que hacer es modificar por terminal el contenido del archivo utilizando el siguiente código por terminal:
   ```bash
   sudo nano /etc/gdm3/custom.conf
   ```
   2. Estando dentro del documento, debemos descomentar la línea borrando el símbolo '#' que se antepone a la línea que menciona al 'Wayland'.
   3. Presionamos Ctrl+O (Letra 'o') y luego la tecla 'Enter' para guardar los cambios realizados en el archivo, finalmente Ctrl+X para cerrar el archivo.
7. Es necesario también otorgarle los permisos necesarios a SSH para poder acceder sin problemas ocupando el siguiente código por terminal:
```bash
sudo ufw allow ssh
```
8. Ahora debemos hacer una instalación que varía según nuestra versión de Ubuntu:
   - Versión 22.04 LTS:
      1. Debemos instalar estos compiladores por medio de la siguiente línea en terminal:
      ```bash
        sudo apt install gcc-12 g++-12
      ```   
      2. Luego debemos actualizar el sistema para que considere estas alternativas para la instalación de los drivers gráficos de NVIDIA por medio de la siguiente línea de código por terminal:
        ```bash
         sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 20
         sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 20
        ```
      3. Corroboramos con la siguiente línea de código por terminal:
      ```bash
        gcc --version
        g++ --version
      ```
      4. Si se muestra 'gcc 12.x' y 'g++ 12.x' el procedimiento fue realizado correctamente y podemos continuar.
   - Versión 24.04 LTS:
      1. Debemos instalar una dependencia necesaria que no viene por defecto en esta versión de Ubuntu.
      2. Lo primero que debemos hacer es añadir el repositorio al listado de dependencias del sistema, verifiquemos que todo esté al día:
      ```bash
      sudo apt update
      ```
      3. Luego descargamos el paquete por medio del siguiente comando:
      ```bash
      wget http://security.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2ubuntu0.1_amd64.deb
      ```
      4. Instalamos el paquete:
      ```bash
      sudo apt install ./libtinfo5_6.3-2ubuntu0.1_amd64.deb
      ```
      5. Confirmamos la instalación presionando en la terminal 'Y' y luego presionamos la tecla 'Enter'.
      6. Una vez finalizada la instalación, podemos continuar.   
9. Una vez realizados todos estos cambios toca reiniciar el sistema para que se apliquen los cambios por lo que nuevamente utilizamos lo siguiente por terminal:
```bash
sudo reboot
```
---

## 4.- Instalación de Drivers de NVIDIA en Ubuntu

1. Para empezar la instalación de los drivers gráficos de NVIDIA primero debemos tener presente qué tarjeta estamos trabajando. Normalmente para Compresión/Data se utilizan gráficas de la serie 4000 y para Analítica se están utilizando de la serie 5000. (Esto puede variar de las condiciones de stock del momento del armado)
2. Podemos identificar las gráficas con el siguiente código por terminal:
```bash
DISPLAY=:0 glxinfo | grep "OpenGL renderer"
```
3. Esto nos va a mostrar la versión de la gráfica, teniendo esto presente debemos dirigirnos a la página de NVIDIA para descargar los drivers:
[https://www.nvidia.com/es-la/drivers/](https://www.nvidia.com/es-la/drivers/)
4. Ahora para la descarga de los drivers tenemos dos opciones:
   1. Si tenemos interfaz gráfica, elegimos los datos correspondientes a nuestra gráfica y nuestro sistema operativo (Linux 64 bits)
      1. Damos click en 'Siguiente'
      2. Damos click en 'Descargar'
      3. Revisamos que esté en la carpeta y podemos proseguir
   2. Si no tenemos interfaz gráfica, tendremos que conectarnos por ssh hacia el PC y luego copiar el link desde un equipo que sí tenga interfaz gráfica para utilizar la herramienta wget y descargar los drivers desde la terminal
      1. Copiamos el enlace del botón 'Descargar'
      2. Nos dirigimos a la terminal
      3. Escribimos 'wget' y luego pegamos el link
      ```bash
      wget https://us.download.nvidia.com/XFree86/Linux-x86_64/570.153.02/NVIDIA-Linux-x86_64-570.153.02.run
      ```
      > 💡 Nota 
      > El link que se encuentra arriba puede no estar actualizado, es solo un ejemplo.
5. Antes de instalar los nuevos drivers de NVIDIA, debemos eliminar cualquier librería, dependencia o instalación previa de NVIDIA con el siguiente código por terminal:
```bash
sudo apt-get remove --purge '^nvidia-.*'
```
6. Esperamos a que se descargue el script de bash para luego darle permisos de ejecución con el siguiente comando por terminal:
```bash
sudo chmod +x NVIDIA-Linux-x86_64-570.153.02.run
```
7. Si se ejecutó todo correctamente en el apartado 4 de este manual, se debería poder ejecutar el script de los drivers de NVIDIA sin problemas con la siguiente línea por terminal:
> 💡 Nota  
> Cuando estamos instalando por terminal, debemos navegar con las flechas del teclado.
```bash
sudo ./NVIDIA-Linux-x86_64-570.153.02.run --dkms
```
> 💡 Nota  
> No olvidar añadir el subfijo '--dkms' al final de la línea de instalación de los drivers para evitar problemas con posibles actualizaciones de kernel    
   1. Una vez ejecutemos el script, comenzará la instalación de los drivers de NVIDIA.
   2. Como primera opción aparecerá el tipo de drivers de NVIDIA que queremos instalar:
       - En caso de que la tarjeta sea generación 4000, se debe instalar los drivers de tipo 'NVIDIA Propietary'
       - En caso de que la tarjeta sea generación 5000, se deben instalar los drivers de tipo 'MIT/GPL'
   3. Desde aquí nos aparecerán varias ventanas haciendo ciertas comprobaciones, donde a todo le daremos ok.
   4. Una vez finalizada la instalación es necesario hacer un:
   ```bash
   sudo reboot
   ```
   5. Cuando se haya reiniciado el sistema, entramos a la terminal y utilizamos el siguiente comando para verificar que se haya instalado correctamente:
   ```bash
   nvidia-smi
   ```
   6. Si se muestran los datos de la tarjeta gráfica y la versión de los drivers, ¡felicidades! Los drivers fueron instalados correctamente. En caso de que muestre que hubo un error llamando a los gráficos de NVIDIA, es necesario repetir el proceso de instalación.
   7. Una vez estén instalados los drivers correctamente, seguimos con el siguiente apartado.
---

## 5.- Instalación CUDA Toolkit

1. Lo primero que debemos hacer es descargar el paquete .deb para instalar el CUDA Toolkit.
2. Abrimos la terminal y corremos la siguiente serie de comandos, a medida que vayan finalizando, ejecutamos el siguiente:
   - Ubuntu 22.04: 
   ```bash
   wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin

   sudo mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600

   wget https://developer.download.nvidia.com/compute/cuda/12.8.0/local_installers/cuda-repo-ubuntu2204-12-8-local_12.8.0-570.86.10-1_amd64.deb

   sudo dpkg -i cuda-repo-ubuntu2204-12-8-local_12.8.0-570.86.10-1_amd64.deb

   sudo cp /var/cuda-repo-ubuntu2204-12-8-local/cuda-*-keyring.gpg /usr/share/keyrings/

   sudo apt-get update

   sudo apt-get -y install cuda-toolkit-12-8
   ```
   - Ubuntu 24.04:
   ```bash
   wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-ubuntu2404.pin

   sudo mv cuda-ubuntu2404.pin /etc/apt/preferences.d/cuda-repository-pin-600

   wget https://developer.download.nvidia.com/compute/cuda/12.8.0/local_installers/cuda-repo-ubuntu2404-12-8-local_12.8.0-570.86.10-1_amd64.deb

   sudo dpkg -i cuda-repo-ubuntu2404-12-8-local_12.8.0-570.86.10-1_amd64.deb

   sudo cp /var/cuda-repo-ubuntu2404-12-8-local/cuda-*-keyring.gpg /usr/share/keyrings/

   sudo apt-get update

   sudo apt-get -y install cuda-toolkit-12-8
   ```
3. Esta instalación tardará unos minutos (5-10 min. aprox), cuando finalice debemos configurar las variables de entorno relacionadas al CUDA Toolkit.
4. Para configurar las variables de entorno que involucran al CUDA Toolkit, ejecutamos el siguiente comando por terminal:
```bash
sudo nano ~/.bashrc
```
1. Con esto podremos modificar el contenido del perfil de bash, el cual contiene las variables de entorno del sistema.
2. Como estamos editando con nano, navegamos con las flechas del teclado hasta el final del documento.
3. Una vez nos encontremos al final debemos escribir manualmente o copiar y pegar (siempre que la terminal nos lo permita) la siguiente información dentro del documento:
```bash
# CUDA Toolkit configuration
export PATH=${PATH}:/usr/local/cuda-12.8/bin
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/cuda-12.8/lib64
```
> 💡 Nota  
> Los valores de las variables de entorno, difieren dependiendo de la version de CUDA Toolkit que se requiera instalar, normalmente se utiliza la 12.8.
1. Una vez esto esté escrito dentro del archivo .bashrc, debemos presionar Ctrl+O y 'Enter' para almacenar los cambios y luego Ctrl+X para salir del editor de texto.
2. Por último, debemos ocupar el siguiente comando para actualizar el estado del archivo y que se apliquen los cambios:
```bash
source ~/.bashrc
```
1.  Nos queda verificar que esté linkeado correctamente, lo podemos hacer corriendo el siguiente comando por terminal:
```bash
nvcc --version
```
1.  Si el procedimiento se hizo correctamente, debería mostrar la versión de CUDA que instaló y podremos continuar. De no ser así, repetir el proceso.
---

## 6.- Instalaciones necesarias para PC de compresión
- Debemos tener en cuenta los componentes necesarios para los PC de compresión los cuales son:
  - terminator
  - nvtop
  - MongoDB
  - MongoDB Compass
  - Golang (snap)
  - Visual Studio Code (snap)
  - ffmpeg
  - gstreamer
- También debemos instalar todas las dependencias necesarias de gstreamer.
1. terminator:
```bash
sudo apt install terminator
```
2. nvtop:
```bash
sudo apt install nvtop
```
3. MongoDB:
   1. Lo primero es importar la llave pública del repositorio:
   ```bash
   curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg \
   --dearmor
   ```
   2. Creamos la lista de archivos para nuestra versión de Ubuntu:
      - Ubuntu 22.04 LTS
      ```bash
      echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
      ```
      - Ubuntu 24.04 LTS
      ```bash
      echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
      ```
   3. Actualizamos los paquetes de la base de datos:
   ```bash
   sudo apt-get update
   ```
   4. Instalamos la versión LTS de MongoDB:
   ```bash
   sudo apt-get install -y mongodb-org
   ```
   5. Ahora debemos configurar Mongo, lo primero que debemos hacer es iniciar el servicio:
   ```bash
   sudo systemctl start mongod
   ```
   6. Continuamos con la revisión del estado actual del servicio, debería mostrar 'Active':
   ```bash
   sudo systemctl status mongod
   ```
   7. Y nos aseguramos de que el servicio arranque cada vez que el PC encienda:
   ```bash
   sudo systemctl enable mongod
   ```
   > 💡 Nota  
   > Para detener el servicio de Mongo se puede utilizar `sudo systemctl stop mongod` y para reiniciar el servicio se puede utilizar `sudo systemctl restart mongod`
4. MongoDB Compass:
   1. Descargamos el instalador de MongoDB Compass:
   ```bash
   wget https://downloads.mongodb.com/compass/mongodb-compass_1.45.4_amd64.deb
   ```
   2. Ejecutamos el instalador:
   ```bash
   sudo apt install ./mongodb-compass_1.45.4_amd64.deb
   ```
   3. Iniciamos MongoDB Compass:
   ```bash
   mongodb-compass
   ```
5. Golang:
   - Para instalar golang solo necesitamos utilizar la tienda de snap con el siguiente comando por terminal:
   ```bash
   sudo snap install go --classic
   ```
6. Visual Studio Code:
   - Para instalar VSC solo necesitamos utilizar la tienda de snap con el siguiente comando por terminal:
   ```bash
   sudo snap install code --classic
   ```
7. ffmpeg:
```bash
sudo apt install ffmpeg
```
8. gstreamer:
   1. Lo primero sería instalar todas las dependencias necesarias relacionadas a gstreamer:
   ```bash
   sudo apt-get install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgstreamer-plugins-bad1.0-dev gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 gstreamer1.0-qt5 gstreamer1.0-pulseaudio gstreamer1.0-rtsp
   ```
   2. Una vez teniendo gstreamer instalado, corroboramos la instalación con los siguientes comandos:
   ```bash
   gst-inspect-1.0 rtspclientsink
   ```
   3. Se debería mostrar por pantalla los parámetros, salimos con Ctrl+C y luego ejecutamos el siguiente comando por terminal:
   ```bash
   gst-inspect-1.0 nvh264enc
   ```
   4. Proceder igual que en el paso 3. En caso de que ambos comandos muestren los parámetros por pantalla, gstreamer fue instalado correctamente. En caso contrario, será necesario desinstalar gstreamer y todas sus dependencias para luego hacer una reinstalación limpia:
   ```bash
   sudo apt-get remove --purge 'gstreamer*'
   sudo apt-get autoremove
   ```
**Habiendo llegado hasta aquí, el acondicionamiento del equipo para Compresión está finalizado.**
---

## 7.- Instalaciones necesarias para PC de analítica

- Debemos tener en cuenta los componentes necesarios para los PC de analítica, los cuales son:
  - MongoDB
  - NodeRED
  - pip3
    - pandas
    - numpy
    - scikit-learn
    - paho-mqtt
    - ultralytics
1. MongoDB:
   1. Lo primero es importar la llave pública del repositorio:
   ```bash
   curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg \
   --dearmor
   ```
   2. Creamos la lista de archivos para nuestra versión de Ubuntu:
      - Ubuntu 22.04 LTS
      ```bash
      echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
      ```
      - Ubuntu 24.04 LTS
      ```bash
      echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
      ```
   3. Actualizamos los paquetes de la base de datos:
   ```bash
   sudo apt-get update
   ```
   4. Instalamos la versión LTS de MongoDB:
   ```bash
   sudo apt-get install -y mongodb-org
   ```
   5. Ahora debemos configurar Mongo, lo primero que debemos hacer es iniciar el servicio:
   ```bash
   sudo systemctl start mongod
   ```
   6. Continuamos con la revisión del estado actual del servicio, debería mostrar 'Active':
   ```bash
   sudo systemctl status mongod
   ```
   7. Y nos aseguramos de que el servicio arranque cada vez que el PC encienda:
   ```bash
   sudo systemctl enable mongod
   ```
   8. Ahora debemos crear la base de datos y el usuario con sus credenciales respectivas:
      1. Accedemos a la consola de MongoDB con el siguiente comando:
      ```bash
      mongosh
      ```
      2. Una vez dentro de la consola de MongoDB, copiamos y pegamos el siguiente comando:
      ```JavaScript
      use FISHFLOW
      db.createUser({
       user: "analitic",
       pwd: "PASSWORD",
       roles: [
        {
         role: "readWrite",
         db: "FISHFLOW"
        }
       ]
      })
      ```
      3. Ahora que hemos creado la base de datos y un usuario para la misma, tenemos que realizar una última configuración utilizando el siguiente comando por terminal:
      ```bash
      sudo nano /etc/mongod.conf
      ```
      4. Y en el apartado de '# network interfaces' modificamos 'bindIp', debemos cambiar el valor por:
      ```txt
      0.0.0.0
      ```
      5. Luego descomentamos 'security', bajamos una línea y presionamos 2 veces la tecla 'Espacio' para escribir:
      ```txt
      authorization: enabled
      ```
      6. Guardamos los cambios con Ctrl+O, presionamos la tecla 'Enter' y finalmente cerramos el editor de texto con Ctrl+X.
      7. Reiniciamos el servicio para aplicar los cambios:
      ```bash
      sudo systemctl restart mongod
      ```
2. NodeRED:
   1. Vamos a realizar la instalación por medio de un comando de tipo bash:
   ```bash
   bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered)
   ```
   2. Seguimos el paso a paso de las configuraciones donde:
      - Usuario: workstation
      - Contraseña: <contraseña>
   3. Si se requiere que NodeRED inicie automáticamente:
   ```bash
   sudo systemctl enable nodered.service
   ```
3. pip3:
   1. Lo primero relacionado a pip3 sería instalarlo por medio de apt:
   ```bash
   sudo apt install python3-pip
   ```
   2. Se recomienda actualizar pip antes de instalar los paquetes:
   ```bash
   pip3 install --upgrade pip
   ```
   3. Luego de instalar pip3, debemos instalar todas las librerías y dependencias necesarias para poder trabajar los modelos de inferencia de Ultralytics:
   ```bash
   pip3 install pandas numpy scikit-learn paho-mqtt ultralytics
   ```
   4. Esta descarga e instalación de paquetes es pesada, por lo que puede tardar varios minutos.
**Habiendo llegado hasta aquí, el acondicionamiento del equipo para Analítica está finalizado.**
---

## 8.- Interfaz gráfica como servidor

- Desactivar interfaz gráfica:
```bash
sudo systemctl disable gdm3
sudo systemctl set-default multi-user.target
sudo reboot
```
- Reactivar interfaz gráfica:
```bash
sudo systemctl enable gdm3
sudo systemctl set-default graphical.target
sudo reboot
sudo systemctl start gdm3
```
  
