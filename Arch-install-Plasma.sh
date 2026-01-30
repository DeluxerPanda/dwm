#!/bin/bash

# Redirect stdout and stderr to archsetup.txt and still output to console
exec > >(tee -i archsetup.txt)
exec 2>&1
export MSIBORD=$(cat /sys/class/dmi/id/board_vendor 2>/dev/null)
loadkeys sv-latin1
echo -ne "
-------------------------------------------------------------------------

 █████╗ ██████╗  ██████╗██╗  ██╗    ██████╗ ███████╗██╗     ██╗   ██╗██╗  ██╗
██╔══██╗██╔══██╗██╔════╝██║  ██║    ██╔══██╗██╔════╝██║     ██║   ██║╚██╗██╔╝
███████║██████╔╝██║     ███████║    ██║  ██║█████╗  ██║     ██║   ██║ ╚███╔╝ 
██╔══██║██╔══██╗██║     ██╔══██║    ██║  ██║██╔══╝  ██║     ██║   ██║ ██╔██╗ 
██║  ██║██║  ██║╚██████╗██║  ██║    ██████╔╝███████╗███████╗╚██████╔╝██╔╝ ██╗
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚═════╝ ╚══════╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝
                                                                             
-------------------------------------------------------------------------
"
if [ ! -f /usr/bin/pacstrap ]; then
    echo "Det här skriptet måste köras från en Arch Linux ISO-miljö."
    exit 1
fi

root_check() {
    if [[ "$(id -u)" != "0" ]]; then
        echo -ne "FEL! Det här skriptet måste köras under användaren 'root'.!\n"
        exit 1
    fi
}

docker_check() {
    if awk -F/ '$2 == "docker"' /proc/self/cgroup | read -r; then
        echo -ne "FEL! Docker-containern stöds inte\n"
        exit 1
    elif [[ -f /.dockerenv ]]; then
        echo -ne "FEL! Docker-containern stöds inte\n"
        exit 1
    fi
}

arch_check() {
    if [[ ! -e /etc/arch-release ]]; then
        echo -ne "FEL! Det här skriptet måste köras i Arch Linux!\n"
        exit 1
    fi
}

pacman_check() {
    if [[ -f /var/lib/pacman/db.lck ]]; then
        echo "FEL! Pacman är blockerad."
        echo -ne "Om den inte körs ta bort /var/lib/pacman/db.lck.\n"
        exit 1
    fi
}

background_checks() {
    root_check
    arch_check
    pacman_check
    docker_check
}

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
            echo "Välj ett alternativ med piltangenterna och Enter:"
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

# @description Displays ArchTitus logo
# @noargs
logo () {
# This will be shown on every set as user is progressing
echo -ne "
-------------------------------------------------------------------------

 █████╗ ██████╗  ██████╗██╗  ██╗    ██████╗ ███████╗██╗     ██╗   ██╗██╗  ██╗
██╔══██╗██╔══██╗██╔════╝██║  ██║    ██╔══██╗██╔════╝██║     ██║   ██║╚██╗██╔╝
███████║██████╔╝██║     ███████║    ██║  ██║█████╗  ██║     ██║   ██║ ╚███╔╝ 
██╔══██║██╔══██╗██║     ██╔══██║    ██║  ██║██╔══╝  ██║     ██║   ██║ ██╔██╗ 
██║  ██║██║  ██║╚██████╗██║  ██║    ██████╔╝███████╗███████╗╚██████╔╝██╔╝ ██╗
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚═════╝ ╚══════╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝
                                                                                                                                                                     
-------------------------------------------------------------------------
"
}

# @description Choose whether drive is SSD or not.
drivessd () {
    echo -ne "
    Är detta en solid state-disk (SSD) eller hårddisk (HDD)?
    "

    options=("SSD" "HDD")
    select_option "${options[@]}"

    case $? in
        0)
        export MOUNT_OPTIONS="noatime,compress=zstd,ssd,commit=120";;
        1)
        export MOUNT_OPTIONS="noatime,compress=zstd,commit=120";;
        *) echo "Fel alternativ. Försök igen."; drivessd;;
    esac
}

