#!/bin/bash
########################################################################
# install.sh
# This script creates symlinks from the home directory to any desired 
# dotfiles in ~/dotfiles
########################################################################

# Before doing anything, check to determine if run as root/sudo.
#if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root/sudo." ; exit 1 ; fi

# Script Variables
dir=~/.dotfiles                      # Dotfiles directory
backupdir=~/.dotfiles_backup         # Old dotfiles backup directory
packageManagerInstall=sudo pacman -S # Distro specific package manager.

# Messages
completed="Complete."                
installed="Already installed, skipping."
newWPrompt=" wasn't installed.  Would you like to go through the default configuration steps?"
new=" wasn't installed."
# List of files/folders to synlink in the ~ directory.
files="aliases bashrc exports fonts functions gitconfig path psqlrc vimrc vim zshrc zpreztorc"    

# Create the back up directory (name is controlled by the olddir variable).
echo -n "Creating $backupdir to  backup of any existing dotfiles in ~..."
mkdir -p $backupdir
echo $completed

# Change to the dotfiles directory
echo -n "Changing to the $dir directory..."
cd $dir
echo $completed

# Script functions.
setup_aliases () {
    # Move any existing dotfiles in homedir to dotfiles_backup directory, then create symlinks 
    # from the homedir to any files in the ~/.dotfiles directory specified in $files
    for file in $files; do
        echo "Moving any existing dotfiles from ~ to $backupdir"
        mv ~/.$file ~/$backupdir
        echo "Creating symlink to $file in home directory."
        ln -s $dir/$file ~/.$file
    done
}

install_vim () {
    if which vim >/dev/null; then
        echo "Vim " + $installed
    else
        $packageManagerInstall vim
    fi
}

install_git () {
    if which git >/dev/null; then
        echo "git" $installed
    else
        $packageManagerInstall git
        echo
        read -p "Git " + $new "Seems like it's your first git install, would you like yo setup basic config? " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -n "Please enter your git username: "
            read git_username
            git config --global user.name $git_username

            echo
            echo -n "Please enter your git email address: "
            read git_useremail
            git config --global user.email $git_useremail

            echo
            echo "Your git config has been setup in ~/.gitconfig"
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

install_git

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

