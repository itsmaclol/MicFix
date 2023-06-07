#!/usr/bin/env bash

# Thanks to palera1n install.sh for these colours

RED='\033[0;31m'
YELLOW='\033[0;33m'
DARK_GRAY='\033[90m'
LIGHT_CYAN='\033[0;96m'
NO_COLOR='\033[0m'

error() {
    echo -e " - [${DARK_GRAY}$(date +'%m/%d/%y %H:%M:%S')${NO_COLOR}] ${RED}<Error>${NO_COLOR}: ${RED}$1${NO_COLOR}"
}

info() {
    echo -e " - [${DARK_GRAY}$(date +'%m/%d/%y %H:%M:%S')${NO_COLOR}] ${LIGHT_CYAN}<Info>${NO_COLOR}: ${LIGHT_CYAN}$1${NO_COLOR}"
}

warning() {
    echo -e " - [${DARK_GRAY}$(date +'%m/%d/%y %H:%M:%S')${NO_COLOR}] ${YELLOW}<Warning>${NO_COLOR}: ${YELLOW}$1${NO_COLOR}"
}

clear

# is it clear that i made the script?

echo "# == MicFix script =="
echo "#"
echo "# Made by Mac"
echo "#"
echo ''


# Check for root access
if [ "$(id -u)" -ne 0 ]; then error "This script will not run without root or sudo." >&2; exit 1; fi

advanced_called=False

function finish_code {
    case $advanced_called in
        False )
            # Find the app in /Applications folder
            appPath="/Applications/$appName.app"
            
            # Check if the app exists
            if [[ ! -d "$appPath" ]]; then
                error "App not found in /Applications folder."
                exit 1
            fi

            # Path to info.plist
            infoPlistPath="$appPath/Contents/Info.plist"

            # Validate the info.plist file
            if [[ ! -f "$infoPlistPath" ]]; then
                error "info.plist file not found for the specified app."
                exit 1
            fi

            # Retrieve AppBundleURLname from info.plist
            AppBundleURLname=$(defaults read "$infoPlistPath" CFBundleIdentifier)

            # Validate the AppBundleURLname
            if [[ -z "$AppBundleURLname" ]]; then
                error "Failed to retrieve AppBundleURLname from Info.Plist file."
                exit 1
            fi
            ;;
        True )
            echo ""
            ;;
        esac

    # Create a backup of TCC.db
    cp ~/Library/Application\ Support/com.apple.TCC/TCC.db ~/TCC.db.bak
    # Execute SQLite query
    sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db <<EOF
    insert into access
    values
    ('kTCCServiceMicrophone','$AppBundleURLname', 0, 2, 2, 1, null, null, null, 'UNUSED', null, null, 1669648527);
EOF

    info "Script executed successfully!"

    info "Please be sure to restart the app and system settings for mic access to work properly."

    exit 1
}




macos_version=$(sw_vers -productVersion)
macos_version_major=${macos_version%%.*}
if [[ "$macos_version_major" -lt 13 ]]; then
    error "This script is made for macOS Ventura." >&2
    exit 1
fi


case "$1" in
    --reset | -r )
        tccutil reset Microphone > /dev/null 2>&1
        info "Microphone successfully reset."
        exit 1
        ;;
    --advanced )
        advanced_called=True
        info "Enter custom AppBundleURLname"
        read -r -p "" AppBundleURLname
        finish_code
        ;;
    "" )
        echo ""
        ;;
    * )
        error "Command not found."
        exit 1
        ;;
esac


if [[ $advanced_called = False ]]; then
    info "Please enter the name of the app for which you want to enable microphone for."
    info "Please note that some apps (ex zoom.us) have a . in the name, please type the entire app name for this script to work."
    read -r -p "App Name: " appName
    finish_code
fi


