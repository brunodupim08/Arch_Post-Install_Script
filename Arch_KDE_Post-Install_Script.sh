#!/usr/bin/env bash

#-----------------------------------------------------------------#

# Global variable for Arch Linux repository programs
arch_programs=(
    "packagekit-qt5"
    "yakuake"
    "okular"
    "unrar"
    "spectacle"
    "gwenview"
    "partitionmanager"
    "kcalc"
    "plank"
    "btop"
    "micro"
    "neofetch"
    "timeshift"
    "ufw"
)

# Global variable for AUR Arch Linux repository programs
aur_programs=(
    "auto-cpufreq"
    "caffeine-ng"
    "deemix-gui-git"
    "jellyfin"
)

# Global variable for Flatpak programs
flatpak_programs=(
    "com.belmoussaoui.Authenticator"
    "com.belmoussaoui.Decoder"
    "com.bitwarden.desktop"
    "com.discordapp.Discord"
    "com.github.tchx84.Flatseal"
    "com.github.unrud.VideoDownloader"
    "com.github.wwmm.easyeffects"
    "com.github.zocker_160.SyncThingy"
    "com.google.Chrome"
    "com.obsproject.Studio"
    "dev.geopjr.Collision"
    "io.bassi.Amberol"
    "io.github.amit9838.weather"
    "io.github.appoutlet.GameOutlet"
    "io.github.giantpinkrobots.flatsweep"
    "io.github.seadve.Mousai"
    "md.obsidian.Obsidian"
    "net.agalwood.Motrix"
    "net.pcsx2.PCSX2"
    "org.kde.kamoso"
    "org.libretro.RetroArch"
    "org.mozilla.Thunderbird"
    "org.ppsspp.PPSSPP"
    "org.qbittorrent.qBittorrent"
    "org.videolan.VLC"
)

# Variable for programs/services to be enabled with systemctl
systemctl_programs=(
    "ufw"
    "cronie"
    "bluetooth"
    "auto-cpufreq"
    "jellyfin"
)

#-------------------------------------------------------------------#

# Variables for NVIDIA programs
nvidia_aur=(
    "optimus-manager"
    "optimus-manager-qt"
    "bbswitch"
)
nvidia_arch=(
    "nvidia"
    "nvidia-utils"
    "nvidia-settings"
    "lib32-nvidia-utils"
    "cuda"
    "opencl-nvidia"
    "lib32-opencl-nvidia"
    "nvidia-prime"
    "nvtop"
)

#-------------------------------------------------------------------#

version="1.0"

# Function to check for superuser privileges
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "This script must be run as root."
        exit 1
    fi
}

# Function to display the menu options
show_menu() {
    clear
    echo "Arch KDE Post-Install Script - Version $version"
    echo "Author: https://github.com/brunodupim08"
    echo "-------------------------------------------------"
    echo "1. Install Arch Linux programs"
    echo "2. Install AUR programs with yay"
    echo "3. Install Flatpak programs"
    echo "4. Install NVIDIA drivers and related programs"
    echo "5. Enable and start programs/services"
    echo "6. Update system and clean cache"
    echo "7. Exit"
    echo "-------------------------------------------------"
}

