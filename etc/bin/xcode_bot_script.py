# This script should be copied into the Run Script trigger of an Xcode Bot
# `Xcode Bot > Edit Bot > Triggers > After Integration > Run Script`

# Utilizes `cavejohnson` for various integrations
# https://github.com/drewcrawford/CaveJohnson

#!/bin/bash
PATH=/Library/Frameworks/Python.framework/Versions/3.4/bin:$PATH

# GitHub

# First set a github auth token like so:
# sudo -u _xcsbuildd cavejohnson setGithubAuthToken --token auth_token_generated_by_github

# Set build status on GitHub
cavejohnson setGithubStatus

#test2

echo "Finished running Xcode Bot's Run Script Trigger"
