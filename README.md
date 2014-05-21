# Apptentive iOS SDK

The Apptentive iOS SDK provides a powerful and simple channel to communicate with your customers in-app. 

Use Apptentive features to manage your app's ratings, collect and respond to customers feedback, show surveys at specific points within your app, and more.

## Apptentive Demo App

The Apptentive sample application `FeedbackDemo` is included in this repository along with the SDK.

Use FeedbackDemo to test Apptentive's features. Edit the `defines.h` file to include your Apptentive **API Key** and iTunes **App ID** where specified.

Message Center, the Ratings Prompt, Surveys, and other Apptentive interactions can all be tested before integrating Apptentive in your own app. 

## Install Guide

Apptentive can be installed manually as an Xcode subproject or via the dependency manager CocoaPods.

The following linked guides walk you through the integration process.

#### Install using CocoaPods

The Apptentive iOS SDK is available via [CocoaPods](http://cocoapods.org/), a dependency manager for Objective-C.

Please see the Apptentive [CocoaPods installation guide](docs/project_setup_cocoapods.md) to integrate Apptentive via CocoaPods.

#### Install as an Xcode subproject

The Apptentive iOS SDK can also be installed manually as an Xcode subproject.

Please see the Apptentive [Xcode project setup guide](docs/project_setup_source.md) to install Apptentive manually as an Xcode subproject or git submodule.

## Using Apptentive in your App

After integrating the Apptentive SDK into your project, you can begin using Apptentive features in your app.

You should begin by engaging Apptentive events at various places in your app:

``` objective-c
	#import "ATConnect.h"
	...
	[[ATConnect sharedConnection] engage:@"event_name" fromViewController:viewController];
```

Later, on your Apptentive dashboard, you will target these events with Apptentive features such as Message Center, Ratings Prompts, and Surveys.

Please see our [iOS integration guide]() for more on this subject.

## Testing Apptentive Features

Apptentive interactions are only shown if the conditions set on your Apptentive dashboard are met. Your Rating Prompt might only show 3 days after installing the app, for example.

This can make some Apptentive features somewhat hard to invoke and test. An interaction may or may not be shown whenever you engage and event in your app.

Please see the [Apptentive testing guide](docs/testing_guide.md) for directions on how to test that the Rating Prompt, Surveys, and other Apptentive features have been configured correctly.

