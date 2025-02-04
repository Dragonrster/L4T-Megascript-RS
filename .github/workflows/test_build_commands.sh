#!/bin/bash

sudo chown runner:docker /home/runner
# print user info
echo $USER $USERNAME $(id) $(whoami)
sudo bash -c 'echo $USER $USERNAME $(id) $(whoami)'
echo "GITHUB_JOB: $GITHUB_JOB"

# set DIRECTORY variable
DIRECTORY="$(pwd)"

# print date
date

#necessary functions
error() { #red text and exit 1
  echo -e "\e[91m$1\e[0m" 1>&2
  exit 1
}

warning() { #yellow text
  echo -e "\e[93m\e[5m◢◣\e[25m WARNING: $1\e[0m" 1>&2
}

status() { #cyan text to indicate what is happening
  
  #detect if a flag was passed, and if so, pass it on to the echo command
  if [[ "$1" == '-'* ]] && [ ! -z "$2" ];then
    echo -e $1 "\e[96m$2\e[0m" 1>&2
  else
    echo -e "\e[96m$1\e[0m" 1>&2
  fi
}

status_green() { #announce the success of a major action
  echo -e "\e[92m$1\e[0m" 1>&2
}


if [[ "$GITHUB_JOB" == "bionic-64bit" ]]; then
  # fix nvidia jank
  # update sources list for t210
  sudo sed -i "s/<SOC>/t210/" /etc/apt/sources.list.d/nvidia-l4t-apt-source.list
  # add ld conf files
  echo "/usr/lib/aarch64-linux-gnu/tegra-egl" | sudo tee /etc/ld.so.conf.d/aarch64-linux-gnu_EGL.conf
  echo "/usr/lib/aarch64-linux-gnu/tegra" | sudo tee /etc/ld.so.conf.d/aarch64-linux-gnu_GL.conf
fi

if [[ "$GITHUB_JOB" == "focal-64bit" ]]; then
  # fix nvidia jank
  # update sources list for t194
  sudo sed -i "s/<SOC>/t194/" /etc/apt/sources.list.d/nvidia-l4t-apt-source.list
fi

sudo apt update
if [[ "$GITHUB_JOB" == "bionic-64bit" ]]; then
  # update certificate chain
  sudo apt install -y ca-certificates
fi

sudo apt install -y curl wget

#determine what type of input we received
if [ -z "$name" ]; then
  error "No Helper Script name format passed to script. Exiting now."
fi

status "Testing: $name"

# create standard directories
mkdir -p  $HOME/.local/share/applications $HOME/.local/bin
sudo mkdir -p /usr/local/bin /usr/local/share/applications

#load functions from github source
unset functions_downloaded
source <(curl -s https://raw.githubusercontent.com/cobalt2727/L4T-Megascript/master/functions.sh)
[[ ! -z ${functions_downloaded+z} ]] && status "Functions Loaded" || error "Oh no! Something happened to your internet connection! Exiting the Megascript - please fix your internet and try again!"

# run runonce entries
# this replaces the need for an initial setup script
status "Runing Initial Setup Runonce entries"
bash -c "$(curl -s https://raw.githubusercontent.com/cobalt2727/L4T-Megascript/master/scripts/runonce-entries.sh)"

bash <( curl https://raw.githubusercontent.com/cobalt2727/L4T-Megascript/master/helper.sh ) "$name"
