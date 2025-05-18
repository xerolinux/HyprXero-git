#!/bin/bash

set -eu # Exit on error and undefined variables

echo "##########################################"
echo "Be Careful this will override your Rice!! "
echo "##########################################"
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
      echo "Installing yay..."
      echo
      git clone https://aur.archlinux.org/yay.git
      cd yay
      makepkg -si
      cd ..
      rm -rf yay
      aur_helper="yay"
      ;;
    2)
      echo "Installing paru..."
      echo
      sudo pacman -S --noconfirm rust
      git clone https://aur.archlinux.org/paru.git
      cd paru
      makepkg -si
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

echo "Selected AUR helper: $aur_helper"
echo

# Install packages using the detected AUR helper
$aur_helper -S --noconfirm --needed ttf-meslo-nerd-font-powerlevel10k imagemagick kvantum unzip jq xmlstarlet fastfetch oh-my-posh-bin gtk-engine-murrine gtk-engines ttf-hack-nerd ttf-fira-code kdeconnect ttf-terminus-nerd noto-fonts-emoji ttf-meslo-nerd waybar noto-fonts-emoji waybar-module-pacman-updates-git wttrbar hyprpolkitagent hyprland hypridle hyprland-protocols hyprpaper hyprpicker hyprsunset pyprland hyprlock waypaper mako nwg-displays nwg-look nwg-menu nwg-dock-hyprland pacman-contrib rofi grim slurp swaybg kitty kitty-shell-integration kitty-terminfo xdg-desktop-portal-hyprland xdg-user-dirs power-profiles-daemon kvantum ttf-ubuntu-nerd mako qt5ct qt6ct qt5-wayland qt6-wayland thunar thunar-archive-plugin thunar-media-tags-plugin thunar-shares-plugin thunar-vcs-plugin thunar-volman satty swaync wlogout pamixer pavucontrol nm-connection-editor tela-circle-icon-theme-purple openssh

sudo systemctl enable sddm sshd

sleep 2
echo

echo "Creating Backup & Applying new Rice, hold on..."
echo "###############################################"

cp -Rf ~/.config ~/.config-backup-$(date +%Y.%m.%d-%H.%M.%S) && cp -Rf Configs/Home/. ~
sudo cp -Rf Configs/System/. / && sudo cp -Rf Configs/Home/. /root/

sleep 2
echo

echo "Adding Fastfetch to your shell configuration"
echo

# Function to add fastfetch to a shell configuration file
add_fastfetch() {
  local shell_rc="$1"
  if ! grep -Fxq 'fastfetch' "$HOME/$shell_rc"; then
    echo '' >> "$HOME/$shell_rc"
    echo 'fastfetch' >> "$HOME/$shell_rc"
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
line2='eval "$(oh-my-posh init bash --config $HOME/.config/ohmyposh/distrous-xero-linux.omp.json)"'

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

echo "Applying HyprXero SDDM theme"
echo "############################"
echo
if [ -f /etc/sddm.conf ]; then
    # Replace the value after Current= with HyprSDDM (in the [Theme] section)
    sed -i '/^\[Theme\]/,/^\[/{s/^Current=.*/Current=HyprSDDM/}' /etc/sddm.conf
    # If Current= is not found in the [Theme] section, append it under [Theme]
    grep -q '^\[Theme\]' /etc/sddm.conf && grep -q '^Current=' /etc/sddm.conf || sed -i '/^\[Theme\]/a Current=HyprSDDM' /etc/sddm.conf
else
    # Create the file with the required content
   printf '[Theme]\nCurrent=HyprSDDM\n' | sudo tee /etc/sddm.conf > /dev/null
fi

echo
echo "Plz Reboot To Apply Settings..."
echo "###############################"
