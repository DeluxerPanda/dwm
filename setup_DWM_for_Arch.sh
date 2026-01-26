#!/bin/bash
set -e  # Exit on error

titel_message="
 ██████╗ ███████╗██╗     ██╗   ██╗██╗  ██╗    ██████╗ ██╗    ██╗███╗   ███╗
 ██╔══██╗██╔════╝██║     ██║   ██║╚██╗██╔╝    ██╔══██╗██║    ██║████╗ ████║
 ██║  ██║█████╗  ██║     ██║   ██║ ╚███╔╝     ██║  ██║██║ █╗ ██║██╔████╔██║
 ██║  ██║██╔══╝  ██║     ██║   ██║ ██╔██╗     ██║  ██║██║███╗██║██║╚██╔╝██║
 ██████╔╝███████╗███████╗╚██████╔╝██╔╝ ██╗    ██████╔╝╚███╔███╔╝██║ ╚═╝ ██║
 ╚═════╝ ╚══════╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝    ╚═════╝  ╚══╝╚══╝ ╚═╝     ╚═╝                                          
"

work_dir="$(pwd)"
USERNAME="$(logname)"

# Helper function to print formatted messages
print_message() {
    local message="$1"
    local message_length=${#message}
    local separator="-----------------------------------------------------------------------------"
    local spaces=$(( (${#separator} - message_length) / 2 ))
    printf "%s\n%${spaces}s%s\n%s\n" "$separator" "" "$message" "$separator"
}

# Helper function for yes/no prompts
prompt_yes_no() {
    local prompt="$1"
    while true; do
        read -p "$prompt (j/n) " jn
        case "$jn" in
            [yY] | [jJ] | [sS][oO] | [yY][eE][sS] | [jJ][aA] )
                return 0
                ;;
            [nN] | [nN][oO] | [nN][eE][iI][nN] )
                return 1
                ;;
            * )
                echo "Ogiltigt svar. Ange 'j' för ja eller 'n' för nej."
                ;;
        esac
    done
}

# Check if running as root
if [ "$(id -u)" -eq 0 ]; then
    print_message "$titel_message"
    print_message "Du kan inte köra som root"
    exit 1
fi

print_message "$titel_message"
print_message "Script starting"

if ! prompt_yes_no "Vill du köra det här skriptet?"; then
    echo "avslutar..."
    exit 0
fi

function Installing() {
    clear
    print_message "$titel_message"
    print_message "installera paket"

    # Update pacman config
    sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
    sudo sed -i "/\Color/"'s/^#//' /etc/pacman.conf
    grep -q '^ILoveCandy' /etc/pacman.conf || sudo sed -i '/^\[options\]/a ILoveCandy' /etc/pacman.conf

    sudo pacman -Sy --noconfirm
    sudo pacman -Syu --noconfirm

    # System packages
    sudo pacman -S --needed --noconfirm base-devel libx11 libxft xorg-server xorg-xinit ffmpeg networkmanager mate-polkit nfs-utils nano usbutils gnome-keyring fuse

    # Fonts
    sudo pacman -S --needed --noconfirm ttf-jetbrains-mono-nerd noto-fonts-emoji

    # Programs
    sudo pacman -S --needed --noconfirm rofi arandr xarchiver mpv firefox pavucontrol feh pcmanfm dunst flameshot wget zip unzip

    # KDE apps
    sudo pacman -S --needed --noconfirm kdeconnect

    # Terminal utilities
    sudo pacman -S --needed --noconfirm starship bash-completion bat fastfetch btop

    # Install YAY
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg --noconfirm -si
    cd "$work_dir"
    rm -rf yay-bin

    # Optional GoXLR support
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
    wget -O ~/Bilder/backgrounds/wallpaper.jpg "https://lh3.googleusercontent.com/pw/AP1GczNr22gSNbdSNq_08trKdHkkswDq1k2PuefBqriaPp86lshFr10RjFqKQ_phn0187riksWgh-ouqn_6-MkHwVb5nIpyCaiH34WCOIywCis8X39gV3q3Fsy_9HZO-he7gxYnjbt7zulTazkiIj4qxyBjY"

    sudo mkdir -p /mnt/DeluxDrive
    sudo mkdir -p /mnt/media
    sudo mkdir -p /mnt/Squizzmallow

    # Config files
    mkdir -p ~/.config
    cp "$work_dir/config/starship.toml" ~/.config/
    cp "$work_dir/config/mimeapps.list" ~/.config/
    mkdir -p ~/.config/rofi && cp -r "$work_dir/config/rofi/" ~/.config/
    mkdir -p ~/.config/fastfetch && cp -r "$work_dir/config/fastfetch/" ~/.config/

    # Shell configs
    cp "$work_dir/config/.bash_profile" ~/.bash_profile
    cp "$work_dir/config/.bashrc" ~/.bashrc
    cp "$work_dir/config/.xinitrc" ~/.xinitrc

    # Dark theme
    echo "GTK_THEME=Adwaita:dark" | sudo tee -a /etc/environment > /dev/null

    # GPU configuration
    if lspci | grep -i 'vga' | grep -qi 'amd'; then
        if prompt_yes_no "Vill du konfigurera AMD GPU som primär?"; then
        sudo mkdir -p /etc/X11/xorg.conf.d
        sudo cp "$work_dir/config/20-amdgpu.conf" /etc/X11/xorg.conf.d/20-amdgpu.conf
        fi
    fi

    # Dual GPU setup (AMD + NVIDIA)
    if lspci | grep -i 'vga' | grep -qi 'amd' && lspci | grep -i 'vga' | grep -qi 'nvidia'; then
        sudo pacman -S --needed --noconfirm go
        git clone https://github.com/HikariKnight/quickpassthrough.git
        cd quickpassthrough
        go mod download
        CGO_ENABLED=0 go build -ldflags="-X github.com/HikariKnight/quickpassthrough/internal/version.Version=$(git rev-parse --short HEAD)" -o quickpassthrough cmd/main.go
        chmod +x ./quickpassthrough
        ./quickpassthrough
        cd "$work_dir"
        rm -rf quickpassthrough
    fi
}

function buildingPackages() {
    clear
    print_message "$titel_message"
    print_message "Bygger och installerar dwm, st"
    
    cd "$work_dir/dwm"
    sudo make clean install
    cd "$work_dir"

    git clone https://github.com/DeluxerPanda/st.git
    cd st
    sudo make clean install
    cd "$work_dir"
    rm -rf st
}

function setupAutologin() {
    if ! prompt_yes_no "Vill du logga in automatiskt?"; then
        echo "avslutar..."
        clear
        sudo reboot
        exit 0
    fi

    clear
    print_message "$titel_message"
    print_message "Setting up autologin"

    # Check if user exists
    if ! id "$USERNAME" &>/dev/null; then
        echo "User '$USERNAME' does not exist. Please create the user first."
        exit 1
    fi

    # Create systemd override directory
    sudo mkdir -p /etc/systemd/system/getty@tty1.service.d

    # Write the override configuration
    sudo bash -c "cat > /etc/systemd/system/getty@tty1.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $USERNAME --noclear %I \$TERM
EOF"

    sudo systemctl enable getty@tty1

    clear
    sudo reboot
}

# Main execution
Installing
CopyingFiles
buildingPackages
setupAutologin
