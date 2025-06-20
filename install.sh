#!/bin/bash

set -eu # Exit on error and undefined variables

echo "##########################################"
echo "Be Careful this will override your Rice!! "
echo "##########################################"

if ! grep -q "\[xerolinux\]" /etc/pacman.conf; then
    echo
    echo "Adding The XeroLinux Repository..."
    echo "##################################"
    sleep 3
    echo -e '\n[xerolinux]\nSigLevel = Optional TrustAll\nServer = https://repos.xerolinux.xyz/$repo/$arch' | sudo tee -a /etc/pacman.conf
    sudo sed -i '/^\s*#\s*\[multilib\]/,/^$/ s/^#//' /etc/pacman.conf
    echo
    echo "XeroLinux Repository added!"
    echo
    echo "Updating Pacman Options..."
    echo
    sudo sed -i '/^# Misc options/,/ParallelDownloads = [0-9]*/c\# Misc options\nColor\nILoveCandy\nCheckSpace\n#DisableSandbox\nDisableDownloadTimeout\nParallelDownloads = 10' /etc/pacman.conf
    sudo sed -i "s/debug lto/!debug lto/g" /etc/makepkg.conf
     echo "Updated /etc/pacman.conf under # Misc options"
     echo
     echo "Updating Databases before proceeding..."
    echo "########################################"
    echo
     sudo pacman -Syy
    sleep 3
else
    echo
    echo "XeroLinux Repository already added."
    echo
    sleep 3
fi

echo
echo "Installing Necessary Packages"
echo "#############################"
echo

# Check if yay or paru is installed
if pacman -Qs yay &> /dev/null; then
  aur_helper="yay"
elif pacman -Qs paru &> /dev/null; then
  aur_helper="paru"
else
  echo "Neither yay nor paru is installed. Please select one to install:"
  echo
  echo "1. Install yay"
  echo "2. Install paru"
  echo
  read -p "Enter your choice (1/2): " choice

  case "$choice" in
    1)
      echo
      echo "Installing yay..."
      echo
      git clone https://aur.archlinux.org/yay.git
      cd yay
      makepkg -si --noconfirm --needed && yay -Y --devel --save && yay -Y --gendb
      cd ..
      rm -rf yay
      aur_helper="yay"
      ;;
    2)
      echo
      echo "Installing paru..."
      echo
      sudo pacman -S --noconfirm rust
      git clone https://aur.archlinux.org/paru.git
      cd paru
      makepkg -si --noconfirm --needed && paru --gendb
      cd ..
      rm -rf paru
      aur_helper="paru"
      ;;
    *)
      echo "Invalid choice. Exiting."
      exit 1
      ;;
  esac
fi

echo
echo "Selected AUR helper: $aur_helper"
echo

# Install packages using the detected AUR helper
$aur_helper -S --noconfirm --needed ttf-meslo-nerd-font-powerlevel10k  brightnessctl imagemagick kvantum unzip jq xmlstarlet fastfetch oh-my-posh-bin gtk-engine-murrine gtk-engines ttf-hack-nerd ttf-fira-code ttf-terminus-nerd noto-fonts-emoji ttf-meslo-nerd waybar noto-fonts-emoji waybar-module-pacman-updates-git wttrbar polkit-gnome hyprland hypridle hyprland-protocols hyprpaper hyprpicker hyprsunset pyprland hyprlock waypaper mako nwg-displays nwg-look nwg-menu nwg-dock-hyprland pacman-contrib rofi-wayland grim slurp swaybg kitty kitty-shell-integration kitty-terminfo xdg-desktop-portal-hyprland xdg-user-dirs-gtk power-profiles-daemon kvantum uwsm ttf-ubuntu-nerd mako qt5ct qt6ct qt5-wayland qt6-wayland thunar thunar-archive-plugin thunar-media-tags-plugin thunar-shares-plugin thunar-vcs-plugin thunar-volman satty swaync wlogout pamixer pavucontrol nm-connection-editor tela-circle-icon-theme-purple openssh falkon meld sddm gedit xlapit-cli kde-wallpapers gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd tumbler nano neovim-qt fwupd gnome-firmware blueman gnome-disk-utility flatseal yad file-roller networkmanager

sudo systemctl enable sddm sshd power-profiles-daemon bluetooth NetworkManager
sleep 2
echo

echo "Creating Backup & Applying new Rice, hold on..."
echo "###############################################"

cp -Rf ~/.config ~/.config-backup-$(date +%Y.%m.%d-%H.%M.%S) && cp -Rf Configs/Home/. ~
sudo cp -Rf Configs/System/. / && sudo cp -Rf Configs/Home/. /root/
mkdir -p ~/Satty

