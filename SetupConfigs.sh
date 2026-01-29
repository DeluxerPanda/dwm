#!/bin/bash

work_dir="$(pwd)"

select_option() {
    local options=("$@")
    local num_options=${#options[@]}
    local selected=0
    local last_selected=-1

    while true; do
        # Move cursor up to the start of the menu
        if [ $last_selected -ne -1 ]; then
            echo -ne "\033[${num_options}A"
        fi

        if [ $last_selected -eq -1 ]; then
            echo "Please select an option using the arrow keys and Enter:"
        fi
        for i in "${!options[@]}"; do
            if [ "$i" -eq $selected ]; then
                echo "> ${options[$i]}"
            else
                echo "  ${options[$i]}"
            fi
        done

        last_selected=$selected

        # Read user input
        read -rsn1 key
        case $key in
            $'\x1b') # ESC sequence
                read -rsn2 -t 0.1 key
                case $key in
                    '[A') # Up arrow
                        ((selected--))
                        if [ $selected -lt 0 ]; then
                            selected=$((num_options - 1))
                        fi
                        ;;
                    '[B') # Down arrow
                        ((selected++))
                        if [ $selected -ge $num_options ]; then
                            selected=0
                        fi
                        ;;
                esac
                ;;
            '') # Enter key
                break
                ;;
        esac
    done

    return $selected
}

GoXLRMini(){
clear
    sudo pacman -S --noconfirm --needed base-devel git
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
    cd ..
    rm -rf yay

    yay -S --sudoloop --noconfirm goxlr-utility
}

dualGPU(){
clear

    # Dual GPU setup (AMD + NVIDIA)
    if lspci | grep -i 'vga' | grep -qi 'Radeon' && lspci | grep -i 'vga' | grep -qi 'nvidia'; then
        echo "Dual GPU setup detected (AMD + NVIDIA). Setting up quickpassthrough..."
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

    GoXLRMini
    dualGPU
