#!/bin/bash

# ======================================================================================
# This script is for downloading Cashera Core wallet v3.0.0 on a unix environment
# with a non-SSE2 CPU such as Raspberry Pi's (ARM processor).
#
# Required operating system  Raspbian Jessie, Stretch or Buster
# -------------------------  download Jessie:   https://downloads.raspberrypi.org/raspbian/images/raspbian-2017-07-05
#                            download Stretch:  https://downloads.raspberrypi.org/raspbian/images/raspbian-2019-04-09
#                            download Buster:   https://www.raspberrypi.org/downloads/raspbian
#
# How to run this script     set permission:    chmod +x Cashera_core_download_raspbian.sh
# ----------------------     run script:        ./Cashera_core_download_raspbian.sh
#                            start wallet:      Casherad -daemon
#                            get wallet info:   Cashera-cli getinfo
#                            logfile:           tail -f ~/.Cashera/debug.log
#
# More info                  script created by: cryptoBUZE
# ---------                  github:            https://github.com/cryptoBUZE
#                            Cashera website:  https://Cashera.com
# ======================================================================================

## General settings
Cashera_ROOT=~/Cashera-3.0.x
BDB_PREFIX="${Cashera_ROOT}/db4"
RASPBIAN_VERSION=`cat /etc/os-release | grep VERSION=`
cd ~

## OS info
case $RASPBIAN_VERSION in
  *jessie*)  RASPBIAN_VERSION="jessie" ;;
  *stretch*) RASPBIAN_VERSION="stretch" ;;
  *buster*)  RASPBIAN_VERSION="buster" ;;
  *)         echo "You are not running Rasbian Jessie, Stretch or Buster" && exit 1 ;;
esac

## SWAP file config (needed for Raspberry Pi's with 1G or less memory)
echo ""
echo "--- Setting swap file to 1G ---"
sudo sed -i "/CONF_SWAPSIZE=/ s/=.*/=1000/" /etc/dphys-swapfile
sudo dphys-swapfile setup
sudo dphys-swapfile swapon

## Download and install dependencies for running binaries (if not already installed) + downloading pre compiled Cashera Core wallet binaries
if [ $RASPBIAN_VERSION = "jessie" ]
then
  echo ""
  echo "--- Installing dependencies for Raspbian Jessie ---"
  sudo apt-get update -y && sudo apt-get install -y libqt4-dev libprotobuf-dev libboost-all-dev libminiupnpc-dev wget pkg-config unzip
  sudo apt-mark hold libqt4-dev libprotobuf-dev libboost-all-dev libssl-dev libminiupnpc-dev
  # Downloading pre compiled Cashera Core wallet binaries with ARM cpu support
  echo ""
  echo "--- Downloading pre compiled Cashera Core wallet for Raspbian Jessie ---"
  wget https://github.com/cryptoBUZE/Cashera/releases/download/rpi_raspbian_jessie_v3.0.0/Casherad
  wget https://github.com/cryptoBUZE/Cashera/releases/download/rpi_raspbian_jessie_v3.0.0/Cashera-cli
  wget https://github.com/cryptoBUZE/Cashera/releases/download/rpi_raspbian_jessie_v3.0.0/Cashera-qt
fi

if [ $RASPBIAN_VERSION = "stretch" ]
then
  echo ""
  echo "--- Installing dependencies for Raspbian Stretch ---"
  sudo apt-get update -y && sudo apt-get install -y libqt4-dev libprotobuf-dev libboost-all-dev wget pkg-config unzip
  sudo sed -i 's/stretch/jessie/g' /etc/apt/sources.list
  sudo apt-get update -y && sudo apt-get install -y libssl-dev
  sudo sed -i 's/jessie/stretch/g' /etc/apt/sources.list
  sudo apt-mark hold libqt4-dev libprotobuf-dev libboost-all-dev libssl-dev && sudo apt-get update -y
  # Downloading pre compiled Cashera Core wallet binaries with ARM cpu support
  echo ""
  echo "--- Downloading pre compiled Cashera Core wallet for Raspbian Stretch ---"
  wget https://github.com/cryptoBUZE/Cashera/releases/download/rpi_raspbian_stretch_v3.0.0/Casherad
  wget https://github.com/cryptoBUZE/Cashera/releases/download/rpi_raspbian_stretch_v3.0.0/Cashera-cli
  wget https://github.com/cryptoBUZE/Cashera/releases/download/rpi_raspbian_stretch_v3.0.0/Cashera-qt
fi

