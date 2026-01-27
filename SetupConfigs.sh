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

SetupConfig() {
clear
    export work_dir="$(pwd)"

    if lsusb | grep -q "GoXLRMini"; then
        yay -S  --sudoloop --needed --noconfirm goxlr-utility

mkdir -p ~/.config/autostart

tee ~/.config/autostart/GoXLR_loopback.desktop > /dev/null <<'EOF'
[Desktop Entry]
Exec=~/scripts/GoXLR_loopback.sh
Icon=application-x-shellscript
Name=GoXLR_loopback.sh
Type=Application
X-KDE-AutostartScript=true
EOF
sudo chmod 600 ~/.config/autostart/GoXLR_loopback.desktop

tee ~/.config/autostart/GoXLR_daemon.desktop > /dev/null <<'EOF'
[Desktop Entry]
Exec=goxlr-daemon
Icon=application-x-shellscript
Name=goxlr-daemon
Type=Application
X-KDE-AutostartScript=true
EOF
sudo chmod 600 ~/.config/autostart/GoXLR_daemon.desktop
    fi
}

dualGPU(){
clear

    # Dual GPU setup (AMD + NVIDIA)
    if lspci | grep -i 'vga' | grep -qi 'amd' && lspci | grep -i 'vga' | grep -qi 'nvidia'; then

        echo -ne "
    Vill du konfigurera AMD GPU som primär?
    "

    options=("Ja" "Nej")
    select_option "${options[@]}"

    case $? in
        0)
            local AMD_main_GPU="yes";;
        1)
           local AMD_main_GPU="no";;
        *) echo "Wrong option. Try again"; drivessd;;
    esac


        if [[ "$AMD_main_GPU" == "yes" ]]; then
        sudo mkdir -p /etc/X11/xorg.conf.d

sudo tee /etc/X11/xorg.conf.d/20-amdgpu.conf > /dev/null <<'EOF'
Section "Device"
	Identifier "AMD"
	Driver "amdgpu"
	Option "TearFree" "true"
EndSection
EOF
        fi

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



    SetupConfig
    dualGPU