# @description Disk selection for drive to be used with installation.
diskpart () {
echo -ne "
------------------------------------------------------------------------
    DETTA FORMATERAR OCH TAR BORT ALL DATA PÅ DISKEN 
    Se till att du vet vad du gör eftersom
    efter att du formaterat din disk finns det inget sätt att få tillbaka data 
    *****SÄKERHETSSKOPIERA DINA DATA INNAN DU FORTSÄTTER***** 
    ***JAG ÄR INTE ANSVARIG FÖR NÅGON DATAFÖRUST***
------------------------------------------------------------------------

"

    #Loop through selection if non-viable device (mmcblkXbootY, mmcblkXrpbm, etc) is selected
       while true
       do
       PS3='
       Välj vilken disk du vill installera på: '
       mapfile -t options < <(lsblk -n --output TYPE,KNAME,SIZE | awk '$1=="disk"{print "/dev/"$2"|"$3}')

       select_option "${options[@]}"
       disk=${options[$?]%|*}
       if [[ ! "${disk%|*}" =~  ^/dev/mmcblk[0-9]+[a-z]+[0-9]? ]]
          then
                break
          fi
          echo -e "\n${disk%|*} är inte en fungerande installationsenhet \n"
    done

    echo -e "\n${disk%|*} selected \n"
        export DISK=${disk%|*}

    drivessd
}

# @description Gather username and password to be used for installation.
userinfo () {
    # Loop through user input until the user gives a valid username
    while true
    do
            read -r -p "Ange användarnamn: " username
            if [[ "${username,,}" =~ ^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$ ]]
            then
                    break
            fi
            echo "ogiltigt användarnamn."
    done
    export USERNAME=$username

    while true
    do
        read -rs -p "Ange lösenord: " PASSWORD1
        echo -ne "\n"
        read -rs -p "Ange lösenord igen: " PASSWORD2
        echo -ne "\n"
        if [[ "$PASSWORD1" == "$PASSWORD2" ]]; then
            break
        else
            echo -ne "FEL! Lösenorden matchar inte. \n"
        fi
    done
    export PASSWORD=$PASSWORD1

     # Loop through user input until the user gives a valid hostname, but allow the user to force save
    while true
    do
            read -r -p "Namnge din dator: " name_of_machine
            # hostname regex (!!couldn't find spec for computer name!!)
            if [[ "${name_of_machine,,}" =~ ^[a-z][a-z0-9_.-]{0,62}[a-z0-9]$ ]]
            then
                    break
            fi
            # if validation fails allow the user to force saving of the hostname
            read -r -p "namnet verkar inte vara korrekt. Vill du fortfarande använda det?? (y/n)" force
            if [[ "${force,,}" = "y" ]]
            then
                    break
            fi
    done
    export NAME_OF_MACHINE=$name_of_machine
}
grubtheme () {
    echo -ne "  
    -----------------------------------------------------------------------
                        Välj ett grub tema                    
    -----------------------------------------------------------------------
    1) Cartoon Girl
    2) Aesthetic
    3) inget tema
    -----------------------------------------------------------------------
    "
    options=("Cartoon Girl" "Aesthetic" "inget tema")
    select_option "${options[@]}"
    case $? in
        0)
        export GRUB_THEME="CartoonGirl";;
        1)
        export GRUB_THEME="Aesthetic";;
        2)
        export GRUB_THEME="none";;
        *) echo "Fel alternativ. Försök igen."; grubtheme;;
    esac                
}

dualGPU_check () {
        echo -ne "  
    -----------------------------------------------------------------------
                        Välj huvud GPU                    
    -----------------------------------------------------------------------
    1) Radeon (AMD)
    2) NVIDIA
    -----------------------------------------------------------------------
    "
    if lspci | grep -E "NVIDIA|GeForce" >/dev/null && lspci | grep -E "Radeon" >/dev/null; then
    options=("Radeon (AMD)" "NVIDIA")
    select_option "${options[@]}"
    case $? in
        0)
        export DUALGPU="AMD";;
        1)
        export DUALGPU="NVIDIA";;
        *) echo "Fel alternativ. Försök igen."; dualGPU_check;;
    esac 
    fi
}