# Function to install Arch Linux programs
install_arch_programs() {
    echo "Installing Arch Linux programs..."
    programs_to_install=()

    for program in "${arch_programs[@]}"; do
        if ! pacman -Q "$program" &>/dev/null; then
            programs_to_install+=("$program")
        else
            echo "$program is already installed."
        fi
    done

    if [ ${#programs_to_install[@]} -gt 0 ]; then
        pacman -S --noconfirm "${programs_to_install[@]}"
        echo "Installation of Arch Linux programs completed."
    else
        echo "No programs need to be installed."
    fi
}

# Function to install Yay
install_yay() {
    if ! command -v yay &>/dev/null; then
        if ! command -v git &>/dev/null; then
            echo "Installing git..."
            pacman -S --noconfirm git
            echo "Git installation completed."
        fi
        echo "Installing Yay..."
        sudo -u $SUDO_USER git clone https://aur.archlinux.org/yay.git /tmp/yay
        sudo -u $SUDO_USER bash -c "cd /tmp/yay && makepkg -si --noconfirm"
        rm -rf /tmp/yay
        echo "Yay installation completed."
    fi
}

# Function to install AUR programs with yay
install_aur_programs_with_yay() {
    echo "Installing AUR programs with yay..."
    install_yay

    # Create an array to store the AUR programs that need to be installed
    aur_programs_to_install=()

    for program in "${aur_programs[@]}"; do
        if ! sudo -u $SUDO_USER yay -Q "$program" &>/dev/null; then
            aur_programs_to_install+=("$program")
        else
            echo "$program is already installed."
        fi
    done

    # Check if there are AUR programs to install
    if [ ${#aur_programs_to_install[@]} -gt 0 ]; then
        # Install all AUR programs in a single command
        sudo -u $SUDO_USER yay -S --noconfirm "${aur_programs_to_install[@]}"
    else
        echo "No AUR programs need to be installed."
    fi

    echo "Installation of AUR programs with yay completed."
}

# Function to install Flatpak programs
install_flatpak_programs() {
    if ! command -v flatpak &>/dev/null; then
        pacman -S --noconfirm flatpak
    fi
    echo "Installing Flatpak programs..."

    # Create an array to store the Flatpak programs that need to be installed
    flatpak_programs_to_install=()

    for program in "${flatpak_programs[@]}"; do
        if ! flatpak list | grep -q "$program"; then
            flatpak_programs_to_install+=("$program")
        else
            echo "$program is already installed."
        fi
    done

    # Check if there are Flatpak programs to install
    if [ ${#flatpak_programs_to_install[@]} -gt 0 ]; then
        # Install all Flatpak programs in a single command
        flatpak install -y "${flatpak_programs_to_install[@]}"
    else
        echo "No Flatpak programs need to be installed."
    fi

    echo "Installation of Flatpak programs completed."
}


# Function to install NVIDIA drivers and related programs
install_nvidia_drivers_and_programs() {
    # Check if the multilib repository is enabled
    if ! grep -qE '^\[multilib\]$' /etc/pacman.conf; then
        echo "The multilib repository is not enabled in /etc/pacman.conf."
        echo "Please enable it manually, as it contains necessary packages for Nvidia drivers and related programs, and then rerun this script."
        return
    fi

    # Update the system
    pacman -Syu --noconfirm

    install_yay

    echo "Checking if NVIDIA drivers and related programs are already installed..."

    # Create separate arrays to store Arch Linux and AUR programs that need to be installed
    arch_to_install=()
    aur_to_install=()

    for program in "${nvidia_arch[@]}"; do
        if ! pacman -Q "$program" &>/dev/null; then
            arch_to_install+=("$program")
        fi
    done

    for program in "${nvidia_aur[@]}"; do
        if ! sudo -u $SUDO_USER yay -Q "$program" &>/dev/null; then
            aur_to_install+=("$program")
        fi
    done

    if [[ ${#arch_to_install[@]} -gt 0 ]]; then
        echo "Installing NVIDIA drivers and related Arch Linux programs..."
        sudo pacman -S --noconfirm "${arch_to_install[@]}"
        echo "Installation of NVIDIA drivers and related Arch Linux programs completed."
    else
        echo "All Arch Linux programs are already installed."
    fi

    if [[ ${#aur_to_install[@]} -gt 0 ]]; then
        echo "Installing NVIDIA-related AUR programs..."
        sudo -u $SUDO_USER yay -S --noconfirm "${aur_to_install[@]}"
        echo "Installation of NVIDIA-related AUR programs completed."
    else
        echo "All AUR programs are already installed."
    fi

    # Inform the user about configuration and reboot
    echo "Remember to configure Optimus Manager to switch between GPUs (Intel/NVIDIA)."
    read -p "Do you want to restart the system now? (Y/n): " choice
    if [[ $choice =~ ^[Yy]*$ ]]; then
        reboot
    else
        echo "Please restart the system later to apply the settings."
    fi
}



# Function to enable and start programs/services with systemctl
enable_and_start_programs() {
    echo "Checking the state of programs/services with systemctl..."
    for program in "${systemctl_programs[@]}"; do
        enabled=$(systemctl is-enabled "$program")
        active=$(systemctl is-active "$program")

        if [ "$enabled" = "enabled" ] && [ "$active" = "active" ]; then
            echo "$program is already enabled and active."
        else
            echo "Status of $program: Enabled - $enabled, Active - $active"
            read -p "Do you want to enable and start $program? (Y/n): " choice
            if [[ $choice =~ ^[Yy]*$ ]]; then
                systemctl enable "$program"
                systemctl start "$program"
                echo "$program enabled and started."
            else
                echo "Option ignored for $program."
            fi
        fi
    done
    echo "Systemctl check completed."
}

# Function to update the system and clean the cache
update_and_clean() {
    echo "Updating the system and cleaning the cache..."

    # Update the system
    pacman -Syu --noconfirm

    # Check if the extra repository is necessary for 'paccache'
    if ! grep -qE '^\[extra\]$' /etc/pacman.conf; then
        echo "This function requires the extra repository to run 'paccache'."
        echo "Please enable it manually in /etc/pacman.conf and then run this script again."
        return
    fi

    # Check if the 'paccache' command is available
    if ! command -v paccache &>/dev/null; then
        echo "Installing paccache..."
        pacman -S --noconfirm pacman-contrib
        paccache -rk0
        echo "paccache installation completed."
    else
        paccache -rk0
        echo "paccache installation completed."
    fi

    echo "Update and cleanup completed."
}


# Main loop
check_root
while true; do
    show_menu
    read -p "Select an option (1-7): " choice
    case $choice in
        1) install_arch_programs ;;
        2) install_aur_programs_with_yay ;;
        3) install_flatpak_programs ;;
        4) install_nvidia_drivers_and_programs ;;
        5) enable_and_start_programs ;;
        6) update_and_clean ;;
        7) echo "Exiting."; exit ;;
        *) echo "Invalid option. Please try again." ;;
    esac
    read -p "Press Enter to continue..."
done
