#!/bin/bash

function pull_latest() {
    substep "Pulling latest changes in ${1} repository"
    if git -C $1 pull origin master &> /dev/null; then
        return
    else
        error "Please pull latest changes in ${1} repository manually"
    fi
}

function symlink() {
    application=$1
    point_to=$2
    destination=$3
    destination_dir=$(dirname "$destination")

    if test ! -e "$destination_dir"; then
        substep "Creating ${destination_dir}"
        mkdir -p "$destination_dir"
    fi
    if rm -rf "$destination" && ln -s "$point_to" "$destination"; then
        substep "Symlinking for \"${application}\" done"
    else
        error "Symlinking for \"${application}\" failed"
        exit 1
    fi
}

function install() {
    command=$1
    file=$2
    already_installed_apps=$3

    readarray -t applications < $file
    info "Installing app \"${applications[*]}\""

    for app in "${applications[@]}"
    do
        if echo "$already_installed_apps" | \
            grep --ignore-case ${app//--classic/ } &> /dev/null; then
            substep "\"${app}\" already exists"
        else
            if ${command} ${app} &> /dev/null; then
                substep "Package \"${app}\" installation succeeded"
            else
                error "Package \"${app}\" installation failed"
            fi
        fi
    done

    success "successfully installed"
}

function run() {
    command_name=$1
    command=$2
    if eval $command; then
        success "${command_name} succeeded"
    else
        error "${command_name} failed"
        exit 1
    fi
}

function coloredEcho() {
    local exp="$1";
    local color="$2";
    local arrow="$3";
    if ! [[ $color =~ '^[0-9]$' ]] ; then
       case $(echo $color | tr '[:upper:]' '[:lower:]') in
        black) color=0 ;;
        red) color=1 ;;
        green) color=2 ;;
        yellow) color=3 ;;
        blue) color=4 ;;
        magenta) color=5 ;;
        cyan) color=6 ;;
        white|*) color=7 ;; # white or invalid color
       esac
    fi
    tput bold;
    tput setaf "$color";
    echo "$arrow $exp";
    tput sgr0;
}

function info() {
    coloredEcho "$1" blue "========>"
}

function substep() {
    coloredEcho "$1" magenta "===="
}

function success() {
    coloredEcho "$1" green "========>"
}

function error() {
    coloredEcho "$1" red "========>"
}