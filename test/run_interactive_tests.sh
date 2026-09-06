#!/usr/bin/env bash

BASH_SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

read -n 1 -s -r -p "######## Press key to run use_terminal ########"
echo
"$BASH_SOURCE_DIR"/use_terminal
read -n 1 -s -r -p "######## Press key to run use_progress_bar ########"
echo
"$BASH_SOURCE_DIR"/use_progress_bar
read -n 1 -s -r -p "######## Press key to run use_spinner ########"
echo
"$BASH_SOURCE_DIR"/use_spinner
read -n 1 -s -r -p "######## Press key to run use_spinner_with_progress_bar ########"
echo
"$BASH_SOURCE_DIR"/use_spinner_with_progress_bar
