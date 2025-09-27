#!/bin/bash

titel_message="
 ██████╗ ███████╗██╗     ██╗   ██╗██╗  ██╗    ██████╗ ██╗    ██╗███╗   ███╗
 ██╔══██╗██╔════╝██║     ██║   ██║╚██╗██╔╝    ██╔══██╗██║    ██║████╗ ████║
 ██║  ██║█████╗  ██║     ██║   ██║ ╚███╔╝     ██║  ██║██║ █╗ ██║██╔████╔██║
 ██║  ██║██╔══╝  ██║     ██║   ██║ ██╔██╗     ██║  ██║██║███╗██║██║╚██╔╝██║
 ██████╔╝███████╗███████╗╚██████╔╝██╔╝ ██╗    ██████╔╝╚███╔███╔╝██║ ╚═╝ ██║
 ╚═════╝ ╚══════╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝    ╚═════╝  ╚══╝╚══╝ ╚═╝     ╚═╝                                          
"

print_message() {
    local message="$1"
    local message_length=${#message}
    local separator="-----------------------------------------------------------------------------"
    local spaces=$(( (${#separator} - message_length) / 2 ))
    printf "%s\n%${spaces}s%s\n%s\n" "$separator" "" "$message" "$separator"
}

work_dir=$(pwd)
USERNAME=$(logname)

if [ "$(id -u)" -eq 0 ]; then
    print_message "$titel_message"
    print_message "Du kan inte köra som root"
    exit 1
else
    print_message "$titel_message"
    print_message "Script starting"

    while true; do
        read -p "Vill du köra det här skriptet? (j/n) " jn
        case $jn in
            [yY] | [jJ] | [sS][oO] | [yY][eE][sS] | [jJ][aA] )
                echo "okej, vi fortsätter"
                break
                ;;
            [nN] | [nN][oO] | [nN][eE][iI][nN] )
                echo "avslutar..."
                exit
                ;;
            * )
                echo "Ogiltigt svar. Ange 'j' för ja eller 'n' för nej."
                exit
                ;;
        esac
    done
fi

function Installing() {
    clear
    print_message "$titel_message"
    print_message "installera paket"

#updateing
    sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
    sudo sed -i "/\Color/"'s/^#//' /etc/pacman.conf
    grep -q '^ILoveCandy' /etc/pacman.conf || sudo sed -i '/^\[options\]/a ILoveCandy' /etc/pacman.conf

    sudo pacman -Sy --noconfirm

    sudo pacman -Syu --noconfirm

#system
    sudo pacman -S --needed --noconfirm base-devel libx11 libxft xorg-server xorg-xinit ffmpeg networkmanager mate-polkit nfs-utils nano

#fonts
    sudo pacman -S --needed --noconfirm ttf-jetbrains-mono-nerd noto-fonts-emoji

#programs
    sudo pacman -S --needed --noconfirm rofi arandr xarchiver mpv firefox pavucontrol feh pcmanfm-gtk3 dunst
 
#KDE apps
    sudo pacman -S --needed --noconfirm kdeconnect

#terminal stuff 
    sudo pacman -S --needed --noconfirm starship picom bash-completion bat fastfetch btop

# YAY
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg --noconfirm -si
cd "$work_dir"
rm -rf yay-bin


if lsusb | grep -q "GoXLRMini"; then
yay -S --needed --noconfirm goxlr-utility
fi

}
function CopyingFiles() {
    clear
    print_message "$titel_message"
    print_message "Copying files"

    # Backgrounds
    mkdir -p ~/Bilder/backgrounds
    wget -O  ~/Bilder/backgrounds/wallpaper.jpg "https://lh3.googleusercontent.com/pw/AP1GczNr22gSNbdSNq_08trKdHkkswDq1k2PuefBqriaPp86lshFr10RjFqKQ_phn0187riksWgh-ouqn_6-MkHwVb5nIpyCaiH34WCOIywCis8X39gV3q3Fsy_9HZO-he7gxYnjbt7zulTazkiIj4qxyBjY"

    # Scripts
    mkdir -p ~/scripts
    cp -r "$work_dir"/scripts/ ~/

    # Starship config
    mkdir -p ~/.config
    cp "$work_dir/config/starship.toml" ~/.config/

    # MimeApps
    cp "$work_dir/config/mimeapps.list" ~/.config/

    # Rofi
    mkdir -p ~/.config/rofi
    cp -r "$work_dir"/config/rofi/ ~/.config/

    # FastFetch
    mkdir -p ~/.config/fastfetch
    cp -r "$work_dir"/config/fastfetch/ ~/.config/

    # Bash Profile
    cp "$work_dir/config/.bash_profile" ~/.bash_profile

    # Bash RC
    cp "$work_dir/config/.bashrc" ~/.bashrc

    # Xinit RC
    cp "$work_dir/config/.xinitrc" ~/.xinitrc


if lspci | grep -i 'vga' | grep -qi 'amd'; then
    # AMD GPU config
    sudo mkdir -p /etc/X11/xorg.conf.d
    sudo cp "$work_dir/config/20-amdgpu.conf" /etc/X11/xorg.conf.d/
fi

}


function buildingPackages() {
    clear
    print_message "$titel_message"
    print_message "Bygger och installerar dwm, st"
    
    cd "$work_dir"/dwm
    sudo make clean install
    cd "$work_dir"

    git clone https://github.com/DeluxerPanda/st.git
    cd st
    sudo make clean install
    cd "$work_dir"
    rm -rf st
}

configure_DarkMode() {
        echo "GTK_THEME=Adwaita:dark" | sudo tee -a /etc/environment > /dev/null
}

function setupAutologin() {
    while true; do
        read -p "Vill du logga in automatiskt? (j/n) " jn
        case $jn in
            [yY] | [jJ] | [sS][oO] | [yY][eE][sS] | [jJ][aA] )
                echo "okej, vi fortsätter"
                break
                ;;
            [nN] | [nN][oO] | [nN][eE][iI][nN] )
                echo "avslutar..."
                clear
                exit
                ;;
            * )
                echo "Ogiltigt svar. Ange 'j' för ja eller 'n' för nej."
                exit
                ;;
        esac
    done

    clear
    print_message "$titel_message"
    print_message "Setting up autologin"

    # Check if user exists
    if ! id "$USERNAME" &>/dev/null; then
        echo "User '$USERNAME' does not exist. Please create the user first."
        exit 1
    fi

    # Create systemd override directory if not exists
    sudo mkdir -p /etc/systemd/system/getty@tty1.service.d

    # Write the override configuration
    sudo bash -c "cat <<'EOF' > /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $USERNAME --noclear %I \$TERM
EOF"

    sudo systemctl enable getty@tty1

    clear
}

Installing
CopyingFiles
buildingPackages
configure_DarkMode
setupAutologin
