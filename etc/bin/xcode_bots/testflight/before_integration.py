# This script should be copied into the Run Script trigger of an Xcode Bot

# Utilizes `cavejohnson` for Xcode Bot scripting
# https://github.com/drewcrawford/CaveJohnson

#!/bin/bash
PATH=/Library/Frameworks/Python.framework/Versions/3.4/bin:$PATH

# Set unique Build Number prior to TestFlight upload
cavejohnson setBuildNumber --plist-path ./apptentive-ios/FeedbackDemo/FeedbackDemo/FeedbackDemo-Info.plist

# Set internal Apptentive API Key and App ID for TestFlight builds
cavejohnson setPlistValueForKey --plist-path ./apptentive-ios/FeedbackDemo/FeedbackDemo/FeedbackDemo-Info.plist --value INSERT_TESTFLIGHT_API_KEY --key ATTestFlightAPIKey
cavejohnson setPlistValueForKey --plist-path ./apptentive-ios/FeedbackDemo/FeedbackDemo/FeedbackDemo-Info.plist --value 980430089 --key ATTestFlightAppIDKey

echo "Finished running Before Integration script"
