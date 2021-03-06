#!/bin/bash
. setup/_shared.sh
# This bash script will set up (or update) your development environment for Ubuntu (v=>9.10)

scripts=""
apt_packages=""  # Installs all packages in a single transaction

if [[ $EUID -eq 0 ]]; then
  echo -e "\e[01;31mPlease do not use sudo to run this script!\e[00m" 2>&1
  exit 1
fi

echo -e "
---------------------------------
| Ubuntu Developer Setup Script |
---------------------------------\n"

# Prerequisites
# -------------------------------------
# Requires root permissions (requests password here)
sudo true

# '--all' flag installs everything
if [ "$1" = "--all" ]; then
  echo "== Setting up default environment..."
  scripts="packages dropbox skype keepass2 bashrc git_config
           gnome conky startup apt-install rvm rvm_hooks "
  prompt_for_git

# '--update' flag updates everything that doesn't require user input
elif [ "$1" = "--update" ]; then
  echo "== Running default update..."
  scripts="packages bashrc rvm_hooks gnome conky startup apt-install "

# If no flag given, ask user which scripts they would like to run.
else
  confirm_by_default "Git config" 'git_config'
  if [[ "$scripts" =~ "git_config" ]]; then prompt_for_git; fi # prompt for git user details

  confirm_by_default "Apt packages"                 'packages'
  confirm_by_default "Dropbox"                      'dropbox'
  confirm_by_default "Skype"                        'skype'
  confirm_by_default "Dotfiles (bashrc, etc.)"      'bashrc'
  confirm_by_default "SCM Breeze"                   'scm_breeze'
  confirm_by_default "Gnome themes and fonts"       'gnome'
  confirm_by_default "Conky (system stats)"         'conky'
  confirm_by_default "Chrome, terminal & editor on startup"  'startup'
  # Defines the point where script should install packages
  scripts+="apt-install "
  confirm_by_default "RVM (Ruby Version Manager)"   'rvm'
  confirm_by_default "RVM Hooks (symlink to current gemset)" 'rvm_hooks'
fi

scripts=`echo $scripts`  # Remove line-breaks
echo -e "\n===== Executing the following scripts:"
echo -e   "      [ $scripts ]\n"


# Include each configured script
# --------------------------------------------------------------
for script in $scripts; do
  if [[ "$script" =~ "apt-install" ]]; then
    # Update sources and install apt packages
    # --------------------------------------------------------------
    if ! [ -e "/tmp/dotfiles_apt_get_updated" ]; then
      echo "== Updating apt sources..."
      sudo apt-get update -qq
      touch "/tmp/dotfiles_apt_get_updated"
    fi

    echo "== Installing apt packages..."
    sudo apt-get install -ym $apt_packages | grep -v "is already the newest version"
    sudo apt-get autoremove -ym
  else
    . setup/$script.sh
  fi
done

# Restarting nautilus for dropbox and image resizer
nautilus -q


echo -e "\n===== Ubuntu development machine has been set up!\n"
echo -e "Further manual configuration may be needed:\n"
echo "    Synergy - Copy your synergy conf to '/etc/synergy.conf' & add to startup:"
echo "              synergys --config '/etc/synergy.conf'"
echo "    Dropbox Symlinks - Run './setup/dropbox_symlinks.sh' after you have set up your Dropbox account."
echo

