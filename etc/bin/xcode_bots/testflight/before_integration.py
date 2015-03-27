# This script should be copied into the Run Script trigger of an Xcode Bot

# Utilizes `cavejohnson` for Xcode Bot scripting
# https://github.com/drewcrawford/CaveJohnson

#!/bin/bash
PATH=/Library/Frameworks/Python.framework/Versions/3.4/bin:$PATH

# Set unique Build Number prior to TestFlight upload
cavejohnson setBuildNumber --plist-path ./apptentive-ios/FeedbackDemo/FeedbackDemo/FeedbackDemo-Info.plist
