#!/usr/bin/env sh

BIN_DIR="/usr/local/bin"
ROOT_DIR=$(pwd)
CONF_DIR="${ROOT_DIR}/conf"
INSTALL_DIR="${ROOT_DIR}/install"

CURRENT_SHELL=$(ps -p $$ | tail -n 1 | awk '{print $NF}')
CURRENT_SHELL_CMD=$(which ${CURRENT_SHELL})
CURRENT_USER=${USER}
CURRENT_BRANCH=$(git branch --no-color | grep '^\* ' | grep -v 'no branch' | sed 's/^* //g')

BASH_RC="${HOME}/.${CURRENT_SHELL}rc"

#
# Main method
#
main() {
    case $1 in
        install)
            check_stable
            check_root
            install
            ;;
        uninstall)
            check_root
            uninstall
            ;;
        help)
            help
            ;;
        *)
            echo "Uknown method"
            ;;
    esac
}

#
# Check if current git branch is stable
#
check_stable() {
    if [ "${CURRENT_BRANCH}" = "stable" ]; then
        echo "You must be on 'stable' branch, not on '${CURRENT_BRANCH}' branch! Try: git checkout --track -b stable origin/stable"
        exit 2
    fi
}

#
# Check if current user is root
#
check_root() {
    if [ "${CURRENT_USER}" != "root" ]; then
        echo "Sorry, you are not root."
        exit 1
    fi
}

#
# Display help
#
help() {
    echo "Usage:"
    echo "    sudo make install: to install Twgit in ${BIN_DIR}, ${CURRENT_SHELL} completion, config file and colored git prompt"
    echo "    sudo make uninstall: to uninstall Twgit from ${BIN_DIR} and ${CURRENT_SHELL} completion"
    echo "    make doc: to generate screenshots of help on command prompt"
}

#
# Uninstall twgit
#
uninstall() {
    rm -f ${BIN_DIR}/twgit 2> /dev/null
}

#
# Install twgit
#
install () {

    echo ""
    echo "Install executable ${BIN_DIR}/twgit:"
    if [ -f ${BIN_DIR}/twgit ]; then
        echo "A previous install has been found and will be removed"
        rm -f ${BIN_DIR}/twgit
    fi

    echo "!#/usr/bin/env ${CURRENT_SHELL}" >> ${BIN_DIR}/twgit
    echo "${CURRENT_SHELL_CMD} \$@" >> ${BIN_DIR}/twgit
    chmod 0755 ${BIN_DIR}/twgit

    echo ""
    echo "Install Twgit ${CURRENT_SHELL} completion:"
    if [ $(cat ${BASH_RC} | grep -E "/${CURRENT_SHELL}_completion.sh" | grep -vE '^#' | wc -l) -gt 0 ]; then
        echo "Twgit Bash completion already loaded by '${BASH_RC}'." 
    else
        echo "Add line '. ${INSTALL_DIR}/${CURRENT_SHELL}_completion.sh' at the of the script '${BASH_RC}'."
        echo "" >> ${BASH_RC} 
        echo "# Added by Twgit makefile:" >> ${BASH_RC}
        echo ". ${INSTALL_DIR}/${CURRENT_SHELL}_completion.sh" >> ${BASH_RC}
        echo "(i) Restart ${CURRENT_SHELL} session to enable configuration."
    fi

    echo ""
    echo "Check Twgit config file:"
    if [ -f "${CONF_DIR}/twgit.sh" ]; then
        echo "Config file '${CONF_DIR}/twgit.sh' already existing."
    else
        echo "Copy config file from '${CONF_DIR}/twgit-dist.sh' to '${CONF_DIR}/twgit.sh'"
        cp -p -n "${CONF_DIR}/twgit-dist.sh" "${CONF_DIR}/twgit.sh"
    fi

    echo ""
    echo "Install colored git prompt:"
    if [ $(cat ${BASH_RC} | grep -E "\.bash_git" | grep -vE '^#' | wc -l) -gt 0 ]; then
        echo "Colored Git prompt already loaded by '${BASH_RC}'."
    else
        echo "Add colored Git prompt to '${BASH_RC}' ? [Y/N] "
        read answer
        if [ "${answer}" = "Y" ] || [ "${answer}" = "y" ]; then
            echo "Install git prompt: ${HOME}/.bash_git"
            install -m 0644 -o ${SUDO_UID} -g ${SUDO_GID} "${INSTALL_DIR}/bash_git.sh" "${HOME}/.bash_git"
            echo "Add line '. ~/.bash_git' at the end of the script '${BASH_RC}'."
            echo "" >> ${BASH_RC}
            echo "# Added by Twgit makefile:" >> ${BASH_RC}
            echo ". ~/.bash_git" >> ${BASH_RC}
        fi
    fi
}


# Run
main "$@"
