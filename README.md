# Apptentive iOS SDK

The Apptentive iOS SDK lets you provide a powerful and simple channel to your customers. With it, you can manage your app's ratings, let your customers give you feedback, respond to customer feedback, show surveys at specific points within your app, and more.

There have been many recent API changes for the 1.0 release. Please see `docs/APIChanges.md`.

Note: For developers with apps created before June 28, 2013, please contact us to have your account upgraded to the new Message Center UI on our website.

## Install Guide

This guide will walk you through implementing Apptentive within your iOS app. Below is a video demonstration of how quick and easy this integration is.

[![iOS Install Guide Video](https://raw.github.com/apptentive/apptentive-ios/master/etc/screenshots/iOS-video.png "iOS Install Guide Video")](https://vimeo.com/73020193)

-

### Get Apptentive

All of our client code is open source and available on [GitHub](https://github.com/apptentive/apptentive-ios).

#### Using Git

You can clone our iOS SDK using git: `git clone https://github.com:apptentive/apptentive-ios.git`.

#### Using CocoaPods

Please note that if you use CocoaPods to get Apptentive, you can skip workspace configuration and go directly to Apptentive implementation below.

##### Create Podfile

1. Search for Apptentive's pod information on [CocoaPods](https://cocoapods.org).
2. List and save the dependencies in a text file named "Podfile" in your Xcode project directory. It should look something like this:

```
platform :ios, '6.0'
pod 'apptentive-ios'
```

##### Install Pods

Now you can install the dependencies in your project. Run this command in your Xcode project directory in Terminal:

```
$ pod install
```

-

### Setup Xcode Project

First, drag the `ApptentiveConnect.xcodeproj` project file (located in the `ApptentiveConnect` folder of our source code) to your project in Xcode 5 and add it as a subproject.

![ApptentiveConnect drag](https://raw.github.com/apptentive/apptentive-ios/master/etc/screenshots/iOS-apptentive-connect.png)

------------------------------------------------------------------------------------

Next, in order to use `ApptentiveConnect`, your project must link against the
following frameworks:

* Accelerate
* AssetsLibrary
* CoreData
* CoreText
* CoreGraphics
* CoreTelephony
* Foundation
* QuartzCore
* StoreKit
* SystemConfiguration
* UIKit

*Note:* If your app uses Core Data and you listen for Core Data related notifications, you will
want to filter them based upon your managed object context. Learn more from [Apple's documentation](https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/CoreDataFramework/Classes/NSManagedObjectContext_Class/NSManagedObjectContext.html).

##### How To

1. Click on your Xcode project in the file browser sidebar.
2. Go to your Xcode project's `Build Phases` tab.
3. Expand "Link Binary With Libraries".
4. Click on the `+` button and add the frameworks listed above.

![iOS Frameworks](https://raw.github.com/apptentive/apptentive-ios/master/etc/screenshots/iOS-frameworks.png)

#### Configure Apptentive

##### Setup Linker Flags

1. Click on your Xcode project in the file navigator sidebar.
2. Go to your Xcode project's `Build Settings` tab.
3. Search for `Other Linker Flags`
4. Double click in the blank area to the right of `Other Linker Flags` but under the "Yes" of `Link With Standard Libraries`
5. Click on the `+` button and add the following:

```
    -ObjC -all_load
```

![iOS Linker Flags](https://raw.github.com/apptentive/apptentive-ios/master/etc/screenshots/iOS-linker-flags.png)

**Note:** If you can't use the `-all_load` flag in your project, you can use the `-force_load` flag instead:

```
-force_load $(BUILT_PRODUCTS_DIR)/libApptentiveConnect.a
```

##### Add Apptentive Connect and Resources

1. Go back to your Xcode project's `Build Phases` tab.
2. Add the `ApptentiveConnect` and `ApptentiveResources` as targets in your project's `Target Dependencies`.

![iOS Target Dependencies](https://raw.github.com/apptentive/apptentive-ios/master/etc/screenshots/iOS-target-dependencies.png)

##### Link Apptentive Library

Under `Link Binary With Libraries`, add `libApptentiveConnect.a`.

![Apptentive Library](https://raw.github.com/apptentive/apptentive-ios/master/etc/screenshots/iOS-apptentive-library.png)

##### Build Apptentive Resources for iOS Devices

Building for iOS devices first works around a bug in Xcode 5.

1. In the upper left corner of your Xcode window, click on your project name in the scheme picker.
2. Select `Apptentive Resources`.
3. Click to the right of the arrow next to `Apptentive Resources`.
4. Select `iOS Devices`.
5. Under `Product` in your Mac's menu bar, click on `Build`.

##### Copy Apptentive Resources Bundle

1. In the file navigator, expand the ApptentiveConnect project.
2. Expand `Products`.
3. Under your Xcode project's `Build Phases`, expand `Copy Bundle Resources`.
4. Drag `ApptentiveResources.bundle` from the `ApptentiveConnect` products in the
file navigator into `Copy Bundle Resources`.

![iOS Bundle Resources](https://raw.github.com/apptentive/apptentive-ios/master/etc/screenshots/iOS-bundle-resources.png)

##### Add the ApptentiveConnect Header File

1. In the file navigator, expand `source` under the ApptentiveConnect project.
2. Drag `ATConnect.h` from `ApptentiveConnect.xcodeproj` to your app's file list.

-

### Implement Apptentive in Project

#### Message Center

`ApptentiveConnect` queues feedback and attempts to upload in the background. This
is intended to provide as quick a mechanism for submitting feedback as possible.

In order for queued/interrupted feedback uploads to continue uploading, we 
recommending instantiating `ATConnect` and setting the API key at application
startup.

1. Open up your app's `AppDelegate.m` file.
2. Under `#import "AppDelegate.h"`, import the `ATConnect.h` file.
3. Under implementation, edit the `application:didFinishLaunchingWithOptions:` method to look like so:

``` objective-c
#include "ATConnect.h"
// ...
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
    ATConnect *connection = [ATConnect sharedConnection];
    connection.apiKey = @"Your_Apptentive_API_Key";
    // ...
}
```

If there isn't an `application:didFinishLaunchingWithOptions:` method, add the above code snippet elsewhere in your App Delegate's implementation.

As soon as you set the API key on the shared connection object, any queued feedback
will start to upload, pending network availability. You also should not have
to set the API key again on the shared connection object.

------------------------------------------------------------------------------------

Now, whereever you want to launch the Apptentive feedback UI from... 

1. Include the `ATConnect.h` header file.
2. Add the following code to whichever method responds to feedback.

``` objective-c
#include "ATConnect.h"
// ...
ATConnect *connection = [ATConnect sharedConnection];
[connection presentMessageCenterFromViewController:viewController];
```

![Message Center initial feedback](https://raw.github.com/apptentive/apptentive-ios/master/etc/screenshots/iOS-love-dialog.png) ![alt text](https://raw.github.com/apptentive/apptentive-ios/master/etc/screenshots/space.png) ![Message Center response](https://raw.github.com/apptentive/apptentive-ios/master/etc/screenshots/iOS-message-center.png)

#### Ratings

`ApptentiveConnect` now provides an app rating flow similar to other projects
such as [Appirater](https://github.com/arashpayan/appirater). This uses the number
of launches of your application, the amount of time users have been using it, and
the number of significant events the user has completed (for example, levels passed)
to determine when to display a ratings dialog.

To use it...

1. Open your project's `AppDelegate.m` file.
2. Add the `ATAppRatingFlow.h` header file to your project.
3. Instantiate a shared `ATAppRatingFlow` object with your iTunes App ID (see "Finding Your iTunes App ID" below):

``` objective-c
#include "ATAppRatingFlow.h"
// ...
- (void)applicationDidFinishLaunching:(UIApplication *)application /* ... */ {
    ATAppRatingFlow *sharedFlow = [ATAppRatingFlow sharedRatingFlow];
    sharedFlow.appID = @"Your_iTunes_App_Store_ID";
    // ...
}
```

------------------------------------------------------------------------------------

**Finding Your iTunes App ID**

In [iTunesConnect](https://itunesconnect.apple.com/), go to "Manage Your 
Applications" and click on your application. In the "App Information" 
section of the page, look for the "Apple ID". It will be a number. This is
your iTunes application ID.

------------------------------------------------------------------------------------

The ratings flow won't show unless you call the following:

``` objective-c
[[ATAppRatingFlow sharedRatingFlow] showRatingFlowFromViewControllerIfConditionsAreMet:viewController];
```

The `viewController` parameter is necessary in order to be able to show the 
feedback view controller if a user is unhappy with your app.

You'll want to add calls to `-showRatingFlowFromViewControllerIfConditionsAreMet:` wherever it makes sense in the context of your app.

If you're using significant events to determine when to show the ratings flow, you can
increment the number of significant events by calling:

``` objective-c
[sharedFlow logSignificantEvent];
```

You can modify the parameters which determine when the ratings dialog will be
shown in your app settings on [Apptentive](https://apptentive.com).

#### Unread Messages

Use `unreadMessageCount` to get the current number of unread messages:

``` objective-c
NSUInteger unreadMessageCount = [[ATConnect sharedConnection] unreadMessageCount];
```

You can also listen for the `ATMessageCenterUnreadCountChangedNotification` notification to be alerted immediately when a new message arrives:

``` objective-c
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unreadMessageCountChanged:) name:ATMessageCenterUnreadCountChangedNotification object:nil];
```

If listening for the notification via the code above, you would then implement the `unreadMessageCountChanged:` method. This will be called every time the unread message count changes.

``` objective-c
- (void)unreadMessageCountChanged:(NSNotification *)notification {
	// Unread message count is contained in the notification's userInfo dictionary.
	NSNumber *unreadMessageCount = [notification.userInfo objectForKey:@"count"];

	// Update your UI or alert the user when a new message arrives.
	NSLog(@"You have %@ unread Apptentive messages", unreadMessageCount);
}
```

#### Upgrade Messages

In iOS 7, users are upgraded automatically when a new version of your app is released. Unfortunately, this means they will rarely (if ever) see your App Store release notes!

Apptentive's Upgrade Message feature allows you to display a brief message when your app has been updated. You can speak directly to your users and let them know what has changed in the release.

To present an upgrade message, engage the code point `app.launch` when your application becomes active:

```objective-c
- (void)applicationDidBecomeActive:(UIApplication *)application {
	[[ATConnect sharedConnection] engage:@"app.launch" fromViewController:viewController];
}
```

Upgrade Messages are created and configured online via your Apptentive dashboard.

#### Surveys

Surveys can be created on our website and presented, in-app, to users.

Surveys are **cached** and will only be re-downloaded every 24 hours, to cut down on network connections. When developing your app and testing Apptentive, force a cache refresh by delete the app from your device and re-running.

To begin using surveys...

1. In the file navigator, expand `source` under the ApptentiveConnect project.
2. Drag `ATConnect.h` from `ApptentiveConnect.xcodeproj` to your app's file list.
3. Import `ATSurveys.h` into the file where you need it.

There are both tagged surveys and untagged surveys. Tags are useful for defining
surveys that should be shown only in certain instances.

To check if a survey with a given set of tags is available to be shown, call:

```objective-c
NSSet *tags = [NSSet setWithArray:@[@"bigWin", @"endOfLevel", @"usedItem"]];

if ([ATSurveys hasSurveyAvailableWithTags:tags]) {
    [ATSurveys presentSurveyControllerWithTags:tags fromViewController:viewController];
}
```

Note: Tags for a particular survey are set on the Apptentive website.

To show a survey without tags, use:

``` objective-c
if ([ATSurveys hasSurveyAvailableWithNoTags]) {
    [ATSurveys presentSurveyControllerWithNoTagsFromViewController:viewController];
}
```

New surveys will be retrieved automatically. When a new survey becomes available,
the `ATSurveyNewSurveyAvailableNotification` notification will be sent.

``` objective-c
#include "ATSurveys.h"
// ...
- (void)applicationDidFinishLaunching:(UIApplication *)application /* ... */ {
    // ...
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(surveyBecameAvailable:) name:ATSurveyNewSurveyAvailableNotification object:nil];
}

- (void)surveyBecameAvailable:(NSNotification *)notification {
    // Present survey here as appropriate.
}
```

#### Custom Data

Custom data can be attached to a device, Apptentive user, or individual message. This data will then be displayed for reference alongside the conversation on the Apptentive website.

Custom data should be of type `NSString`, `NSNumber`, `NSDate`, or `NSNull`.

``` objective-c
- (void)addCustomPersonData:(NSObject<NSCoding> *)object withKey:(NSString *)key;
- (void)addCustomDeviceData:(NSObject<NSCoding> *)object withKey:(NSString *)key;
- (void)presentMessageCenterFromViewController:(UIViewController *)viewController withCustomData:(NSDictionary *)customData;
```

When Message Center is presented with custom data, that custom data will be attached to the first message in the Message Center session.

#### Attachments

The methods below can be used to attach text, images, or files to the user's feedback.

These attachments will appear in your online Apptentive dashboard, but will *not* appear in Message Center on the user's device. They may be useful for sending debug logs or other pertinent information.
 
``` objective-c
- (void)sendAttachmentText:(NSString *)text;
- (void)sendAttachmentImage:(UIImage *)image;
- (void)sendAttachmentFile:(NSData *)fileData withMimeType:(NSString *)mimeType;
```

#### Push Notifications

Apptentive can integrate with your existing [Urban Airship](http://urbanairship.com/) account to offer push notifications when new Apptentive messages arrive.

First, log in to your Apptentive dashboard on the web. Under "App Settings", select "Integrations". Add a new Urban Airship integration by entering your App Key, App Secret, and App Master Secret.

Next, in your iOS app, register an Urban Airship configuration with your device token. If you are using the [Urban Airship library](http://docs.urbanairship.com/build/ios.html#download-install-our-library-frameworks), the device token can be obtained in your app delegate's `didRegisterForRemoteNotificationsWithDeviceToken:` method:

``` objective-c
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
   // Register the device token with Apptentive
   [[ATConnect sharedConnection] addUrbanAirshipIntegrationWithDeviceToken:deviceToken];
}
```

When push notifications arrive, pass them to Apptentive:  

``` objective-c
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    // Pass the push Notification userInfo dictionary to Apptentive
    [[ATConnect sharedConnection] didReceiveRemoteNotification:userInfo fromViewController:viewController];
	
	// You are responsible for clearing badges and/or notifications, if desired. Apptentive does not reset them.
	application.applicationIconBadgeNumber = 0;
}
```

If the push notification was sent by Apptentive, we will then present Message Center from the `viewController` parameter.

#### Metrics

Metrics provide insight into exactly where people begin and end interactions
with your app and with feedback, ratings, and surveys. You can enable and disable
metrics on your app settings page on [Apptentive](https://apptentive.com).

#### Sample Application

The sample application FeedbackDemo demonstrates how to integrate the SDK
with your application.

The demo app includes integration of the message center, surveys, and the
ratings flow. You use it by editing the `defines.h` file and entering in
the Apple ID for your app and your Apptentive API token. 

The rating flow can be activated by clicking on the Ratings button. It asks
the user if they are happy with the app. If not, then a simplified feedback
window is opened. If they are happy with the app, they are prompted to rate
the app in the App Store:

![Popup](https://raw.github.com/apptentive/apptentive-ios/master/etc/screenshots/rating.png)
