# Apptentive iOS SDK

The Apptentive iOS SDK provides a powerful and simple channel to communicate with your customers in-app. With it, you can manage your app's ratings, let your customers give you feedback, respond to customer feedback, show surveys at specific points within your app, and more.

There have been many recent API changes for the 1.4 release. Please see `docs/APIChanges.md`.

## Install Guide

This guide will walk you through implementing Apptentive within your iOS app.

-

### Get Apptentive

All of our client code is open source and available on [GitHub](https://github.com/apptentive/apptentive-ios).

#### Using Git

You can clone our iOS SDK using git: `git clone https://github.com/apptentive/apptentive-ios.git`.

#### Using CocoaPods

Please note that if you use CocoaPods to integrate Apptentive, you can skip the "Setup Xcode Project" section and proceed directly to the ["Implement Apptentive in Project"](https://github.com/apptentive/apptentive-ios#implement-apptentive-in-project) directions below.

##### Create Podfile

1. Find [Apptentive's pod information](http://cocoapods.org/?q=apptentive-ios) on [CocoaPods](http://cocoapods.org).
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

#### Set Apptentive API key

`ApptentiveConnect` queues feedback and attempts to upload in the background. This
is intended to provide as quick a mechanism for submitting feedback as possible.

In order for queued/interrupted feedback uploads to continue uploading, we 
recommending instantiating `ATConnect` and setting the API key at application
startup.

1. Open up your app's `AppDelegate.m` file.
2. Under `#import "AppDelegate.h"`, import the `ATConnect.h` file.
3. Under implementation, set your Apptentive API key in the `application:didFinishLaunchingWithOptions:` method:

``` objective-c
#include "ATConnect.h"
// ...
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // ...
	[ATConnect sharedConnection].apiKey = @"Your_Apptentive_API_Key";
    // ...
}
```

If there isn't an `application:didFinishLaunchingWithOptions:` method, add the above code snippet elsewhere in your App Delegate's implementation.

As soon as you set the API key on the shared connection object, any queued feedback
will start to upload, pending network availability. You also should not have
to set the API key again on the shared connection object.

#### Message Center

The Apptentive Message Center provides an interface for you to communicate directly with your customers. People using your app are able to send you messages, which are routed to your Apptentive dashboard. When you reply to customer feedback, your response will immediately show up in the Message Center in their app.

You might have a menu item in your settings menu, for example, titled "Feedback". When the user clicks on this item, you will open the Message Center. People might also be routed to Message Center through other interactions, such as the rating prompt.

When you want to launch the Apptentive Message Center and feedback UI, import `ATConnect.h` then call `presentMessageCenterFromViewController:`:

``` objective-c
#include "ATConnect.h"
// ...
[[ATConnect sharedConnection] presentMessageCenterFromViewController:viewController];
```

![Message Center initial feedback](https://raw.github.com/apptentive/apptentive-ios/master/etc/screenshots/iOS-love-dialog.png) ![alt text](https://raw.github.com/apptentive/apptentive-ios/master/etc/screenshots/space.png) ![Message Center response](https://raw.github.com/apptentive/apptentive-ios/master/etc/screenshots/iOS-message-center.png)

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
### Events

The rating prompt and other Apptentive **interactions** are targeted to certain Apptentive **events**. For example, you could decide to show the rating prompt at the event `user_completed_level`. You can then, later, reconfigure the rating prompt interaction to show at `user_logged_in`. 

An **event** is a record of your customer performing an action in your app. Generate events by calling `engage:fromViewController:`. Apptentive stores a record of all events, which you can later use show specific interactions to your customer.

``` objective-c
	[[ATConnect sharedConnection] engage:@"completed_level" fromViewController:viewController];
```

The `viewController` parameter is necessary in order to show the feedback view controller if a user is unhappy with your app.

The events you choose to log will be different depending on the specifics of your app. For example, if you were to release a game, you would want engage some of the following events:

 - Completed Level (`engage:@"completed_level_8"`)
 - Ran Out of Lives (`engage:@"game_over"`)
 - Quit Level (`engage:@"quit_level_9"`)
 - Made In-App Purchase
 - Etc.

You'll want to add calls to `engage:fromViewController:` wherever it makes sense in the context of your app. Engage more events than you think you will need, as you may want to use them later.

#### Seed your App with Events

You should *seed* your app with certain Apptentive events at important points in your app. An event for when the app finishes launching. An event when your customer makes a purchase. An event for all the important steps in your app's lifecycle.

Common app events that we recommend logging include:

 - When your app finishes loading and is ready to present a view. (`engage:@"init"` or `did_finish_loading`)
 - Completes an in-app purchase. (`engage:@"completed_in_app_purchase"`)
 - User finishes logging in. (`did_log_in`)
 - Completes a level. (`completed_level_8`)
 - Finishes watching a video. (`finished_video`)
 - Exits out of a video before completing it.
 - Sends a message.
 - Switches navigation tabs.
 - Etc., depending on the specifics of your app.

Be sure to add these events *prior* to uploading the app to the App Store, even if you are not currently using all of the events to show interactions. Later, without having to re-upload a new version, you can re-target the rating prompt or other Apptentive interactions to different events.

### Interactions

An Apptentive **interaction** is a specific piece of your app that can be shown in response to a person's events. For example, Surveys, Message Center, and the Apptentive Rating Flow are all unique interactions. When users engage certain **events**, you can decide (based on pre-defined conditions) to show a specific interaction in your app.

#### Interactions are Configurable via the Apptentive Website

The real strength of Apptentive Events and Interactions come from their remote configurability. 

Prior to releasing your app on the App Store, seed your app with certain events. 
 
Later, after shipping the app, you can configure the interactions that will run whenever a customer hits one of your events.

 - The 10th time they complete a level, ask them to rate the app.
 - When they beat the game, ask for feedback about their experience.
 - After making an in-app purchase, ask them to take a survey.
 
Interactions can be modified, remotely, without shipping a new app update to the App Store. You can easily change a particular event to show a Survey rather than collect Feedback.  The remote configurability of Apptentive interactions make them perfect for A/B testing and quick iteration.

### Rating Prompt

Apptentive provides an app rating prompt interaction that aims to provide the best feedback for both you and your customers.

Customers who love your app are asked to rate the app on the App Store. Those who dislike your app are instead directed to the Apptentive Message Center, where they can communicate directly with your team. You are then able to respond directly to customer issues or feature requests.

The rating prompt is configured online in your Apptentive dashboard. At that time you will choose to trigger it at a certain Apptentive event.

Thus, the only code needed to display a Rating Prompt is to engage events using the `engage:fromViewController:` method. The rating prompt is otherwise configured from your Apptentive dashboard.

``` objective-c
	[[ATConnect sharedConnection] engage:@"completed_level" fromViewController:viewController];
```

One you have engaged some events, you can create a rating prompt and modify the parameters which determine when it will be shown in your interaction settings on [Apptentive](http://www.apptentive.com).

### Upgrade Messages

In iOS 7, users are upgraded automatically when a new version of your app is released. Unfortunately, this means they will rarely (if ever) see your App Store release notes!

Apptentive's Upgrade Message feature allows you to display a brief message when your app has been updated. You can speak directly to your users and let them know what has changed in the release.

To present an upgrade message, engage the code point `init` when your application becomes active and is able to display a view:

```objective-c
- (void)applicationDidBecomeActive:(UIApplication *)application {
	[[ATConnect sharedConnection] engage:@"init" fromViewController:viewController];
}
```

Like the rating dialog, upgrade messages are created and configured online via your Apptentive dashboard.

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

Apptentive can integrate with your existing [Urban Airship](http://urbanairship.com/) or [Amazon AWS SNS](http://aws.amazon.com/sns/) account to offer push notifications when new Apptentive messages arrive.

First, log in to your Apptentive dashboard on the web. Under "App Settings", select "Integrations". Add a new integration by entering the required information and keys.

Next, in your iOS app, add an Apptentive integration with your device token. This device token will be obtained from your app delegate's `application:didRegisterForRemoteNotificationsWithDeviceToken:` method:

``` objective-c
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
   // Urban Airship
   [[ATConnect sharedConnection] addUrbanAirshipIntegrationWithDeviceToken:deviceToken];
   
   // Amazon AWS SNS
   [[ATConnect sharedConnection] addAmazonSNSIntegrationWithDeviceToken:deviceToken];
}
```

When push notifications arrive, pass them to Apptentive:  

``` objective-c
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
	// Pass the push notification userInfo dictionary to Apptentive
	[[ATConnect sharedConnection] didReceiveRemoteNotification:userInfo fromViewController:viewController];

	// You are responsible for clearing badges and/or notifications, if desired. Apptentive does not reset them.
	application.applicationIconBadgeNumber = 0;
}
```

If the push notification was sent by Apptentive, we will then present Message Center from the `viewController` parameter.

#### Metrics

Metrics provide insight into how people are engaging with your app, and exactly which Apptentive events and interactions are being used.

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

#### Customization

For information on customizing the UI and text of `apptentive-ios`, please see [Customization](https://github.com/apptentive/apptentive-ios/blob/master/docs/Customization.md).
