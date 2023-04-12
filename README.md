# KPTV

This repository is to have a customised Raspberry Pi OS image that includes Kiwiplan Web Launcher. 

## Initial setup

### Check if sbin path is configured. If not, pi-gen will complain a few dependencies that are already installed

```bash
# Run as a root
echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games" >> /etc/environment
```

### Make sure en_US.UTF-8 is selected

```bash
sudo dpkg-reconfigure locales
```

### Make sure en_US.UTF-8 is configured as we use en_US.UTF-8 for pi-gen

The actual locale configured in Raspberry Pi OS image will be set by Raspberry Pi Image. So, this is just to avoid any build issue caused by wrong locale setting.

```bash
# Run as a root
echo "export LANGUAGE=en_US.UTF-8" >> /etc/environment
echo "export LANG=en_US.UTF-8" >> /etc/environment
echo "export LC_ALL=en_US.UTF-8" >> /etc/environment
locale-gen en_US.UTF-8
update-locale en_US.UTF-8
```

### Now log out and log in to check locale

`locale` should print out the following result as kptv or root.

#### With kptv user

```bash
locale
LANG=en_US.UTF-8
LANGUAGE=en_US.UTF-8
LC_CTYPE="en_US.UTF-8"
LC_NUMERIC="en_US.UTF-8"
LC_TIME="en_US.UTF-8"
LC_COLLATE="en_US.UTF-8"
LC_MONETARY="en_US.UTF-8"
LC_MESSAGES="en_US.UTF-8"
LC_PAPER="en_US.UTF-8"
LC_NAME="en_US.UTF-8"
LC_ADDRESS="en_US.UTF-8"
LC_TELEPHONE="en_US.UTF-8"
LC_MEASUREMENT="en_US.UTF-8"
LC_IDENTIFICATION="en_US.UTF-8"
LC_ALL=en_US.UTF-8
```

#### With root user

```bash
# Run as a root
locale
LANG=en_US.UTF-8
LANGUAGE=en_US.UTF-8
LC_CTYPE="en_US.UTF-8"
LC_NUMERIC="en_US.UTF-8"
LC_TIME="en_US.UTF-8"
LC_COLLATE="en_US.UTF-8"
LC_MONETARY="en_US.UTF-8"
LC_MESSAGES="en_US.UTF-8"
LC_PAPER="en_US.UTF-8"
LC_NAME="en_US.UTF-8"
LC_ADDRESS="en_US.UTF-8"
LC_TELEPHONE="en_US.UTF-8"
LC_MEASUREMENT="en_US.UTF-8"
LC_IDENTIFICATION="en_US.UTF-8"
LC_ALL=en_US.UTF-8
```

### Make sure Etc/UTC timezone is configured

`cat /etc/timezone` and check if it is `Etc/UTC`. If not, run `sudo timedatectl set-timezone Etc/UTC` to set to 'Etc/UTC'. However, the actual timezone configured in the final image will be set by Raspberry Pi Imager later. This is just to avoid any building issue.

### Install dependencies

```bash
sudo apt update
sudo apt-get install -y \
  coreutils quilt parted qemu-user-static \
  debootstrap zerofree zip dosfstools \
  libarchive-tools libcap2-bin grep \
  rsync xz-utils file git curl bc \
  qemu-utils kpartx gpg pigz
```

## User account of kpbuildtv server

- id: kptv
- pw: tv4pi2022

## How to clone kptv repository

As pi-gen project is included as a git submodule, it's necessary to initialise it too.

```bash
git clone git@nzgit.kiwiplan.co.nz:kiwiplan/iot/devices/kptv.git
cd kptv
git submodule update --init # This is to clone pi-gen project which is included as git submodule
```

## How to build

### From `nzjenkins3` for official releases

Go to `http://nzjenkins3:8080/jenkins/view/Common/job/KPTV/` and click `Build Now`.

#### Where is the build image uploaded?

The new image file will be uploaded to `/nfsjava/currentgit/kptv` of `nzjenkins3` and you can access the files at `http://nznfsjavainstallers/data/currentgit/kptv/` using any web browsers.

#### File naming rule

- 'kptv' + '_' + `version number` like 0.0.0 + _ + 'b' + jenkins `build number` + '.zip'
- For example, `kptv_1.0.0_b12.zip`
- `version number` is from the environmental variable 'VERSION_NUMBER' defined in this script.
- `build number` is from the jenkins' environmental variable BUILD_NUMBER passed to jenkins agency. If the build is triggered without this, `TEST` will be used instead of 'b' + `build_number`.

### `kpbuildtv` for testing 

`ssh kptv@kpbuildtv` and then run the following commands:

```bash
cd /home/kptv/workspace/KPTV
git pull 
echo "tv4pi2022" | sudo -S -E ./build.sh
```

You can find the built image like `kptv_1.0.0_TEST.zip` at `/home/kptv/workspace/KPTV/pi-gen/deploy`.

### build.sh

- `--clean` or `-c` : Use this option to clear the existing built stuff(stage 0 ~ 4). This implies `-a` or `--all` for all build. Building on `kpbuildtv` with 2 cpu allocated would take 6.5 hours. If possible, contact Ian Collins to temporarily have more cpus.  
- `--all` or `-a`: Use this option to update the existing built stuff(stage 0 ~ 4).
- When no option is set, only stage4-kptv will be updated.
- Regardless of options, stage4-kptv will be updated always.

## Image build test results

- Ubuntu 16.04: Doesn't work
- Ubuntu 20.04 server amd64: Works
- Debian 10.12(Buster, amd64): Works
- Raspberry Pi OS Bullseye(32bit) on RPi4: Works

## How to use the image

- Use Raspberry Pi Image(https://downloads.raspberrypi.org/imager/) v1.7.2 and after, which supports the advanced options for sd card image.
- Download the latest image zip file
- Insert micro sd card to use into sd card reader  
- Click 'CHOOSE OS' button 
  - Scroll down to 'Use custom' 
  - Select the downloaded zip file
- Click 'CHOOSE STORAGE' button
  - Choose the inserted sd card device
- Click the gear icon under 'WRITE' button to change the advance Options
  - Image customization options: to always use
  - Set host name: kptv
  - Enable ssh
    - Use password authentication
  - Set username and password
    - Username: kptv
    - Password: kptv
  - Set locale settings
    - Time zone: Pacific/Auckland <-- Choose whatever you want
    - Keyboard layout: us <-- Choose whatever you want
- Click 'WRITE' button

## Extra setups

### Boot read-only
Boot partition is protected as read-only by default.

### Enable Overlay File System(by default, disabled)
Enabling overlay file system will increase the life span of rpi4 device by protecting sd card as read-only.

```bash
ssh kptv@ip_address_of_rpi4 
sudo raspi-config nonint enable_overlayfs
sudo reboot
```

### Disable Overlay File System(by default, disabled)

```bash
ssh kptv@ip_address_of_rpi4 
sudo raspi-config nonint disable_overlayfs
sudo reboot
```

### Enable VNC(by default, disabled)

```bash
ssh kptv@ip_address_of_rpi4 
sudo raspi-config nonint do_vnc 0
sudo reboot
```

### Disable VNC(by default, disabled)
```bash
ssh kptv@ip_address_of_rpi4
sudo raspi-config nonint do_vnc 1
sudo reboot
```