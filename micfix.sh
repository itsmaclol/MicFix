#!/usr/bin/env bash
if [ "$(id -u)" -ne 0 ]; then echo "Please run as root." >&2; exit 1; fi
get_macos_version() {
    macos_version=$(uname -r)
    echo "$macos_version"
}
macos_version=$(get_macos_version)

if [[ $1 == "--reset" ]]; then
    if [[ "$macos_version" < "20.0.0" ]]; then
        echo "This script requires macOS Big sur and higher"
        exit
    else
        tccutil reset Microphone
        exit
    fi
elif [[ $1 == "" ]]; then
    echo ""
else
    echo "Command Not Found."
    exit
fi


echo "Please enter the name of the app for which you want to enable microphone for."

read -p "App Name: " appName

# Find the app in /Applications folder
appPath="/Applications/$appName.app"

# Check if the app exists
if [[ ! -d "$appPath" ]]; then
    echo "Error: App not found in /Applications folder."
    exit 1
fi

# Path to info.plist
infoPlistPath="$appPath/Contents/Info.plist"

# Validate the info.plist file
if [[ ! -f "$infoPlistPath" ]]; then
    echo "Error: info.plist file not found for the specified app."
    exit 1
fi

# Retrieve AppBundleURLname from info.plist
AppBundleURLname=$(defaults read "$infoPlistPath" CFBundleIdentifier)

# Validate the AppBundleURLname
if [[ -z "$AppBundleURLname" ]]; then
    echo "Error: Failed to retrieve AppBundleURLname from info.plist."
    exit 1
fi

# Check macOS version
if [[ "$macos_version" < "20.0.0" ]]; then
    echo "Error: This script requires macOS Big Sur or later."
    exit 1
fi

# Create a backup of TCC.db
cp ~/Library/Application\ Support/com.apple.TCC/TCC.db ~/TCC.db.bak

# Execute SQLite query
sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db <<EOF
insert into access
values
('kTCCServiceMicrophone','$AppBundleURLname', 0, 2, 2, 1, null, null, null, 'UNUSED', null, null, 1669648527);
EOF

echo "Script executed successfully!"
