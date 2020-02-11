#!/bin/bash

# Constants
DOTFILES_REPO=~/dotfiles

# Import
. "${DOTFILES_REPO}/utils.sh"

main() {
    # First things first, asking for sudo credentials
    ask_for_sudo
    #Update ubuntu
    update
    # Installing Homebrew
    install_linuxbrew
    # Cloning Dotfiles repository
    clone_dotfiles_repo
    # Setting up symlinks
    setup_symlinks
    # Installing all packages in Dotfiles repository's Brewfile
    install_homebrew_formulae
    # Install apt packages 
    install_apt
    # Install snap packages
    install_snap_packages
    # Change default shcell to zsh
    change_default_shell_to_zsh
    # Install oh-my-zsh
    install_oh_my_zsh
    # Installing pip packages
    install_pip_packages
    # Installing npm packages
    install_npm_packages
    # Setting up Vim
    setup_vim
    # Setting up tmux
    setup_tmux
}

function update() {
    if wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add - &> /dev/null; then
        success "Google GPG key updated"
        if wget -q -O - https://apt.corretto.aws/corretto.key | sudo apt-key add - &> /dev/null; then
            sudo add-apt-repository 'deb https://apt.corretto.aws stable main' &> /dev/null
            success "Corretto key updated"
            if sudo apt-get update -qqy &> /dev/null; then
                success "update succeeded"
            else
                error "update failed"
                exit 1
            fi
        else
            error "Update faild for corretto key"
            exit 1
        fi
    else
        error "Update failed for Google GPG key"
        exit 1
    fi
}

function install_linuxbrew() {
    info "Installing Homebrew"
    if hash brew &> /dev/null; then
        success "Homebrew already exists"
    else
        if sudo apt install linuxbrew-wrapper &> /dev/null; then
            success "Homebrew installation succeeded"
        else
            error "Homebrew installation failed"
            exit 1
        fi
    fi
}

function setup_symlinks() {
    info "Setting up symlinks"
    symlink "bash" ${DOTFILES_REPO}/bash.profile ~/.bash_profile 
    symlink "git" ${DOTFILES_REPO}/git/gitconfig ~/.gitconfig
    symlink "gitignore" ${DOTFILES_REPO}/git/gitignore_global ~/.gitignore_global
    symlink "tmux" ${DOTFILES_REPO}/tmux/tmux.conf ~/.tmux.conf
    symlink "vim" ${DOTFILES_REPO}/vim/vimrc ~/.vimrc
    symlink "zshrc" ${DOTFILES_REPO}/zsh/zshrc.zsh ~/.zshrc
    symlink "zshenv" ${DOTFILES_REPO}/zsh/env.zsh ~/.zshenv
    success "Symlinks successfully setup"
}

function install_homebrew_formulae() {
    BREW_FILE_PATH="${DOTFILES_REPO}/install/brewfile"
    install_homebrew_formulae_from_file "${BREW_FILE_PATH}"
}

function install_apt() {
    sudo apt --fix-broken install &> /dev/null 
    command="sudo apt install -y "
    file=${DOTFILES_REPO}/install/aptfile
    apt_installed_apps=$(apt list --installed)
    install "${command}" "${file}" "${snap_installed_apps}"

}

function install_snap_packages() {
    command="sudo snap install "
    file=${DOTFILES_REPO}/install/snapfile
    snap_installed_apps=$(snap list)
    install "${command}" "${file}" "${snap_installed_apps}"
}

function install_oh_my_zsh() {
    info "Installing Oh-my-zsh"
    if [ -f "/home/$(whoami)/.oh-my-zsh/oh-my-zsh.sh" ]; then
            success "Oh-my-zsh already exists"
    else
        url=https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh
        if /bin/sh -c "$(curl -fsSL ${url})"; then
            success "Oh-my-zsh installation succeeded"
        else
            error "Oh-my-zsh installation failed"
            exit 1
        fi
    fi
}

function ask_for_sudo() {
    info "Prompting for sudo password"
    if sudo --validate; then
        # Keep-alive
        while true; do sudo --non-interactive true; \
            sleep 10; kill -0 "$$" || exit; done &> /dev/null &
        success "Sudo password updated"
    else
        error "Sudo password update failed"
        exit 1
    fi
}