fastfetch_theme () {
        echo -ne "  
    -----------------------------------------------------------------------
                        Välj ett Fastfetch tema                    
    -----------------------------------------------------------------------
    1) Transgender Flagga
    2) Non-binary Flagga
    3) inget tema
    -----------------------------------------------------------------------
    "
    options=("Transgender Flag" "Nonbinary Flag" "inget tema")
    select_option "${options[@]}"
    case $? in
        0)
        export FASTFETCH="Transgender";;
        1)
        export FASTFETCH="Nonbinary";;
        2)
        export FASTFETCH="none";;
        *) echo "Fel alternativ. Försök igen."; fastfetch_theme;;
    esac
}

starship_theme () {
        echo -ne "  
    -----------------------------------------------------------------------
                        Välj ett Starship tema                    
    -----------------------------------------------------------------------
    1) Transgender
    2) Non-binary
    3) inget tema
    -----------------------------------------------------------------------
    "
    options=("Transgender Flag" "Nonbinary Flag" "inget tema")
    select_option "${options[@]}"
    case $? in
        0)
        export STARSHIP="Transgender";;
        1)
        export STARSHIP="Nonbinary";;
        2)
        export STARSHIP="none";;
        *) echo "Fel alternativ. Försök igen."; starship_theme;;
    esac
}

# Starting functions
background_checks
clear
logo
userinfo
clear
logo
grubtheme
clear
logo
fastfetch_theme
clear
logo
starship_theme
clear
logo
dualGPU_check
clear
logo
diskpart
clear
logo


timedatectl set-ntp true
pacman -Sy
pacman -S --noconfirm archlinux-keyring #update keyrings to latest to prevent packages failing to install
pacman -S --noconfirm --needed pacman-contrib
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
pacman -S --noconfirm --needed rsync grub

if [ ! -d "/mnt" ]; then
    mkdir /mnt
fi

pacman -S --noconfirm --needed gptfdisk btrfs-progs glibc
echo -ne "
-------------------------------------------------------------------------
                    Formaterar disk
-------------------------------------------------------------------------
"
umount -A --recursive /mnt # make sure everything is unmounted before we start
# disk prep
sgdisk -Z "${DISK}" # zap all on disk
sgdisk -a 2048 -o "${DISK}" # new gpt disk 2048 alignment

# create partitions
sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' "${DISK}" # partition 1 (BIOS Boot Partition)
sgdisk -n 2::+1GiB --typecode=2:ef00 --change-name=2:'EFIBOOT' "${DISK}" # partition 2 (UEFI Boot Partition)
sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' "${DISK}" # partition 3 (Root), default start, remaining
if [[ ! -d "/sys/firmware/efi" ]]; then # Checking for bios system
    sgdisk -A 1:set:2 "${DISK}"
fi
partprobe "${DISK}" # reread partition table to ensure it is correct

# make filesystems
echo -ne "
-------------------------------------------------------------------------
                    Skapar filsystem
-------------------------------------------------------------------------
"
# @description Creates the btrfs subvolumes.
createsubvolumes () {
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
}

# @description Mount all btrfs subvolumes after root has been mounted.
mountallsubvol () {
    mount -o "${MOUNT_OPTIONS}",subvol=@home "${partition3}" /mnt/home
}

# @description BTRFS subvolulme creation and mounting.
subvolumesetup () {
# create nonroot subvolumes
    createsubvolumes
# unmount root to remount with subvolume
    umount /mnt
# mount @ subvolume
    mount -o "${MOUNT_OPTIONS}",subvol=@ "${partition3}" /mnt
# make directories home, .snapshots, var, tmp
    mkdir -p /mnt/home
# mount subvolumes
    mountallsubvol
}

if [[ "${DISK}" =~ "nvme"|"mmcblk" ]]; then
    partition2=${DISK}p2
    partition3=${DISK}p3
else
    partition2=${DISK}2
    partition3=${DISK}3
