#!/bin/bash

echo -n "setup miniforge? [y/n]: "
read ans


if [ $ans = "y" ]; then
    echo "setting up miniforge"
    # setup miniforge
    curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
    bash Miniforge3-$(uname)-$(uname -m).sh
    echo "done"
fi

echo -n "create a conda torch env? [y/n]: "
read ans

if [ $ans = "y" ]; then
    echo "creating torch-env"
    # create conda environment named torch
    conda create -yn torch python=3.10
    echo "done"
fi


echo -n "install/configure vim? [y/n]: "
read ans

if [ $ans = "y" ]; then
    # configure vim
    echo "congiguring vim"
    git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
    sh ~/.vim_runtime/install_awesome_vimrc.sh
    echo "done"
fi

echo -n "install/configure tmux? [y/n]: "
read ans

if [ $ans = "y" ]; then
    # configure tmux
    echo "configuring tmux"
    # configure tmux
    git clone https://github.com/gpakosz/.tmux.git ~/.tmux
    ln -s -f ~/.tmux/.tmux.conf
    echo "done"
fi


# create a symbolic link to the .bash_aliases file
echo -n "create symbolic link to .bash_aliases? [y/n]: "
read ans

if [ $ans = "y" ]; then
    echo "creating symbolic link to .bash_aliases"
    ln -s ~/dotfiles/.bash_aliases ~/.bash_aliases
    echo "done"
fi

# create a symbolic link to the bin directory
echo -n "create symbolic link to bin directory? [y/n]: "
read ans

if [ $ans = "y" ]; then
    echo "creating symbolic link to bin directory"
    ln -s ~/dotfiles/bin ~/bin
    echo "done"
fi

# download yt-dlp
echo -n "download yt-dlp? [y/n]: "
read ans

if [ $ans = "y" ]; then
    echo "downloading yt-dlp"
    # download yt-dlp
    wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -O ~/bin/yt-dlp
    chmod a+rx ~/bin/yt-dlp  # Make executable
    echo "done"
fi

# if shell is zsh, then install oh-my-zsh
if [ $SHELL = "/bin/zsh" ]; then
    echo -n "install/configure oh-my-zsh? [y/n]: "
    read ans

    if [ $ans = "y" ]; then
        # install oh-my-zsh
        echo "installing oh-my-zsh"
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        echo "done"


        aliases="if [ -f ~/.bash_aliases ]; then
            . ~/.bash_aliases
        fi"

        # write var to file
        echo "$aliases" >> ~/.zshrc


    fi
fi