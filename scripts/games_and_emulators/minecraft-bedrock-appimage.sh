#!/bin/bash

clear -x

echo "Minecraft Bedrock script started!"
echo "Installing dependencies..."
sleep 1

cd ~
sudo apt install curl zenity kmod -y || error "Could not install dependencies"
rm -rf minecraft-bedrock
mkdir minecraft-bedrock
cd minecraft-bedrock
case "$dpkg_architecture" in
"arm64")
  type="arm64"
  type2="arm64"
  ;;
"armhf")
  type="armhf"
  type2="armhf"
  ;;
"i386")
  type="x86-" #the - at the end keeps i386 users from downloading both i386 and x86_64 files
  type2="i386"
  ;;
"amd64")
  type="x86_64"
  type2="amd64"
  ;;
*)
  echo "Error: your userspace architecture ($dpkg_architecture) is not supporeted by Minecraft Bedrock Launcher and will fail to run"
  echo ""
  echo "Exiting the script"
  sleep 3
  exit 2
  ;;
esac
curl https://api.github.com/repos/ChristopherHX/linux-packaging-scripts/releases/latest | grep "browser_download_url.*Launcher-$type" | cut -d : -f 2,3 | tr -d \" | wget -i -
mv *.AppImage MC.AppImage
chmod +x *.AppImage
curl https://api.github.com/repos/TheAssassin/AppImageLauncher/releases/latest | grep "browser_download_url.*bionic_$type2" | cut -d : -f 2,3 | tr -d \" | wget -i -
sudo dpkg -i *bionic_*.deb
hash -r
ail-cli integrate MC.AppImage || error "Couldn't integrate AppImage"
cd ~
rm -rf minecraft-bedrock

echo "Install Dependencies..."
cd ~

#NOTE:  a long time ago we used to use ZorinOS PPAs and Debian repos to get newer version of libraries needed to make the launcher work on 18.04.
#       this was a bad idea, and we've since gotten things working without external software sources. so the below section wipes out those if they're found on an 18.04 setup
case "$__os_codename" in
bionic)
  if $(dpkg --compare-versions $(dpkg-query -f='${Version}' --show libc6) lt 2.28); then
    echo "Continuing the install"
  else
    echo "Force Downgrading libc and related packages"
    echo "You may need to recompile other programs such as Dolphin and BOX64 if you see this message"
    sudo rm -rf /etc/apt/sources.list.d/zorinos-ubuntu-stable-bionic.list*
    sudo rm -rf /etc/apt/preferences.d/zorinos*
    sudo rm -rf /etc/apt/sources.list.d/debian-stable.list*
    sudo rm -rf /etc/apt/preferences.d/freetype*

    sudo apt update
    sudo apt install libc-bin=2.27* libc-dev-bin=2.27* libc6=2.27* libc6-dbg=2.27* libc6-dev=2.27* libfreetype6=2.8* libfreetype6-dev=2.8* locales=2.27* -y --allow-downgrades || error "Could not install dependencies"
  fi
  ;;
esac

echo "Please Reboot before launching!"
sleep 5
echo "Going back to the menu..."
sleep 2
