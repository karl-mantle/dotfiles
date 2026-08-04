#!/usr/bin/env bash

setup_git() {
    section_start "Configuring Git"

    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
    git config --global init.defaultBranch main

    echo "Git configured:"
    echo "Name:  $(git config --global user.name)"
    echo "Email: $(git config --global user.email)"
}