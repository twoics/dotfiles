#!/bin/bash
#    ____         __       ____               __     __
#   /  _/__  ___ / /____ _/ / / __ _____  ___/ /__ _/ /____ ___
#  _/ // _ \(_-</ __/ _ `/ / / / // / _ \/ _  / _ `/ __/ -_|_-<
# /___/_//_/___/\__/\_,_/_/_/  \_,_/ .__/\_,_/\_,_/\__/\__/___/
#                                 /_/
#

# Check if command exists
_checkCommandExists() {
    cmd="$1"
    if ! command -v "$cmd" >/dev/null; then
        echo 1
        return
    fi
    echo 0
    return
}

_isInstalled() {
    package="$1"
    case $install_platform in
        arch)
            check="$($aur_helper -Qs --color always "${package}" | grep "local" | grep "${package} ")"
            ;;
        fedora)
            check="$(dnf repoquery --quiet --installed ""${package}*"")"
            ;;
        *) ;;
    esac

    if [ -n "${check}" ]; then
        echo 0 #'0' means 'true' in Bash
        return #true
    fi
    echo 1 #'1' means 'false' in Bash
    return #false
}

# ------------------------------------------------------
# Confirm Start
# ------------------------------------------------------

sleep 1
clear
figlet -f smslant "Updates"
echo

if gum confirm "DO YOU WANT TO START THE UPDATE NOW?"; then
    echo
    echo ":: Update started."
elif [ $? -eq 130 ]; then
    exit 130
else
    echo
    echo ":: Update canceled."
    exit
fi

# ----------------------------------------------------- 
# Install update
# ----------------------------------------------------- 

# Arch
if [[ $(_checkCommandExists "pacman") == 0 ]]; then
    aur_helper="$(cat ~/.config/ml4w/settings/aur.sh)"

    if [[ $(_isInstalled "timeshift") == "0" ]]; then
        echo
        if gum confirm "DO YOU WANT TO CREATE A SNAPSHOT?"; then
            echo
            c=$(gum input --placeholder "Enter a comment for the snapshot...")
            sudo timeshift --create --comments "$c"
            sudo timeshift --list
            sudo grub-mkconfig -o /boot/grub/grub.cfg
            echo ":: DONE. Snapshot $c created!"
            echo
        elif [ $? -eq 130 ]; then
            echo ":: Snapshot skipped."
            exit 130
        else
            echo ":: Snapshot skipped."
        fi
        echo
    fi

    $aur_helper

    if [[ $(_isInstalled "flatpak") == "0" ]]; then
        flatpak update
    fi
# Fedora
elif [[ $(_checkCommandExists "dnf") == 0 ]]; then
    sudo dnf upgrade
    if [[ $(_isInstalled "flatpak") == "0" ]]; then
        flatpak update
    fi
else
    echo ":: ERROR - Platform not supported"
    echo "Press [ENTER] to close."
    read
fi

notify-send "Update complete"
echo
echo ":: Update complete"
echo
echo

pkill -RTMIN+1 waybar

echo "Press [ENTER] to close."
read