fi

    mkfs.fat -F32 -n "EFIBOOT" "${partition2}"
    mkfs.btrfs -f "${partition3}"
    mount -t btrfs "${partition3}" /mnt
    subvolumesetup

BOOT_UUID=$(blkid -s UUID -o value "${partition2}")

sync
if ! mountpoint -q /mnt; then
    echo "FEL! Misslyckades med att montera ${partition3} till /mnt efter flera försök."
    exit 1
fi
mkdir -p /mnt/boot
mount -U "${BOOT_UUID}" /mnt/boot/

if ! grep -qs '/mnt' /proc/mounts; then
    echo "Enheten är inte monterad, kan inte fortsätta"
    echo "Omstart på 3 sekunder ..." && sleep 1
    echo "Omstart på 2 sekunder..." && sleep 1
    echo "Omstart på 1 sekunder ..." && sleep 1
    reboot now
fi

if [[ ! -d "/sys/firmware/efi" ]]; then
    pacstrap /mnt base base-devel linux linux-headers linux-firmware btrfs-progs --noconfirm --needed
else
    pacstrap /mnt base base-devel linux linux-headers linux-firmware efibootmgr btrfs-progs --noconfirm --needed
fi
echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

genfstab -U /mnt >> /mnt/etc/fstab
echo "
  Generated /etc/fstab:
"
cat /mnt/etc/fstab
echo -ne "
-------------------------------------------------------------------------
                    GRUB BIOS Bootloader Installation
-------------------------------------------------------------------------
"
if [[ ! -d "/sys/firmware/efi" ]]; then
    grub-install --boot-directory=/mnt/boot "${DISK}" --removable
fi
echo -ne "
-------------------------------------------------------------------------
                    Kontrollerar system med lågt minne <8GB
-------------------------------------------------------------------------
"
TOTAL_MEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[  $TOTAL_MEM -lt 8000000 ]]; then
    # Put swap into the actual system, not into RAM disk, otherwise there is no point in it, it'll cache RAM into RAM. So, /mnt/ everything.
    mkdir -p /mnt/opt/swap # make a dir that we can apply NOCOW to to make it btrfs-friendly.
    if findmnt -n -o FSTYPE /mnt | grep -q btrfs; then
        chattr +C /mnt/opt/swap # apply NOCOW, btrfs needs that.
    fi
    dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=2048 status=progress
    chmod 600 /mnt/opt/swap/swapfile # set permissions.
    chown root /mnt/opt/swap/swapfile
    mkswap /mnt/opt/swap/swapfile
    swapon /mnt/opt/swap/swapfile
    # The line below is written to /mnt/ but doesn't contain /mnt/, since it's just / for the system itself.
    echo "/opt/swap/swapfile    none    swap    sw    0    0" >> /mnt/etc/fstab # Add swap to fstab, so it KEEPS working after installation.
fi

gpu_type=$(lspci | grep -E "VGA|3D|Display")

arch-chroot /mnt /bin/bash <<EOF


#-------------------------------------------------------------------------
#                    Nätverksinställningar
#-------------------------------------------------------------------------

pacman -S --noconfirm --needed networkmanager
systemctl enable NetworkManager

pacman -S --noconfirm --needed pacman-contrib curl terminus-font
pacman -S --noconfirm --needed rsync grub arch-install-scripts git ntp wget

nc=$(grep -c ^"cpu cores" /proc/cpuinfo)

TOTAL_MEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[  $TOTAL_MEM -gt 8000000 ]]; then
sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$nc\"/g" /etc/makepkg.conf
sed -i "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T $nc -z -)/g" /etc/makepkg.conf
fi

#-------------------------------------------------------------------------
#                    Sätter upp språk
#-------------------------------------------------------------------------

sed -i 's/^#sv_SE.UTF-8 UTF-8/sv_SE.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
timedatectl --no-ask-password set-timezone Europe/Stockholm
timedatectl --no-ask-password set-ntp 1
localectl --no-ask-password set-locale LANG="sv_SE.UTF-8" LC_TIME="sv_SE.UTF-8"
ln -s /usr/share/zoneinfo/Europe/Stockholm /etc/localtime

