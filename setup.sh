#!/bin/bash

VER=`cat /etc/redhat-release`
[[ $VER =~ ^"CentOS Linux release 7"* ]] || exit 1

sudo sh -c "echo \"<html><body style=\"background-color:black\;\"></body></html>\" > /usr/share/doc/HTML/index.html"
cd ~/.mozilla/firefox/
cd $(ls | grep '\.default-default$')
echo "user_pref(\"browser.in-content.dark-mode\", true);\
user_pref(\"browser.display.background_color\", \" #1a1a1a\");\
user_pref(\"browser.startup.page\", 3);" > user.js

curl -LO https://addons.mozilla.org/firefox/downloads/file/3615260/dark_reader.xpi
# I can't automatically install the add-ons:
# https://blog.mozilla.org/addons/2019/10/31/firefox-to-discontinue-sideloaded-extensions/
# Unfortunately a button press is required per add-on
firefox -new-window dark_reader.xpi
curl -LO https://addons.mozilla.org/firefox/downloads/file/3629683/ublock_origin.xpi

hostnamectl set-hostname old-boi

gsettings set org.gnome.desktop.interface enable-animations false
gsettings set org.gnome.desktop.interface gtk-theme HighContrastInverse
gsettings set org.gnome.desktop.background picture-uri file:///usr/share/backgrounds/7lines-top.png
gsettings set org.gnome.desktop.screensaver picture-uri file:///usr/share/backgrounds/7lines-top.png
gsettings set org.gnome.desktop.background show-desktop-icons false
gsettings set org.gnome.desktop.interface show-battery-percentage true
gsettings set org.gnome.desktop.interface clock-show-date true

gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/open-terminal/']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/open-terminal/ name 'Open Terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/open-terminal/ command 'gnome-terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/open-terminal/ binding '<Primary><Alt>t'

# get vscode
sudo yum update -y
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
sudo yum install -y code

# get tmux
sudo yum install -y tmux
echo "alias tm=\"tmux attach || tmux\"" >> ~/.bashrc
source ~/.bashrc

sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io
sudo systemctl enable docker.service

read -n 1 -s -r -p "Press any key when done with previous firefox add-on prompt."
echo ""
firefox -new-window ublock_origin.xpi
read -n 1 -s -r -p "Press any key when done with previous firefox add-on prompt."
echo ""
rm -v *.xpi
