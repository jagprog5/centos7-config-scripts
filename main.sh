#!/bin/bash
set -o pipefail

VER=`cat /etc/redhat-release`
[[ $VER =~ ^"CentOS Linux release 7"* ]] || {
    echo "Wrong os version: $VER"
    exit 1
}

DIR=$(dirname "$(readlink -f "$0")")

verify_hash() {
    local EXPECTED_HASH="$1"
    test -z "$EXPECTED_HASH" && return 0
    local FILE="$2"
    local HASH=$(sha256sum "$FILE")
    echo "$HASH" | grep -q "^$EXPECTED_HASH" || {
        echo "HASH DIDN'T MATCH!"
        echo "Expecting: $EXPECTED_HASH, but got: $HASH"
        return 1
    }
    return 0
}

confirm_prompt() {
    local MSG="$1 (y/n): "
    while true; do
        read -p "$MSG" yn
        case "$yn" in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

confirm_prompt "Install vscode?" && cat "$DIR"/files/vscode | sudo dd of=/etc/yum.repos.d/vscode.repo 2>/dev/null &&
    sudo yum install -y code
confirm_prompt "Install docker?" && cat "$DIR"/files/docker | sudo dd of=/etc/yum.repos.d/docker-ce.repo 2>/dev/null &&
    sudo yum install -y docker-ce docker-ce-cli containerd.io &&
    sudo systemctl enable docker.service
confirm_prompt "Install keepass2, and mono?" && cat "$DIR"/files/mono | sudo dd of=/etc/yum.repos.d/mono-centos7-stable.repo 2>/dev/null &&
    sudo yum install -y mono &&
    curl -o keepass2.zip -L "https://sourceforge.net/projects/keepass/files/KeePass 2.x/2.45/KeePass-2.45.zip/download" && 
    (
        if verify_hash ad414db9d411acbafd4e1b5faa8605ad7a28829f1814ce779142ffbd5ca9c3794 keepass2.zip
        then
            exit 0
        else
            sudo rm -fv keepass2.zip
            exit 1
        fi
    ) &&
    sudo unzip keepass2.zip -d /opt/keepass2 &&
    sudo curl "https://upload.wikimedia.org/wikipedia/commons/0/04/KeePass_icon.svg" -o /opt/keepass2/icon.svg &&
    cat "$DIR"/files/keepass2 | sudo dd of=/usr/share/applications/keepass2.desktop 2>/dev/null &&
    sudo update-desktop-database &&
    rm keepass2.zip
confirm_prompt "Build and install git 2.28.0?" &&
    sudo yum remove -y git && 
    curl -o git.zip -L https://github.com/git/git/archive/v2.28.0.zip &&
    (
        if verify_hash 93badab0d6980a7986b58c4b38d499176c1d48bacd3a5623d4b837e083b4fcd3 git.zip
        then
            exit 0
        else
            sudo rm -fv git.zip
            exit 1
        fi
    ) &&
    unzip git.zip &&
    rm git.zip &&
    sudo yum groupinstall "Development Tools" -y &&
    sudo yum install gettext-devel openssl-devel perl-CPAN perl-devel zlib-devel curl-devel -y &&
    cd git-2.28.0 &&
    make configure &&
    ./configure --prefix=/usr/local &&
    sudo make install &&
    sudo yum --setopt=groupremove_leaf_only=1 groupremove 'Development Tools' -y &&
    sudo yum remove gettext-devel openssl-devel perl-CPAN perl-devel zlib-devel curl-devel -y &&
    cd .. &&
    sudo rm -r git-2.28.0/ &&
    git config --global color.ui auto && {
        echo "Enter git global email: "
        read GIT_EMAIL
        [ -z "$GIT_EMAIL" ] && git config --global user.email "$GIT_EMAIL"
        echo "Enter git global name: "
        read GIT_NAME
        [ -z "$GIT_NAME" ] && git config --global user.email "$GIT_NAME"
    }
confirm_prompt "Set gnome theme? " && {
    gsettings set org.gnome.desktop.interface enable-animations false
    gsettings set org.gnome.desktop.interface gtk-theme HighContrastInverse
    gsettings set org.gnome.desktop.background primary-color '#1F001F'
    gsettings set org.gnome.desktop.background picture-options none
    gsettings set org.gnome.desktop.screensaver picture-uri file:///usr/share/backgrounds/7lines-top.png
    gsettings set org.gnome.desktop.background show-desktop-icons false
    gsettings set org.gnome.desktop.interface show-battery-percentage true
    gsettings set org.gnome.desktop.interface clock-show-date true
}
confirm_prompt "Set ctrl+alt+t => open terminal? Warning: overwrites existing shortcuts." && {
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/open-terminal/']"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/open-terminal/ name 'Open Terminal'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/open-terminal/ command 'gnome-terminal'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/open-terminal/ binding '<Primary><Alt>t'
}

confirm_prompt "Build and install tmux 2.9?" && 
    sudo yum remove -y tmux &&
    curl -o tmux.zip -L https://github.com/tmux/tmux/archive/2.9.zip &&
    (
        if verify_hash 8f012810d19f29d7decd564b939ce405deaf144ff43e3cc6900fe815fc872287 tmux.zip
        then
            exit 0
        else
            sudo rm -fv tmux.zip
            exit 1
        fi
    ) &&
    unzip tmux.zip &&
    rm tmux.zip &&
    cd tmux-2.9 &&
    sudo yum install -y libevent-devel ncurses-devel automake && 
    sh autogen.sh &&
    ./configure &&
    sudo make install &&
    cd .. &&
    sudo rm -r tmux-2.9 && 
    cat "$DIR"/files/tmux > ~/.tmux.conf &&
    echo "alias tm=\"tmux attach || tmux\"" >> ~/.bashrc &&
    source ~/.bashrc && 
    sudo yum remove -y libevent-devel ncurses-devel automake &&


confirm_prompt "Configure firefox?" && 

echo "Enter hostname: "
read HOST_NAME
[ -z "$HOST_NAME" ] && hostnamectl set-hostname "$HOST_NAME"