# Set keymaps
loadkeys sv-latin1
echo "KEYMAP=sv-latin1" > /etc/vconsole.conf
echo "XKBLAYOUT=se" >> /etc/vconsole.conf

# Add sudo no password rights
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

#Add parallel downloading
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

#Set colors and enable the easter egg
sed -i 's/^#Color/Color\nILoveCandy/' /etc/pacman.conf

#Enable multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm --needed


#-------------------------------------------------------------------------
#                    Installerar Microcode
#-------------------------------------------------------------------------

# determine processor type and install microcode
if grep -q "GenuineIntel" /proc/cpuinfo; then
    echo "Installing Intel microcode"
    pacman -S --noconfirm --needed intel-ucode
elif grep -q "AuthenticAMD" /proc/cpuinfo; then
    echo "Installing AMD microcode"
    pacman -S --noconfirm --needed amd-ucode
else
    echo "Unable to determine CPU vendor. Skipping microcode installation."
fi


#-------------------------------------------------------------------------
#                    Installera grafikdrivrutiner
#-------------------------------------------------------------------------

# Graphics Drivers find and install
if [[ "$DUALGPU" == "AMD" ]]; then
    echo "Installing AMD drivers: xf86-video-amdgpu vulkan-radeon"
    pacman -S --noconfirm --needed xf86-video-amdgpu vulkan-radeon
    mkdir -p /etc/X11/xorg.conf.d/
    wget https://raw.githubusercontent.com/DeluxerPanda/Arch-scripts/main/config/X11/20-amdgpu.conf -O /etc/X11/xorg.conf.d/20-amdgpu.conf
elif echo "${gpu_type}" | grep -E "NVIDIA|GeForce"; then
    echo "Installing NVIDIA drivers: nvidia-open nvidia-open-dkms nvidia-settings nvidia-utils"
    pacman -S --noconfirm --needed nvidia-open nvidia-open-dkms nvidia-settings nvidia-utils
elif echo "${gpu_type}" | grep 'VGA' | grep -E "Radeon"; then
    echo "Installing AMD drivers: xf86-video-amdgpu vulkan-radeon"
    pacman -S --noconfirm --needed xf86-video-amdgpu vulkan-radeon
    mkdir -p /etc/X11/xorg.conf.d/
    wget https://raw.githubusercontent.com/DeluxerPanda/Arch-scripts/main/config/X11/20-amdgpu.conf -O /etc/X11/xorg.conf.d/20-amdgpu.conf
fi


#-------------------------------------------------------------------------
#                    Lägger till användare
#-------------------------------------------------------------------------

groupadd libvirt
useradd -m -G wheel,libvirt -s /bin/bash $USERNAME
echo "$USERNAME created, home directory created, added to wheel and libvirt group, default shell set to /bin/bash"
echo "$USERNAME:$PASSWORD" | chpasswd
echo "$USERNAME password set"
echo $NAME_OF_MACHINE > /etc/hostname

# Final Setup and Configurations
# GRUB EFI Bootloader Install & Check

if [[ -d "/sys/firmware/efi" ]]; then
    grub-install --efi-directory=/boot ${DISK} --removable
fi

#-------------------------------------------------------------------------
#              Skapa Grub-startmenyn
#-------------------------------------------------------------------------


# set kernel parameter for adding splash screen
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& splash /' /etc/default/grub

# remove quiet from grub cmdline
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)quiet\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1\2"/' /etc/default/grub

# Copy theme