if [ $RASPBIAN_VERSION = "buster" ]
then
  echo ""
  echo "--- Installing dependencies for Raspbian Buster ---"
  sudo sed -i 's/buster/stretch/g' /etc/apt/sources.list
  sudo apt-get update -y && sudo apt-get install -y git build-essential libqt4-dev libprotobuf-dev protobuf-compiler libtool autotools-dev autoconf wget pkg-config libboost-thread-dev libboost-program-options-dev libboost-filesystem-dev libboost-system-dev
  sudo apt-mark hold libqt4-dev libprotobuf-dev libboost-thread-dev libboost-program-options-dev libboost-filesystem-dev libboost-system-dev && sudo apt-get update -y
  sudo sed -i 's/stretch/buster/g' /etc/apt/sources.list
  wget https://github.com/cryptoBUZE/Cashera/releases/download/rpi_raspbian_buster_v3.0.0/libssl1.0.0_1.0.1t-1%2Bdeb8u6_armhf.deb
  wget https://github.com/cryptoBUZE/Cashera/releases/download/rpi_raspbian_buster_v3.0.0/libssl-dev_1.0.1t-1%2Bdeb8u6_armhf.deb
  sudo dpkg -i libssl1.0.0_1.0.1t-1+deb8u6_armhf.deb
  sudo dpkg -i libssl-dev_1.0.1t-1+deb8u6_armhf.deb
  rm libssl*
  # Downloading pre compiled Cashera Core wallet binaries with ARM cpu support
  echo ""
  echo "--- Downloading pre compiled Cashera Core wallet for Raspbian Buster ---"
  wget https://github.com/cryptoBUZE/Cashera/releases/download/rpi_raspbian_buster_v3.0.0/Casherad
  wget https://github.com/cryptoBUZE/Cashera/releases/download/rpi_raspbian_buster_v3.0.0/Cashera-cli
  wget https://github.com/cryptoBUZE/Cashera/releases/download/rpi_raspbian_buster_v3.0.0/Cashera-qt
fi

## Setting permissions
sudo chown pi Cashera* && sudo chmod +x Cashera*
sudo mv Casherad Cashera-cli Cashera-qt /usr/local/bin

## Create Cashera.conf file for using Cashera Core command line interface and RPC calls
if test -f ~/.Cashera/Cashera.conf; then
  echo ""
  echo "--- Skipping step for creating Cashera.conf configuration file (already exists) ---"
else
  echo ""
  echo "--- Creating Cashera.conf configuration file ---"
  mkdir -p ~/.Cashera && cd ~/.Cashera
  echo "rpcuser="$USER >> Cashera.conf
  read RPC_PWD < <(date +%s | sha256sum | base64 | head -c 32 ; echo)
  echo "rpcpassword="$RPC_PWD >> Cashera.conf
fi

## Download snapshot of blockchain data if there is no wallet.dat in .Cashera folder
if test -f ~/.Cashera/wallet.dat; then
  echo ""
  echo "--- Skipping downloading of latest blockchain data for fast synchronization of blocks after wallet startup ---"
else
  echo ""
  echo "--- Downloading latest blockchain data for fast synchronization of blocks after wallet startup ---"
  wget -O rdd_blkchain.zip https://sourceforge.net/projects/Cashera-blockchain-snapshot/files/arm/rdd_blockchain_arm.zip/download
  unzip rdd_blkchain.zip
  rm rdd_blkchain.zip
fi

## Cashera Stakebox update from v2 to v3 wallet
if test -f ~/Cashera-2.0.1.2/rdd_logo.png; then
  echo ""
  echo "--- Hey Stakebox user! Replacing now old v2 wallet links to new v3 wallet links ---"
  # Removing older v2 wallet files
  cd ~
  mv Cashera-2.0.1.2/rdd_logo.png .
  rm -r Cashera-2.0.1.2
  wget https://github.com/cryptoBUZE/Cashera/releases/download/rpi_raspbian_jessie_v3.0.0/download_blockchain.sh
  chmod +x download_blockchain.sh
  # Set new wallpaper
  wget -O Cashera_wallpaper.png https://i.imgur.com/RoTUmUc.png
  pcmanfm --set-wallpaper /home/pi/Cashera_wallpaper.png
  # Update desktop links
  echo "[Desktop Entry]" > Desktop/Download\ Blockchain
  echo "Version=1.0" >> Desktop/Download\ Blockchain
  echo "Exec=/home/pi/download_blockchain.sh" >> Desktop/Download\ Blockchain
  echo "Name=Download Cashera blockchain" >> Desktop/Download\ Blockchain
  echo "Comment=Script for downloading the Cashera blockchain" >> Desktop/Download\ Blockchain
  echo "Encoding=UTF-8" >> Desktop/Download\ Blockchain
  echo "Terminal=true" >> Desktop/Download\ Blockchain
  echo "Type=Application" >> Desktop/Download\ Blockchain
  echo "[Desktop Entry]" > Desktop/Cashera\ Core.desktop
  echo "Version=1.0" >> Desktop/Cashera\ Core.desktop
  echo "Exec=Cashera-qt" >> Desktop/Cashera\ Core.desktop
  echo "Name=Cashera Core 3.0.0" >> Desktop/Cashera\ Core.desktop
  echo "Comment=Cashera Core QT Desktop Wallet" >> Desktop/Cashera\ Core.desktop
  echo "Icon=/home/pi/rdd_logo.png" >> Desktop/Cashera\ Core.desktop
  echo "Encoding=UTF-8" >> Desktop/Cashera\ Core.desktop
  echo "Terminal=false" >> Desktop/Cashera\ Core.desktop
  echo "Type=Application" >> Desktop/Cashera\ Core.desktop
fi
echo ""
echo "Done! You can now start the Cashera Core wallet as a daemon process with 'Casherad -daemon' or Cashera-qt for running the wallet in desktop mode."
