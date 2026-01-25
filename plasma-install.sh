#!/bin/bash 
export work_dir="$(pwd)"
sudo systemctl enable --now NetworkManager
sudo pacman -Sy --noconfirm
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm kdeconnect starship bash-completion bat fastfetch btop pavucontrol mpv firefox feh flameshot wget plasma konsole kate dolphin ark nfs-utils nano usbutils gnome-keyring fuse ffmpeg flatpak steam
sudo systemctl enable sddm

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

        # Config files
    mkdir -p ~/.config
    cp "$work_dir/config/starship.toml" ~/.config/
    mkdir -p ~/.config/fastfetch && cp -r "$work_dir/config/fastfetch/" ~/.config/

    # Shell configs
    cp "$work_dir/config/.bashrc" ~/.bashrc

echo -ne "
-------------------------------------------------------------------------
              Installation of Plasma Desktop Environment Complete
-------------------------------------------------------------------------
"

sudo reboot now