if [ "$GRUB_THEME" == "CartoonGirl" ]; then
    mkdir -p "/boot/grub/themes/CartoonGirl"

    wget https://raw.githubusercontent.com/DeluxerPanda/Arch-scripts/refs/heads/main/config/Grub/CartoonGirl/theme.txt -O /boot/grub/themes/CartoonGirl/theme.txt
    wget https://raw.githubusercontent.com/DeluxerPanda/Arch-scripts/refs/heads/main/config/Grub/CartoonGirl/select_w.png -O /boot/grub/themes/CartoonGirl/select_w.png
    wget https://raw.githubusercontent.com/DeluxerPanda/Arch-scripts/refs/heads/main/config/Grub/CartoonGirl/select_e.png -O /boot/grub/themes/CartoonGirl/select_e.png
    wget https://raw.githubusercontent.com/DeluxerPanda/Arch-scripts/refs/heads/main/config/Grub/CartoonGirl/select_c.png -O /boot/grub/themes/CartoonGirl/select_c.png
    wget https://raw.githubusercontent.com/DeluxerPanda/Arch-scripts/refs/heads/main/config/Grub/CartoonGirl/norwester_22.pf2 -O /boot/grub/themes/CartoonGirl/norwester_22.pf2
    wget https://raw.githubusercontent.com/DeluxerPanda/Arch-scripts/refs/heads/main/config/Grub/CartoonGirl/hackb_18.pf2 -O /boot/grub/themes/CartoonGirl/hackb_18.pf2
    wget https://raw.githubusercontent.com/DeluxerPanda/Arch-scripts/refs/heads/main/config/Grub/CartoonGirl/Cartoon_Girl.png -O /boot/grub/themes/CartoonGirl/Cartoon_Girl.png
    
    sed -i 's|^#GRUB_THEME=.*|GRUB_THEME="/boot/grub/themes/CartoonGirl/theme.txt"|' /etc/default/grub

elif [ "$GRUB_THEME" == "Aesthetic" ]; then
    mkdir -p "/boot/grub/themes/Aesthetic"

    wget -p https://raw.githubusercontent.com/DeluxerPanda/Arch-scripts/refs/heads/main/config/Grub/Aesthetic/theme.txt -O /boot/grub/themes/Aesthetic/theme.txt
    wget -p https://raw.githubusercontent.com/DeluxerPanda/Arch-scripts/refs/heads/main/config/Grub/Aesthetic/select_w.png -O /boot/grub/themes/Aesthetic/select_w.png
    wget -p https://raw.githubusercontent.com/DeluxerPanda/Arch-scripts/refs/heads/main/config/Grub/Aesthetic/select_e.png -O /boot/grub/themes/Aesthetic/select_e.png
    wget -p https://raw.githubusercontent.com/DeluxerPanda/Arch-scripts/refs/heads/main/config/Grub/Aesthetic/select_c.png -O /boot/grub/themes/Aesthetic/select_c.png
    wget -p https://raw.githubusercontent.com/DeluxerPanda/Arch-scripts/refs/heads/main/config/Grub/Aesthetic/hackb_18.pf2 -O /boot/grub/themes/Aesthetic/hackb_18.pf2
    wget -p https://raw.githubusercontent.com/DeluxerPanda/Arch-scripts/refs/heads/main/config/Grub/Aesthetic/Aesthetic.png -O /boot/grub/themes/Aesthetic/Aesthetic.png
    
    sed -i 's|^#GRUB_THEME=.*|GRUB_THEME="/boot/grub/themes/Aesthetic/theme.txt"|' /etc/default/grub
fi

    sed -i '/^GRUB_TIMEOUT=/c\GRUB_TIMEOUT=30' /etc/default/grub

echo -e "Updating grub..."

    grub-mkconfig -o /boot/grub/grub.cfg

    mkinitcpio -P

if [[ "$MSIBORD" == *"MSI"* || "$MSIBORD" == *"Micro-Star"* ]]; then
    mkdir -p /boot/EFI/Microsoft/Boot/
    cp /boot/EFI/BOOT/BOOTX64.EFI /boot/EFI/Microsoft/Boot/bootmgfw.efi
fi

    echo -e "All set!"



#-------------------------------------------------------------------------
#                    Aktivera viktiga tjänster
#-------------------------------------------------------------------------

ntpd -qg
systemctl enable ntpd.service
echo "  NTP enabled"
systemctl disable dhcpcd.service
echo "  DHCP disabled"
systemctl enable NetworkManager.service
echo "  NetworkManager enabled"
systemctl enable reflector.timer
echo "  Reflector enabled"


