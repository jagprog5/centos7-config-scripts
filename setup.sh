#!/bin/bash

VER=`cat /etc/redhat-release`
[[ $VER =~ ^"CentOS Linux release 7"* ]] || exit 1

sudo sh -c "echo -e \"<html>\n<body style=\"background-color:black\;\"></body>\n</html>\" > /usr/share/doc/HTML/index.html"
cd ~/.mozilla/firefox/
cd $(ls | grep '\.default-default$')
echo -e "user_pref(\"browser.in-content.dark-mode\", true);\nuser_pref(\"browser.display.background_color\", \" #000000\");\nuser_pref(\"browser.startup.page\", 3);" > user.js
# mkdir chrome
# cd chrome/
# echo -e "#browser vbox#appcontent tabbrowser, #content, #tabbrowser-tabpanels,\nbrowser[type=content-primary],browser[type=content] > html {\n    background: #000000 !important\n}" > userChrome.css

# I can't automatically install the add-ons:
# https://blog.mozilla.org/addons/2019/10/31/firefox-to-discontinue-sideloaded-extensions/
# Unfortunately a button prompt is required per add-on
curl -LO "https://addons.mozilla.org/firefox/downloads/file/3615260/dark_reader.xpi"
curl -LO "https://addons.mozilla.org/firefox/downloads/file/3629683/ublock_origin.xpi"
READERHASH=`sha256sum dark_reader.xpi`
if echo "$READERHASH" | grep -q "6027a82e9133aabb4536f9f182d27307156d00c05e891623ded5107c28542e55  dark_reader.xpi"; then
    firefox -new-window dark_reader.xpi
else
    echo "dark_reader hash didn't match!"
    echo "$READERHASH"
    rm -v *.xpi
    exit 1
fi
read -n 1 -s -r -p "Press any key when done with previous firefox add-on prompt."
echo ""
BLOCKERHASH=`sha256sum ublock_origin.xpi`
if echo "$BLOCKERHASH" | grep -q "e9d2fa95b5323cec0e56e439b995326203d13c2fc781927741270ea34d244d30  ublock_origin.xpi"; then
    firefox -new-window ublock_origin.xpi
else
    echo "ublock hash didn't match!"
    echo "$BLOCKERHASH"
    rm -v *.xpi
    exit 1
fi
read -n 1 -s -r -p "Press any key when done with previous firefox add-on prompt."
echo ""
rm -v *.xpi

echo "Enter hostname: "
read HOST_NAME
[ -z "$HOST_NAME" ] && hostnamectl set-hostname "$HOST_NAME"
git config --global color.ui auto
echo "Enter git global email: "
read GIT_EMAIL
[ -z "$GIT_EMAIL" ] && git config --global user.email "$GIT_EMAIL"
echo "Enter git global name: "
read GIT_NAME
[ -z "$GIT_NAME" ] && git config --global user.email "$GIT_NAME"

gsettings set org.gnome.desktop.interface enable-animations false
gsettings set org.gnome.desktop.interface gtk-theme HighContrastInverse
gsettings set org.gnome.desktop.background primary-color '#0B000B'
gsettings set org.gnome.desktop.background picture-options none
gsettings set org.gnome.desktop.screensaver picture-uri file:///usr/share/backgrounds/7lines-top.png
gsettings set org.gnome.desktop.background show-desktop-icons false
gsettings set org.gnome.desktop.interface show-battery-percentage true
gsettings set org.gnome.desktop.interface clock-show-date true

gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/open-terminal/']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/open-terminal/ name 'Open Terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/open-terminal/ command 'gnome-terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/open-terminal/ binding '<Primary><Alt>t'

sudo yum update -y
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
sudo yum install -y code

echo -e "unbind C-b\nset -g prefix C-Space\nbind Space send-prefix" > ~/.tmux.conf
sudo yum install -y tmux
echo "alias tm=\"tmux attach || tmux\"" >> ~/.bashrc
source ~/.bashrc

sudo sh -c 'echo -e "[docker-ce-stable]\nbaseurl=https://download.docker.com/linux/centos/7/$basearch/stable\nenabled=1\ngpgcheck=1\ngpgkey=https://download.docker.com/linux/centos/gpg" > /etc/yum.repos.d/docker-ce.repo'
sudo yum install -y docker-ce docker-ce-cli containerd.io
sudo systemctl enable docker.service

# keepass2
sudo sh -c 'echo -e "[mono-centos7-stable]\nbaseurl=https://download.mono-project.com/repo/centos7-stable/\nenabled=1\ngpgcheck=1\ngpgkey=https://download.mono-project.com/repo/xamarin.gpg" > /etc/yum.repos.d/mono-centos7-stable.repo'
sudo yum install -y mono
curl -o keepass2.zip -L "https://sourceforge.net/projects/keepass/files/KeePass 2.x/2.45/KeePass-2.45.zip/download"
KEEPASSHASH=`sha256sum keepass2.zip`
if echo "$KEEPASSHASH" | grep -q "d414db9d411acbafd4e1b5faa8605ad7a28829f1814ce779142ffbd5ca9c3794  keepass2.zip"; then
    sudo unzip keepass2.zip -d /opt/keepass2
    sudo curl "https://upload.wikimedia.org/wikipedia/commons/0/04/KeePass_icon.svg" -o /opt/keepass2/icon.svg
    sudo sh -c 'echo -e "[Desktop Entry]\nType=Application\nTerminal=false\nName=KeePass2\nIcon=/opt/keepass2/icon.svg\nExec=mono /opt/keepass2/KeePass.exe" > /usr/share/applications/keepass2.desktop'
    sudo update-desktop-database
else
    echo "keepass2 hash didn't match!"
    echo "$KEEPASSHASH"
    rm keepass2.zip
    exit 1
fi
rm keepass2.zip

