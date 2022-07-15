#!/bin/bash

#add armhf architecture (multiarch)
if [[ $(dpkg --print-foreign-architectures) == *"armhf"* ]]; then
  echo "armhf arcitecture already added..."
else
  sudo dpkg --add-architecture armhf
  # perform an apt update to check for errors
  # if apt update errors, assume that adding the foreign arch caused it and remove it
  sudo apt update
  if [[ "$?" != 0 ]]; then
    sudo dpkg --remove-architecture armhf
    error "armhf architecture caused apt to error so it has been removed!"
  fi
fi

# add mesa 22+ ppa
# this is known to conflict with the LLVM 14 APT repo. it must be removed if a user has manually installed it
ppa_name="kisak/turtle" && ppa_installer
sudo apt upgrade -y || error "Could not upgrade MESA (needs for Steam VirtualGL hardware acceleration)"

sudo apt install ninja-build python3 python3-pip -y || error "Could not install VIRGL build dependencies"
hash -r
python3 -m pip install meson || error "Could not install meson VIRGL build dependency"
hash -r

# compile and install epoxy
cd
rm -rf libepoxy
git clone https://github.com/anholt/libepoxy
cd libepoxy
meson -Dprefix=/usr build
ninja -j$(nproc) -C build
sudo ninja -C build install || error "Could not install libepoxy"

# virgl
cd
rm -rf virglrenderer
git clone https://gitlab.freedesktop.org/virgl/virglrenderer.git
cd virglrenderer
meson -Dprefix=/usr build
ninja -j$(nproc) -C build
sudo ninja -C build install || error "Could not install virglrenderer"


# install sdl2
bash -c "$(curl -s https://raw.githubusercontent.com/$repository_username/L4T-Megascript/$repository_branch/scripts/sdl2_install_helper.sh)" || error "Could not install SDL2"
# installing dependencies
sudo apt install -y libsdl2-2.0-0:arm64 libsdl2-2.0-0:armhf libsdl2-mixer-2.0-0:armhf libsdl2-mixer-2.0-0:arm64 libnss3:armhf libnm0:armhf libdbus-glib-1-2:armhf libudev1:armhf libnspr4:armhf libgudev-1.0-0:armhf libxtst6:armhf libsm6:armhf libice6:armhf libusb-1.0-0:armhf libnss3 libnm0 libdbus-glib-1-2 libudev1 libnspr4 libgudev-1.0-0 libxtst6 libsm6 libice6 libusb-1.0-0 || error "Could not install steam dependencies"

bash -c "$(curl -s https://raw.githubusercontent.com/$repository_username/L4T-Megascript/$repository_branch/scripts/box86.sh)"|| exit $?
bash -c "$(curl -s https://raw.githubusercontent.com/$repository_username/L4T-Megascript/$repository_branch/scripts/box64.sh)"|| exit $?

echo "Installing steam.deb"
wget https://steamcdn-a.akamaihd.net/client/installer/steam.deb -qO /tmp/steam.deb || error "Failed to download steam.deb"
sudo apt install --no-install-recommends -y /tmp/steam.deb || error "Failed to install steam.deb"

sudo mkdir -p /usr/local/bin /usr/local/share/applications
# if a matching name binary is found in /usr/local/bin it takes priority over /usr/bin
echo '#!/bin/bash
if ! pgrep virgl_test_ser*; then
  virgl_test_server --use-egl-surfaceless & export pid_virgl=$!
  echo "VIRGL Server Started"
fi
export STEAMOS=1
export STEAM_RUNTIME=1
GALLIUM_DRIVER=virpipe BOX64_LOG=1 BOX86_LOG=1 BOX64_EMULATED_LIBS=libmpg123.so.0 /usr/lib/steam/bin_steam.sh -no-cef-sandbox steam://open/minigameslist "$@"

kill $pid_virgl' | sudo tee /usr/local/bin/steam || error "Failed to create steam launch script"

# set execution bit
sudo chmod +x /usr/local/bin/steam

# copy official steam.desktop file to /usr/local and edit it
# we can't edit the official steam.desktop file since this will get overwritten on a steam update
# if a matching name .desktop file is found in /usr/local/share/applications it takes priority over /usr/share/applications
sudo cp /usr/share/applications/steam.desktop /usr/local/share/applications/steam.desktop
sudo sed -i 's:Exec=/usr/bin/steam:Exec=/usr/local/bin/steam:' /usr/local/share/applications/steam.desktop

# remove deb
rm /tmp/steam.deb

if ! echo "$XDG_DATA_DIRS" | grep -q "/usr/local/share" || ! echo "$PATH" | grep -q "/usr/local/bin" ; then
  warning "YOU NEED TO REBOOT before starting steam. This is because Steam is the first application on your system to be installed into the /usr/local folder."
fi