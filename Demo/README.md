Apptentive iOS Demo App
-----------------------

**Note: For an example of how to integrate the Apptentive SDK, please see the example app at the top level of this repository.**

This app is intended to demonstrate the features of the Apptentive SDK, often in ways that are not suitable for use in a production app, including the use of undocumented APIs that may change without notice. As such, it is not intended for use as an example of how to integrate with the Apptentive SDK. 

Features
========

This app allows you to quickly and easily try out various features of the Apptentive SDK, including:

- Creating and triggering events
- Manually launching interactions
- Reading and modifying custom device and person data

Setup
=====

At launch, this app will present a view controller requesting an API key. You can find your API key on your [Apptentive dashboard](https://be.apptentive.com/apps/current/settings/api) in the API section of the Settings tab. 

To avoid having to enter your API key each time you launch the app, edit the `defaults.plist` file and add your API key at the root level as a string with the key `APIKey`. You can also pass it in as a command-line argument (e.g. `-APIKey <Your Apptentive API Key>`) in Xcode's scheme editor. 

**Note: For a production app, you should store your API key as a string constant in compiled code. Including it in a resource (such as a property list file) makes it especially easy for someone to obtain your API key and potentially interfere with your app's data on the Apptentive dashboard.** 

Message Center
==============

The Message Center tab allows you to launch Message Center, and maintains an indication of the unread message count. 

Events
======

You can use the Events tab to trigger events by tapping on the event's row. To change an event label, tap the Edit button and then tap on the corresponding row. 

You can also change the default events by editing the `defaults.plist` file, or passing them in on the command line (e.g. `-events <array><string>event_1</string><string>event_2</string></array>`). 

Interactions
===========

The Interactions tab allows you to directly trigger interactions, such as launching Message Center, a Survey, or the Ratings Prompt. For debugging purposes, you can export the raw interactions data using the action button. 

Custom Data
===========

The Data tab lets you view device and person data, as well as edit custom data associated with the device or person. 
