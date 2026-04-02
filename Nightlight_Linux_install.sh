#!/bin/bash

command_exists() {
    for cmd in "$@"; do
        export PATH="$HOME/.local/share/flatpak/exports/bin:/var/lib/flatpak/exports/bin:$PATH"
        command -v "$cmd" >/dev/null 2>&1 || return 1
    done
    return 0
}

checkEscalationTool() {
    ## Check for escalation tools.
    if [ -z "$ESCALATION_TOOL_CHECKED" ]; then
        if [ "$(id -u)" = "0" ]; then
            ESCALATION_TOOL="eval"
            ESCALATION_TOOL_CHECKED=true
            printf "%b\n" "${CYAN}Running as root, no escalation needed${RC}"
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

    ## Enable apk community packages
    if [ "$PACKAGER" = "apk" ] && grep -qE '^#.*community' /etc/apk/repositories; then
        "$ESCALATION_TOOL" sed -i '/community/s/^#//' /etc/apk/repositories
        "$ESCALATION_TOOL" "$PACKAGER" update
    fi

    if [ -z "$PACKAGER" ]; then
        printf "%b\n" "${RED}Can't find a supported package manager${RC}"
        exit 1
    fi
}

checkWebKit() {
    case "$PACKAGER" in
        pacman|apt-get|zypper)
            webKit="webkit2gtk-4.1"
            ;;
        dnf|rpm-ostree)
            webKit="webkit2gtk4.1"
            ;;
        *)
            printf "%b\n" "Unsupported package manager"
            ;;
    esac
}

installNightlight() {

    checkEscalationTool
    checkPackageManager
    checkWebKit

    "$ESCALATION_TOOL" "$PACKAGER" install "$webKit"

    wget http://update.nightlight.gg/desktop/latest/linux -O nightlight-linux
    chmod +x nightlight-linux

    printf "\n\n\n\n\n"
    printf "%b\n" "Download Completed!"
    printf "%b\n" "Double Click nightlight-linux in the ${PWD} directory in your file manager to open nightlight"

}

installNightlight


