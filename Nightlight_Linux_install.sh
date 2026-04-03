#!/bin/bash

RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'

command_exists() {
    for cmd in "$@"; do
        export PATH="$HOME/.local/share/flatpak/exports/bin:/var/lib/flatpak/exports/bin:$PATH"
        command -v "$cmd" >/dev/null 2>&1 || return 1
    done
    return 0
}

checkSteamOS() {
    #TODO: add support for steamOS
    return 0
}

checkEscalationTool() {
    ## Check for escalation tools.
    if [ -z "$ESCALATION_TOOL_CHECKED" ]; then
        if [ "$(id -u)" = "0" ]; then
            ESCALATION_TOOL="eval"
            ESCALATION_TOOL_CHECKED=true
            return 0
        fi

        ESCALATION_TOOLS='sudo doas'
        for tool in ${ESCALATION_TOOLS}; do
            if command_exists "${tool}"; then
                ESCALATION_TOOL=${tool}
                ESCALATION_TOOL_CHECKED=true
                return 0
            fi
        done

        printf "%b\n" "${RED}Can't find a supported escalation tool${RC}"
        exit 1
    fi
}

checkPackageManager() {
    ## Check Package Manager
    PACKAGEMANAGER="pacman apt-get dnf zypper rpm-ostree"
    for pgm in ${PACKAGEMANAGER}; do
        if command_exists "${pgm}"; then
            PACKAGER=${pgm}
            break
        fi
    done

    if [ -z "$PACKAGER" ]; then
        printf "%b\n" "${RED}Can't find a supported package manager${RC}"
        exit 1
    fi
}

installWebKit() {

    printf "%b\n" "${YELLOW}Installing necessary dependency${RC}"

    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S webkit2gtk-4.1
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install webkit2gtk4.1
            ;;
        rpm-ostree)
            "$PACKAGER" install webkit2gtk4.1
            ;;
        apt-get|zypper)
            "$ESCALATION_TOOL" "$PACKAGER" install webkit2gtk-4.1
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager${RC}"
            ;;
    esac
}

installNightlight() {

    #checkSteamOS
    checkEscalationTool
    checkPackageManager
    installWebKit

    wget http://update.nightlight.gg/desktop/latest/linux -O nightlight-linux
    chmod +x nightlight-linux

    printf "\n\n\n\n\n"
    printf "%b\n" "${YELLOW}Download Completed!${RC}"
    printf "%b\n" "${YELLOW}Double Click nightlight-linux in the ${PWD} directory in your file manager to open nightlight${RC}"
}

installNightlight
