Apptentive Example App
-----------------------

**Note: For testing Apptentive SDK features or working with SDK internals, please see the demo app in the /Demo directory in this repository.**

This app is intended as an exampe of how you might integrate a real-world app with the Apptentive SDK. 

Features
========

This app shows an example of the how to use Apptentive SDK's classes and methods in a real-world app:

- Setting the API Key
- Engaging events
- Launching message center
- Showing the unread message count

Setup
=====

First, navigate to the directory that this README is in and type `pod install` to install the latest version of the Apptentive SDK. If you prefer to use the local version of the SDK (in the parent directory), comment out the first `pod` statement and uncomment the second one (you will have to `pod install` again after changing this). 

You will need to set a valid Apptentive API Key to run this app in the `AppDelegate.swift` file. You can find your API key on your [Apptentive dashboard](https://be.apptentive.com/apps/current/settings/api) in the API section of the Settings tab. We suggest creating a new app for evaluation purposes. 

Events
======

This app sends events when the user switches between the Photos and Favorites tab (as seen in the `AppDelegate.swift` file), and also when the user likes or unlikes a photo (as seen in the `PicturesViewController.swift` and `FavoritesViewController.swift` files). 

Message Center
==============

Under the Options tab, the user can launch the Apptentive Message Center (as seen in the `MoreViewController.swift` file). 

Unread Message Count
====================

The Message Center button (implemented as a `UITableViewCell`) includes the unread message count accessory view provided by the Apptentive SDK (also in `MoreViewController.swift`). 

Credits
=======

Photos courtesy of [https://unsplash.it](https://unsplash.it). 
