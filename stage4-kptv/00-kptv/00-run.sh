#!/bin/bash -e

# Remove kwl directory
on_chroot << EOF
        echo "kwl removed"
        rm -rf /home/${FIRST_USER_NAME}/kwl
EOF

# Change wallpaper
install -v -m 644 "files/pcmanfm_desktop-items-0.conf" "${ROOTFS_DIR}/etc/xdg/pcmanfm/LXDE-pi/desktop-items-0.conf"
install -v -m 644 "files/pcmanfm_kiwiplan_wallpaper.jpg" "${ROOTFS_DIR}/usr/share/rpd-wallpaper/kiwiplan_wallpaper.jpg"

# Electron app to run
# - The directory to contain Kiwiplan Web Launcher files
install -v -o 1000 -g 1000 -m 755 -d "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/kwl"
# - The shell script to start Kiwiplan Web Launcher
install -v -o 1000 -g 1000 -m 644 "files/run_kwl.sh" "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/kwl/"
# - The configuration file required by Kiwiplan Web Launcher
install -v -o 1000 -g 1000 -m 644 "files/kwl.conf" "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/kwl/"
# - The zip file format of Kiwiplan Web Launcher
# - The latest Kiwiplan Web Launcher should be downloaded from nznfsjavainstallers/data/currentgit/web-launcher/
install -v -o 1000 -g 1000 -m 644 "files/kwl.zip" "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/kwl/"

# Automatic start up
install -v -m 644 "files/lxsession_autostart" "${ROOTFS_DIR}/etc/xdg/lxsession/LXDE-pi/autostart"

# Install the repo and the gpg key of log2ram
install -v -m 644 "files/log2ram_azlux.list" "${ROOTFS_DIR}/etc/apt/sources.list.d/azlux.list"
install -v -m 644 "files/log2ram_azlux-archive-keyring.gpg" "${ROOTFS_DIR}/usr/share/keyrings/azlux-archive-keyring.gpg"

# Apply customisations
on_chroot << EOF
        raspi-config nonint do_blanking 1
        raspi-config nonint do_vnc 1
        raspi-config nonint do_boot_wait 0
        raspi-config nonint enable_bootro
        raspi-config nonint do_overlayfs 1

        if ! grep -q "logo.nologo" /boot/cmdline.txt; then
          sed -i '\$s/\$/ logo.nologo vt.global_cursor_default=0/' /boot/cmdline.txt
        fi
        if grep -q "splash " /boot/cmdline.txt; then
          sed -i 's/splash //' /boot/cmdline.txt
        fi
        if ! grep -q "ipv6.disable=1" /boot/cmdline.txt; then
          sed -i '\$s/\$/ ipv6.disable=1/' /boot/cmdline.txt
        fi

        if ! grep -q "dtoverlay=disable-bt" /boot/config.txt; then
          echo "dtoverlay=disable-bt" >> /boot/config.txt
        fi
        if ! grep -q "disable_splash" /boot/config.txt; then
          echo "disable_splash=1" >> /boot/config.txt
        fi

        systemctl disable hciuart.service
        systemctl disable bluealsa.service
        systemctl disable bluetooth.service

        pushd /home/${FIRST_USER_NAME}/kwl
        unzip -u ./kwl.zip
        chmod +x ./kiwiweblauncher
        popd
        chown -R ${FIRST_USER_NAME}:${FIRST_USER_NAME} /home/${FIRST_USER_NAME}/kwl

        apt update
        apt install -y log2ram unclutter-xfixes
        systemctl disable log2ram-daily.timer
EOF

# Install the conf file of log2ram
install -v -m 644 "files/log2ram_log2ram.conf" "${ROOTFS_DIR}/etc/log2ram.conf"
