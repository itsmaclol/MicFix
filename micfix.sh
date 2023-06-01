#!/usr/bin/env bash
if [ "$(id -u)" -ne 0 ]; then echo "Please run as root." >&2; exit 1; fi

macos_version=$(sw_vers -productVersion)
macos_version_major=${macos_version%%.*}
if [[ "$macos_version_major" -lt 11 ]]; then
    echo "ERROR: This script requires macOS Big Sur or newer." >&2
    exit 1
fi

case "$1" in
    --reset | -r )
        tccutil reset Microphone
        ;;
    "" )
        echo ""
        ;;
    * )
        echo "Command Not Found"
        exit 1
        ;;
esac



echo "Please enter the name of the app for which you want to enable microphone for."

echo "Please note that some apps (ex zoom.us) have a . in the name, please type the entire app name for this script to work."

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


# Create a backup of TCC.db
cp ~/Library/Application\ Support/com.apple.TCC/TCC.db ~/TCC.db.bak

# Execute SQLite query
sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db <<EOF
insert into access
values
('kTCCServiceMicrophone','$AppBundleURLname', 0, 2, 2, 1, null, null, null, 'UNUSED', null, null, 1669648527);
EOF

echo "Script executed successfully!"
