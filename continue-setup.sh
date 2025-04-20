#!/bin/bash

aliases="if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi"

# write var to file
echo "$aliases" >> ~/.zshrc

# add ~/bin to PATH
echo 'export PATH="$PATH:$HOME/bin"' >> ~/.zshrc