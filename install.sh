#!/bin/bash
#
##[ Welcome ]###################################################################
#      _       _    __ _ _
#   __| | ___ | |_ / _(_) | ___  ___
#  / _` |/ _ \| __| |_| | |/ _ \/ __|
# | (_| | (_) | |_|  _| | |  __/\__ \
#  \__,_|\___/ \__|_| |_|_|\___||___/
#
#  _           _        _ _       _   _                             _       _
# (_)_ __  ___| |_ __ _| | | __ _| |_(_) ___  _ __    ___  ___ _ __(_)_ __ | |_
# | | '_ \/ __| __/ _` | | |/ _` | __| |/ _ \| '_ \  / __|/ __| '__| | '_ \| __|
# | | | | \__ \ || (_| | | | (_| | |_| | (_) | | | | \__ \ (__| |  | | |_) | |_
# |_|_| |_|___/\__\__,_|_|_|\__,_|\__|_|\___/|_| |_| |___/\___|_|  |_| .__/ \__|
#                                                                    |_|
##[ install.sh ]################################################################
# This script creates symlinks from the home directory to any desired 
# dotfiles in ~/.dotfiles
################################################################################

# Before doing anything, check to determine if run as root/sudo.
#if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root/sudo." ; exit 1 ; fi

##[ Script Variables ]#########################################################
dir=~/.dotfiles                      # Dotfiles directory
backupdir=~/.dotfiles_backup         # Old dotfiles backup directory
binDir=~/bin                         # Bin folder for scripts and tools.
packageManagerInstall=sudo pacman -S # Distro specific package manager.

##[ Messages ]#################################################################
completed="Operation complete."                
installed="✓ Already installed, skipping."
new=" wasn't installed."
directoryExists="Directory already exists, skipping creation."

# File System Messages
changeDir="Changing to the $dir directory..."
moveingDotFiles="Moving any existing dotfiles from ~/ to $backupdir"
createSimlink="Creating symlink to $file in the home directory."

##[ Prompts ]##################################################################
newPrompt=" wasn't installed.  Would you like to go through the default
configuration steps?"
gitUserNamePrompt="Please enter your git user name:"
gitUserEmailPrompt="Please enter your git email:"

##[ Apps ]#####################################################################
git="git"
vim="vim"
zsh="oh-my-zsh"

##[ Files ]####################################################################
# List of files/folders to synlink in the ~ directory.
files="aliases bashrc exports fonts functions gitconfig path psqlrc vimrc vim
zshrc zpreztorc"    

# Step 1: Create back up directory

# Change to the dotfiles directory
echo -n $changeDir 
cd $dir
echo $completed

##[ Script Functions ]#########################################################
verify_os() {
    # This function is designed to ensure that the install.sh script is running
    # on a distribution that is supported.
    if [ -f /etc/apt/sources.list ]; then
       apt-get upgrade
       apt-get update
       apt-get dist-update
       apt-get autoclean
       # Now set the package manager variable.
       $packaeManagerInstall=apt-get -y install
    elif [-f /etc/yum.conf ]; then
       $packageManagerInstall=yum -y install
    elif [-f /etc/pacman.conf ]; then
       # We don't need to do set the variable as it defaults to arch.
       pacman -Syu
       pacman -S --noconfirm pacman
    else
       echo "Your distribution is not supported by this script."
       exit
    fi
}

create_directories() {
    # This function is designed to create the directories needed to backup
    # files prior to installing the dotfiles.
    echo -n "Creating $backupdir to backup existing dotfiles in ~..."
    mkdir -p $backupdir
    echo $completed
}

setup_aliases () {
    # Move any existing dotfiles in homedir to dotfiles_backup directory, then
    # create symlinks from the homedir to any files in the ~/.dotfiles 
    # directory specified in $files
    for file in $files; do
        echo $moveingDotFiles
        mv ~/.$file ~/$backupdir
        echo $createSimlink
        ln -s $dir/$file ~/.$file
    done
}

install_vim () {
    if which vim >/dev/null; then
        echo $vim $installed
    else
        $packageManagerInstall vim
    fi
}

setup_directories () {
    # Create the directories useful for various scripts and tools if they
    # don't exist.
    if [ ! -d $dir/$binDir ]; then
	    mkdir -p $dir/$binDir
    else
      echo $directoryExists
    fi 
}

install_git () {
    if which git >/dev/null; then
        echo $git $installed
    else
        $packageManagerInstall git
        echo
        read -p $git $new "Would you like to setup basic config? " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -n $gitUserNamePrompt
            read git_username
            git config --global user.name $git_username

            echo
            echo -n $gitUserEmailPrompt  
            read git_useremail
            git config --global user.email $git_useremail

            echo
            echo "Your git config has been setup in ~/.gitconfig with the following settings:"
	    echo "git username:" $git_username 
	    echo "git email:" $git_useremail 
        fi
    fi

    # Installing diff-so-fancy if needed
    if [ ! -d ~/bin/diff-so-fancy ]; then
        cd ~/bin
        git clone https://github.com/stevemao/diff-so-fancy.git
        git config --global core.pager "diff-so-fancy | less --tabs=1,5 -R"
    fi
}

install_zsh () {
# Test to see if zshell is installed.  If it is:
if [ -f /bin/zsh -o -f /usr/bin/zsh ]; then
    # Clone Prezt
    if [[ ! -d $dir/.zprezto/ ]]; then
        git clone --recursive https://github.com/sorin-ionescu/prezto.git ~/.zprezto

        echo "====================================="
        echo "Be sure to run the following command:"
        echo "setopt EXTENDED_GLOB
              for rcfile in \"\${ZDOTDIR:-$HOME}\"/.zprezto/runcoms/^README.md(.N); do
                  ln -s \"\$rcfile\" \"${ZDOTDIR:-\$HOME}/.\${rcfile:t}\"
              done"
        echo "====================================="

    fi
    # Set the default shell to zsh if it isn't currently set to zsh
    if [[ ! $(echo $SHELL) == $(which zsh) ]]; then
        chsh -s $(which zsh)
    fi
else
    # If zsh isn't installed, get the platform of the current machine
    platform=$(uname);
    # If the platform is Linux, try an apt-get to install zsh and then recurse
    if [[ $platform == 'Linux' ]]; then
        if [ -n "$(command -v yum)" ]; then
            sudo yum install zsh
        else
            sudo apt-get install zsh
        fi
        install_zsh
    # If the platform is OS X, tell the user to install zsh :)
    elif [[ $platform == 'Darwin' ]]; then
        echo "Please install zsh, then re-run this script!"
        exit
    fi
fi
}

install_vundle () {
    if [[ ! -d $dir/vim/bundle/Vundle.vim ]]; then
        git clone https://github.com/gmarik/Vundle.vim.git $dir/vim/bundle/Vundle.vim
    fi
    vim +PluginInstall +qall
}

setup_directories 

#install_git

#install_vim

#install_zsh

install_vundle

read -p "Do you want to setup aliases? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    setup_aliases
fi

if [[ ! -d $dir/vim/backup ]]; then
    mkdir $dir/vim/backup
fi

if [[ ! -d $dir/vim/swap ]]; then
    mkdir $dir/vim/swap
fi

