#!/usr/bin/env bash

BASH_SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PATH=$BASH_SOURCE_DIR/..:$PATH
cd $BASH_SOURCE_DIR
unset BASH_SOURCE_DIR

bats . --print-output-on-failure --pretty
read -n 1 -s -r -p "######## Press key to run use_terminal ########"
echo
./use_terminal
read -n 1 -s -r -p "######## Press key to run use_progress_bar ########"
echo
./use_progress_bar
read -n 1 -s -r -p "######## Press key to run use_spinner ########"
echo
./use_spinner
read -n 1 -s -r -p "######## Press key to run use_spinner_with_progress_bar ########"
echo
./use_spinner_with_progress_bar
