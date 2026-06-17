#!/bin/bash

sudo dnf install stow
cd ~/dotfiles
stow */
