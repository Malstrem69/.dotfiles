#!/usr/bin/env bash

set -euo pipefail

declare -a categories=(
    "Graphics"
    "Github"
    "Files"
    "Utilites"
    "Network"
)

declare -a graphics=(
    "pinta"
)

declare -a github=(
    "meld"
)

declare -a files=(
    "nemo"
    "baobab"
)

declare -a utilites=(
    "pavucontrol"
)

declare -a network=(
    "postman"
    "wireshark"
)

choice=$(printf '%s\n' "${categories[@]}" | dmenu -i -l 20 -h 28 -bw 2 -W 700 -p 'Menu:' "${@}" )

if [ "$choice" == "Graphics" ]; then
    choice=$(printf '%s\n' "${graphics[@]}" | dmenu -i -l 10 -h 28 -bw 2 -W 700 -p 'Graphics:' "${@}")
    exec $choice
fi

if [ "$choice" == "Github" ]; then
    choice=$(printf '%s\n' "${github[@]}" | dmenu -i -l 10 -h 28 -bw 2 -W 700 -p 'Github:' "${@}")
    exec $choice
fi

if [ "$choice" == "Files" ]; then
    choice=$(printf '%s\n' "${files[@]}" | dmenu -i -l 10 -h 28 -bw 2 -W 700 -p 'Files:' "${@}")
    exec $choice
fi

if [ "$choice" == "Utilites" ]; then
    choice=$(printf '%s\n' "${utilites[@]}" | dmenu -i -l 10 -h 28 -bw 2 -W 700 -p 'Utilites:' "${@}")
    exec $choice
fi

if [ "$choice" == "Network" ]; then
    choice=$(printf '%s\n' "${network[@]}" | dmenu -i -l 10 -h 28 -bw 2 -W 700 -p 'Network:' "${@}")
    exec $choice
fi
