#!/bin/bash
#
# Copyright (C) 2019 nysascape
#
# Licensed under the Raphielscape Public License, Version 1.d (the "License");
# you may not use this file except in compliance with the License.
#

# Install packages
command -v pacman > /dev/null

# Run oh-my-zsh installer unatteneded
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended



# Powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k

# Add zsh plugins
sed -i 's/plugins=(git)/plugins=(git cp gpg-agent)/g' ~/.zshrc

# Git configurations
git config --global user.name "Reinazhard"
git config --global user.email "muh.alfarozy@gmail.com"
git config --global credential.helper store
git config --global commit.gpgsign true
git config --global user.signingkey "A15571E738CE3CD4"