sleep 2
echo

echo "Adding Fastfetch to your shell configuration"
echo

# Function to add fastfetch to a shell configuration file
add_fastfetch() {
  local shell_rc="$1"
  if ! grep -Fxq 'fastfetch' "$HOME/$shell_rc"; then
    echo '' >> "$HOME/$shell_rc"
    echo 'fastfetch --config ~/.config/hypr/fastfetch/hyprfetch.jsonc' >> "$HOME/$shell_rc"
    echo
    echo "fastfetch has been added to your $shell_rc and will run on Terminal launch."
  else
    echo "fastfetch is already set to run on Terminal launch in $shell_rc."
  fi
}

# Detect the current shell
current_shell=$(basename "$SHELL")

# Prompt the user
read -p "Do you want to enable fastfetch to run on Terminal launch? (y/n): " response

case "$response" in
  [yY])
    if [ "$current_shell" = "zsh" ]; then
      add_fastfetch ".zshrc"
    elif [ "$current_shell" = "bash" ]; then
      add_fastfetch ".bashrc"
    else
      echo "Unsupported shell: $current_shell"
    fi
    ;;
  [nN])
    echo "fastfetch will not be added to your shell configuration."
    ;;
  *)
    echo "Invalid response. Please enter y or n."
    ;;
esac

sleep 2
echo
echo "Injecting OMP to .bashrc"

# Define the lines to be added
line1='# Oh-My-Posh Config'
line2='eval "$(oh-my-posh init bash --config $HOME/.config/hypr/ohmyposh/hyprxero.omp.json)"'

# Define the .bashrc file
bashrc_file="$HOME/.bashrc"

# Function to add lines if not already present
add_lines() {
  if ! grep -qxF "$line1" "$bashrc_file"; then
    echo "" >> "$bashrc_file" # Add an empty line before line1
    echo "$line1" >> "$bashrc_file"
  fi
  if ! grep -qxF "$line2" "$bashrc_file"; then
    echo "$line2" >> "$bashrc_file"
    echo "" >> "$bashrc_file" # Add an empty line after line2
  fi
}

# Run the function to add lines
add_lines

echo "Oh-My-Posh injection complete."
sleep 3
echo

echo "Applying Grub Theme...."
echo "#######################"

# Check if GRUB is installed
if [ -d "/boot/grub" ]; then
    echo "GRUB detected. Proceeding with theme installation..."

    # Clone the repository and install the theme
    sudo ./Grub.sh
    sudo sed -i "s/GRUB_GFXMODE=*.*/GRUB_GFXMODE=1920x1080x32/g" /etc/default/grub
    sudo grub-mkconfig -o /boot/grub/grub.cfg
else
    echo "GRUB not detected. Skipping theme installation."
fi
sleep 2
echo

echo "Installing Layan Theme"
echo "######################"
echo

if git clone https://github.com/vinceliuice/Layan-kde.git; then
  cd Layan-kde/ && sh install.sh
  cd ~ && rm -Rf Layan-kde/
else
  echo "Failed to clone Layan-kde theme"
  exit 1
fi

sleep 2
echo

echo "Installing & Applying GTK4 Theme "
echo "#################################"

# Check if ~/.themes directory exists, if not create it
if [ ! -d "$HOME/.themes" ]; then
  mkdir -p "$HOME/.themes"
  echo "Created ~/.themes directory"
fi

cd ~ && git clone https://github.com/vinceliuice/Layan-gtk-theme.git && cd Layan-gtk-theme/ && sh install.sh -l -c dark -d $HOME/.themes
cd ~ && rm -Rf Layan-gtk-theme/
echo
echo "Applying HyprXero SDDM theme"
sleep 3
if [ -f /etc/sddm.conf ]; then
    # Replace the value after Current= with HyprSDDM (in the [Theme] section)
    sudo sed -i '/^\[Theme\]/,/^\[/{s/^Current=.*/Current=HyprSDDM/}' /etc/sddm.conf
    # If Current= is not found in the [Theme] section, append it under [Theme]
    grep -q '^\[Theme\]' /etc/sddm.conf && grep -q '^Current=' /etc/sddm.conf || sudo sed -i '/^\[Theme\]/a Current=HyprSDDM' /etc/sddm.conf
else
    # Create the file with the required content
   printf '[Theme]\nCurrent=HyprSDDM\n' | sudo tee /etc/sddm.conf > /dev/null
fi

cd ~ && rm -rf HyprXero-git/

xdg-user-dirs-gtk-update

echo
echo "Plz Reboot To Apply Settings..."
echo "###############################"
