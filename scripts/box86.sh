#!/bin/bash

case "$dpkg_architecture" in
"arm64")
  case "$__os_codename" in
  bionic) ppa_name="theofficialgman/cmake-bionic" && ppa_installer ;;
  esac
  ;;
"amd64")
  echo "Installing Dependencies"
  ;;
*)
  error_user "Error: your cpu architecture ($dpkg_architecture) is not supported by box64 and will fail to compile"
  ;;
esac

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

# allow loading of MESA libraries (still uses ARM64 proprietary nvidia drivers)
sudo sed -i "s/\"library_path\" : .*/\"library_path\" : \"libEGL_mesa.so.0\"/g" "/usr/share/glvnd/egl_vendor.d/50_mesa.json"
sudo sed -i 's:^DISABLE_MESA_EGL="1":DISABLE_MESA_EGL="0":' /etc/systemd/nv.sh

cd ~
# gcc 7 produces errors when compiling on arm/arm64 on both box86 and box64
# there is no available gcc-11 armhf cross compiler so the gcc-8 armhf cross compiler is used and it works fine
sudo apt install -y cmake git build-essential gcc-8-arm-linux-gnueabihf libsdl2-mixer-2.0-0:armhf libsdl2-image-2.0-0:armhf libsdl2-net-2.0-0:armhf libsdl2-2.0-0:armhf libc6:armhf libx11-6:armhf libgdk-pixbuf2.0-0:armhf libgtk2.0-0:armhf libstdc++6:armhf libpng16-16:armhf libcal3d12v5:armhf libopenal1:armhf libcurl4:armhf osspd:armhf libjpeg62:armhf libudev1:armhf || error "Could install box86 dependencies"

rm -rf box86
git clone --depth=1 https://github.com/ptitSeb/box86.git
cd box86
mkdir build
cd build
cmake .. -DCMAKE_ASM_FLAGS="-marm -pipe -march=armv8-a+crc+simd+crypto -mcpu=cortex-a57 -mfpu=crypto-neon-fp-armv8 -mfloat-abi=hard" -DCMAKE_C_FLAGS="-marm -pipe -march=armv8-a+crc+simd+crypto -mcpu=cortex-a57 -mfpu=crypto-neon-fp-armv8 -mfloat-abi=hard" -DCMAKE_C_COMPILER=arm-linux-gnueabihf-gcc-8 -DARM_DYNAREC=ON
make -j$(nproc) || error "Compilation failed"
sudo make install || error "Make install failed"
sudo systemctl restart systemd-binfmt

rm -rf rm -rf ~/box86
