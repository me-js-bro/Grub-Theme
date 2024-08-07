#!/bin/bash

# color defination
red="\e[1;31m"
green="\e[1;32m"
yellow="\e[1;33m"
blue="\e[1;34m"
magenta="\e[1;1;35m"
cyan="\e[1;36m"
orange="\x1b[38;5;214m"
end="\e[1;0m"

# texts
att="${orange} [ ATTENTION ] ${end}"
acc="${green} [ ACTION ] ${end}"
ok="${cyan} [ OK ] ${end}"
note="${blue} [ NOTE ] ${end}"
qus="${yellow} [ QUESTION ] ${end}"
err="${red} [ ERROR ] ${end}"

# Grub2 Theme
ROOT_UID=0
THEME_DIR="/usr/share/grub/themes"
THEME_NAME="Xenlism-Arch"

MAX_DELAY=20 # max dilay 20 seconds

# prompt message function
info() {
    local action="$1"
    local msg="$2"

    case $action in
        at) printf "\n$att \n  ${orange}$msg${end}\n"
        ;;
        ac) printf "\n$acc \n  ${green}$msg${end}\n"
        ;;
        ok) printf "$ok \n  ${cyan}$msg${end}\n\n"
        ;;
        nt) printf "$note \n  ${blue}$msg${end}\n"
        ;;
        qs) printf "\n$qus \n  ${yellow}$msg${end}\n"
        ;;
        er) printf "\n$err \n  ${red}$msg${end}\n"
        ;;
        *) echo ""
        ;;
    esac
}

# directories
present_dir="$(dirname $(realpath "$0"))"
log="$present_dir/install.log"
touch "$log"

GRUB_CONFIG="/etc/default/grub"
LINE="GRUB_DISABLE_OS_PROBER=false"

package_manager=$(command -v paru || command -v yay)

# Welcome message

# Check command avalibility
function has_command() {
  command -v $1 > /dev/null
}

# install some packages
if ! "$package_manager" -Qi update-grub &> /dev/null; then
    info ac "Installing 'update-grub'"
    "$package_manager" -S --noconfirm update-grub 2>&1 | tee -a "$log"
fi


# Create themes directory if not exists
info at "Checking for the existence of themes directory..."
[[ -d "${THEME_DIR}/${THEME_NAME}" ]] && sudo rm -rf "${THEME_DIR}/${THEME_NAME}" 2>&1 | tee -a "$log"
sudo mkdir -p "${THEME_DIR}/${THEME_NAME}" 2>&1 | tee -a "$log"

# Copy theme
info ac "Installing ${THEME_NAME} theme..."

sudo cp -a "${present_dir}/${THEME_NAME}/." "${THEME_DIR}/${THEME_NAME}" 2>&1 | tee -a "$log"

# Set theme
info nt "Setting ${THEME_NAME} as default..."

# Backup grub config
sudo cp -an /etc/default/grub /etc/default/grub.bak 2>&1 | tee -a "$log"

if sudo grep "GRUB_THEME=" /etc/default/grub 2>&1 >/dev/null; then
    sudo sed -i '/GRUB_THEME=/d' /etc/default/grub 2>&1 | tee -a "$log"
fi

echo "GRUB_THEME=\"${THEME_DIR}/${THEME_NAME}/theme.txt\"" | sudo tee -a /etc/default/grub 2>&1 | tee -a "$log"

# Check if the line is commented
if grep -q "^#${LINE}" "$GRUB_CONFIG"; then
    # Uncomment the line
    sudo sed -i "s/^#${LINE}/${LINE}/" "$GRUB_CONFIG" 2>&1 | tee -a "$log"
    info ok "Uncommented the line: ${LINE}"
else
    info at "The line is already uncommented"
fi

# Update grub config
info at "Updating grub config..."
if has_command update-grub; then
    sudo update-grub 2>&1 | tee -a "$log"
elif has_command grub-mkconfig; then
    sudo grub-mkconfig -o /boot/grub/grub.cfg 2>&1 | tee -a "$log"
elif has_command grub2-mkconfig; then
    if has_command zypper; then
      sudo grub2-mkconfig -o /boot/grub2/grub.cfg 2>&1 | tee -a "$log"
    elif has_command dnf; then
      sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg 2>&1 | tee -a "$log"
    fi
fi

# Success message
if [[ $? -eq 0 ]]; then
    info ok "Installation completed..." 2>&1 | tee -a >(sed 's/\x1B\[[0-9;]*[JKmsu]//g' >> "$log")
else 
    info er "Sorry, could not set the ${THEME_NAME}..." 2>&1 | tee -a >(sed 's/\x1B\[[0-9;]*[JKmsu]//g' >> "$log")
    exit 1
fi