function clone_dotfiles_repo() {
    info "Cloning dotfiles repository into ${DOTFILES_REPO}"
    if test -e $DOTFILES_REPO; then
        substep "${DOTFILES_REPO} already exists"
        pull_latest $DOTFILES_REPO
        success "Pull successful in ${DOTFILES_REPO} repository"
    else
        url=https://github.com/nejads/ubuntu-dotfiles.git
        if git clone "$url" $DOTFILES_REPO && \
           git -C $DOTFILES_REPO remote set-url origin git@github.com:nejads/ubuntu-dotfiles.git; then
            success "Dotfiles repository cloned into ${DOTFILES_REPO}"
        else
            error "Dotfiles repository cloning failed"
            exit 1
        fi
    fi
}

function install_homebrew_formulae_from_file() {
    BREW_FILE_PATH=$1
    info "Installing packages within ${BREW_FILE_PATH}"
    if brew bundle check --file="$BREW_FILE_PATH" &> /dev/null; then
        success "Brewfile's dependencies are already satisfied "
    else
        if brew bundle --file="$BREW_FILE_PATH"; then
            success "Brewfile installation succeeded"
        else
            error "Brewfile installation failed"
            exit 1
        fi
    fi
}

function change_default_shell_to_zsh() {
    user=$(whoami)
    if sudo chsh -s /bin/zsh "$user"; then
        success "zsh shell successfully set for \"${user}\""
    else
        error "Please try setting zsh shell again"
    fi
}

function install_pip_packages() {
    pip_packages=($(cat  install/pipfile | tr "\n" " "))
    info "Installing pip packages \"${pip_packages[*]}\""

    pip3_list_outcome=$(pip3 list)
    for package_to_install in "${pip_packages[@]}"
    do
        if echo "$pip3_list_outcome" | \
            grep --ignore-case "$package_to_install" &> /dev/null; then
            substep "\"${package_to_install}\" already exists"
        else
            if pip3 install "$package_to_install" &> /dev/null; then
                substep "Package \"${package_to_install}\" installation succeeded"
            else
                error "Package \"${package_to_install}\" installation failed"
                exit 1
            fi
        fi
    done

    success "pip packages successfully installed"
}

function install_npm_packages() {
    npm_packages=($(cat  install/npmfile | tr "\n" " "))
    info "Installing npm packages \"${npm_packages[*]}\""

    npm_list_outcome=$(npm list -g)
    for package_to_install in "${npm_packages[@]}"
    do
        if echo "$npm_list_outcome" | \
            grep --ignore-case "$package_to_install" &> /dev/null; then
            substep "\"${package_to_install}\" already exists"
        else
            if sudo npm install -g "$package_to_install" &> /dev/null; then
                substep "Package \"${package_to_install}\" installation succeeded"
            else
                error "Package \"${package_to_install}\" installation failed"
                exit 1
            fi
        fi
    done

    success "npm packages successfully installed"
}

function setup_tmux() {
    info "Setting up tmux"
    substep "Installing tpm"
    if test -e ~/.tmux/plugins/tpm; then
        substep "tpm already exists"
        pull_latest ~/.tmux/plugins/tpm
        substep "Pull successful in tpm's repository"
    else
        url=https://github.com/tmux-plugins/tpm
        if git clone "$url" ~/.tmux/plugins/tpm; then
            substep "tpm installation succeeded"
        else
            error "tpm installation failed"
            exit 1
        fi
    fi

    substep "Installing all plugins"

    # sourcing .tmux.conf is necessary for tpm
    tmux source-file ~/.tmux.conf &> /dev/null

    if ~/.tmux/plugins/tpm/bin/./install_plugins &> /dev/null; then
        substep "Plugins installations succeeded"
    else
        error "Plugins installations failed"
        exit 1
    fi
    success "tmux successfully setup"
}

function setup_vim() {
    info "Setting up vim"
    substep "Installing Vundle"
    if test -e ~/.vim/bundle/Vundle.vim; then
        substep "Vundle already exists"
        pull_latest ~/.vim/bundle/Vundle.vim
        substep "Pull successful in Vundle's repository"
    else
        url=https://github.com/VundleVim/Vundle.vim.git
        if git clone "$url" ~/.vim/bundle/Vundle.vim; then
            substep "Vundle installation succeeded"
        else
            error "Vundle installation failed"
            exit 1
        fi
    fi
    substep "Installing all plugins"
    if vim +PluginInstall +qall &> /dev/null; then
        substep "Plugins installations succeeded"
    else
        error "Plugins installations failed"
        exit 1
    fi
    success "vim successfully setup"
}


main "$@"
