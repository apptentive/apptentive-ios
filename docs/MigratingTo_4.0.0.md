# Migration to Apptentive v4.0.0

If you have integrated a previous version of the Apptentive SDK, you will need to keep in mind the following changes in our version 4.0.0 release. For more information, please see our [Integration Reference](https://learn.apptentive.com/knowledge-base/ios-integration-reference/).

## Moved from Static Library to Dynamic Framework

We still recommend integrating using CocoaPods. If you previously integrated using a static library, it has been removed from the project and replaced with a dynamic framework.

The easiest way to use this framework is by using [Carthage](https://github.com/Carthage/Carthage). 

## New SDK Registration Process

In place of the a single API key, the SDK now uses an Apptentive App Key and Apptentive App Signature. These are available from the [API and Settings section of your Apptentive dashboard](https://be.apptentive.com/apps/current/settings/api). You use these to create an instance of the new `ApptentiveConfiguration` class. 

You should pass this configuration instance to the `register(with:)` class method on the `Apptentive` class. 

After that you can use the SDK as you normally would. 

## Optional Login/Logout Feature

A new `logIn(withToken:completion:)` method has been added, along with a corresponding `logOut` method. These allow multiple users to use the same app instance without being exposed to one another's messages and custom data. Use of this feature is entirely optional. For more information, see our [integration guide](https://learn.apptentive.com/knowledge-base/ios-integration-reference/).

## Runtime Log Level Setting

You can now set the log level at runtime. The easiest way to do this is to set the `logLevel` property on the configuration object before you register the SDK. The setting defaults to `INFO` for all build configurations. 

You can also set the `logLevel` property directly on the `Apptentive` singleton after you have registered the SDK. 

## Local Notification Forwarding for Push Notifications

To support multiple users without exposing potentially sensitive messages in notifications, the SDK uses a two step process to implement push notifications. A silent push is sent from the server, and if the intended recipient is logged in, a local notification is posted. 

When the user responds to this local notification, your app should forward it to the Apptentive SDK using the new `didReceiveLocalNotification(_:from:)` method. The first parameter is the local notification passed into your app delegate's `application(_ application:didReceive:)` method (which your app delegate must implement), and the second is a view controller suitable for presenting the Message Center view controller from. 