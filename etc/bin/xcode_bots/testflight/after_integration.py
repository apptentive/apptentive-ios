# This script should be copied into the Run Script trigger of an Xcode Bot

# Utilizes `cavejohnson` for Xcode Bot scripting
# https://github.com/drewcrawford/CaveJohnson

#!/bin/bash
PATH=/Library/Frameworks/Python.framework/Versions/3.4/bin:$PATH

# Upload build to TestFlight
cavejohnson uploadiTunesConnect --itunes-app-id 980430089 --itunes-username INSERT_ITUNES_USERNAME --itunes-password INSERT_ITUNES_PASSWORD

echo "Finished running After Integration script"