#-------------------------------------------------------------------------
#                    Installation av skrivbordsmiljö och grundläggande paket
#-------------------------------------------------------------------------

pacman -Sy --noconfirm
pacman -S --needed --noconfirm kdeconnect starship bash-completion bat fastfetch btop pavucontrol mpv firefox feh plasma sddm konsole kate dolphin ark nfs-utils nano usbutils gnome-keyring fuse ffmpeg flatpak steam ttf-jetbrains-mono-nerd noto-fonts-emoji gamescope

systemctl enable sddm.service
echo "  Sddm enabled"

wget https://raw.githubusercontent.com/DeluxerPanda/Arch-scripts/refs/heads/main/config/.bashrc -O /home/$USERNAME/.bashrc
chown $USERNAME:$USERNAME /home/$USERNAME/.bashrc

mkdir -p /home/$USERNAME/Desktop
wget https://raw.githubusercontent.com/DeluxerPanda/Arch-scripts/main/SetupConfigs.sh -O /home/$USERNAME/Desktop/SetupConfigs.sh
chown -R $USERNAME:$USERNAME /home/$USERNAME/Desktop
chmod +x /home/$USERNAME/Desktop/SetupConfigs.sh


if lsusb | grep -q "GoXLRMini"; then

    mkdir -p /home/$USERNAME/.config/autostart

    wget https://raw.githubusercontent.com/DeluxerPanda/Arch-scripts/main/scripts/GoXLR_loopback.sh -O /home/$USERNAME/.config/autostart/GoXLR_loopback.sh
    chmod +x /home/$USERNAME/.config/autostart/GoXLR_loopback.sh

    wget https://raw.githubusercontent.com/DeluxerPanda/Arch-scripts/main/config/autostart/GoXLR_loopback.desktop -O /home/$USERNAME/.config/autostart/GoXLR_loopback.desktop
    chmod 600 /home/$USERNAME/.config/autostart/GoXLR_loopback.desktop

    wget https://raw.githubusercontent.com/DeluxerPanda/Arch-scripts/main/config/autostart/GoXLR_daemon.desktop -O /home/$USERNAME/.config/autostart/GoXLR_daemon.desktop
    chmod 600 /home/$USERNAME/.config/autostart/GoXLR_daemon.desktop
fi

mkdir -p /home/$USERNAME/.config/fastfetch
if [ "$FASTFETCH" == "Transgender" ]; then
    wget https://raw.githubusercontent.com/DeluxerPanda/Arch-scripts/main/config/fastfetch/transgender/config.jsonc -O /home/$USERNAME/.config/fastfetch/config.jsonc
    wget https://raw.githubusercontent.com/DeluxerPanda/Arch-scripts/main/config/fastfetch/transgender/trans.txt -O /home/$USERNAME/.config/fastfetch/trans.txt
elif [ "$FASTFETCH" == "Nonbinary" ]; then
    wget https://raw.githubusercontent.com/DeluxerPanda/Arch-scripts/main/config/fastfetch/nonbinary/config.jsonc -O /home/$USERNAME/.config/fastfetch/config.jsonc
    wget https://raw.githubusercontent.com/DeluxerPanda/Arch-scripts/main/config/fastfetch/nonbinary/nonbinary.txt -O /home/$USERNAME/.config/fastfetch/nonbinary.txt
fi


if [ "$STARSHIP" == "Transgender" ]; then
    wget https://raw.githubusercontent.com/DeluxerPanda/Arch-scripts/main/config/starship/transgender/starship.toml -O /home/$USERNAME/.config/starship.toml
elif [ "$STARSHIP" == "Nonbinary" ]; then
    wget https://raw.githubusercontent.com/DeluxerPanda/Arch-scripts/main/config/starship/nonbinary/starship.toml -O /home/$USERNAME/.config/starship.toml
fi

chown -R $USERNAME:$USERNAME /home/$USERNAME/.config

#-------------------------------------------------------------------------
#                    Städa upp
#-------------------------------------------------------------------------

# Remove no password sudo rights
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
EOF
