#! /bin/sh

#   File:       KCHelperUninstall.sh
#
#   Contains:   Script to remove everything installed by KeyboardCommander.
#

# This uninstalls everything installed by the KC.  It's useful 
# when testing to ensure that you start from scratch.

sudo launchctl unload -w /Library/LaunchDaemons/com.opcoders.kc.plist
sudo rm /Library/LaunchDaemons/com.opcoders.kc.plist
sudo rm /Library/PrivilegedHelperTools/com.opcoders.kc
sudo rm /var/run/com.opcoders.kc.socket
