# Apptentive iOS SDK

The Apptentive iOS SDK provides a powerful and simple channel to communicate with your customers in-app. 

Use Apptentive features to manage your app's ratings, collect and respond to customers feedback, show surveys at specific points within your app, and more.

There have been many recent API changes for the 1.4 release. Please see `docs/APIChanges.md`.

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

## Start using Apptentive

Be sure to first integrate Apptentive as an Xcode subproject or by using CocoaPods. Please see the sections above.

Once Apptentive has been added to your Xcode project you can begin using its features. Import the `ATConnect.h` header file to use Apptentive in your project files:  

``` objective-c
#import "ATConnect.h"
```

You will primarily interact with Apptentive's `sharedConnection` [shared instance singleton](https://developer.apple.com/library/mac/documentation/general/conceptual/devpedia-cocoacore/Singleton.html).

``` objective-c
[ATConnect sharedConnection]
```

The following sections will explain how to integrate Apptentive's features in your app.

#### Set Apptentive API key

`ApptentiveConnect` queues feedback and attempts to upload in the background. This
is intended to provide as quick a mechanism for submitting feedback as possible.

In order for queued/interrupted feedback uploads to continue uploading, we 
recommending instantiating `ATConnect` and setting the API key at application
startup.

1. In your app's `AppDelegate.m` file, import `ATConnect.h`.
2. Set your Apptentive API key in the app delegate's `application:didFinishLaunchingWithOptions:` method:

``` objective-c
#import "ATConnect.h"
// ...
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // ...
	[ATConnect sharedConnection].apiKey = @"Your_Apptentive_API_Key";
    // ...
}
```

If there isn't an `application:didFinishLaunchingWithOptions:` method, add the above code snippet elsewhere in your app delegate's implementation.

As soon as you set the API key on the shared connection object, any queued feedback
will start to upload, pending network availability. You also should not have
to set the API key again on the shared connection object.

#### Message Center

The Apptentive Message Center provides an interface for you to communicate directly with your customers. People using your app are able to send you messages, which are routed to your Apptentive dashboard. When you reply to customer feedback, your response will immediately show up in the Message Center in their app.

To launch the Apptentive Message Center, import `ATConnect.h` and then call `presentMessageCenterFromViewController:`:

``` objective-c
#include "ATConnect.h"
// ...
[[ATConnect sharedConnection] presentMessageCenterFromViewController:viewController];
```

![Message Center initial feedback](https://raw.github.com/apptentive/apptentive-ios/master/etc/screenshots/iOS-love-dialog.png) ![spacer image](https://raw.github.com/apptentive/apptentive-ios/master/etc/screenshots/space.png) ![Message Center response](https://raw.github.com/apptentive/apptentive-ios/master/etc/screenshots/iOS-message-center.png)

#### Feedback Button

Your app should implement a Feedback button that takes people to Message Center. 

This button is very important, as it allows users to get back to your Apptentive support channel at any time. They might want to add additional information or tell you that their problem has resolved itself.

You might title the button "Contact Us", "Give Feedback", or "Support". Developers often put this button in their settings menu. 

When the user taps this button, you should open Message Center using `presentMessageCenterFromViewController:`.

![Give Feedback button](https://raw.github.com/apptentive/apptentive-ios/readme/etc/screenshots/give-feedback-button.png)


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

The rating prompt is configured online in your Apptentive dashboard. At that time you will configure it to be shown when a certain event is engaged. You can also edit the exact text that will be displayed.

Thus, the only code needed to display a Rating Prompt is to engage events using the `engage:fromViewController:` method. The rating prompt is otherwise configured from your Apptentive dashboard.

``` objective-c
	[[ATConnect sharedConnection] engage:@"completed_level" fromViewController:viewController];
```

One you have engaged some events, you can create a rating prompt and modify the parameters which determine when it will be shown in your interaction settings on [Apptentive](http://www.apptentive.com).

![Enjoyment dialog](https://raw.github.com/apptentive/apptentive-ios/readme/etc/screenshots/rating_prompt_enjoyment_dialog.png) ![spacer image](https://raw.github.com/apptentive/apptentive-ios/master/etc/screenshots/space.png) ![Rating dialog](https://raw.github.com/apptentive/apptentive-ios/readme/etc/screenshots/rating_prompt_rating_dialog.png) ![spacer image](https://raw.github.com/apptentive/apptentive-ios/master/etc/screenshots/space.png) ![feedback dialog image](https://raw.github.com/apptentive/apptentive-ios/readme/etc/screenshots/rating_prompt_feedback_dialog.png)

#### Surveys

Apptentive Surveys are created on the Apptentive dashboard and presented natively in your app.

Surveys are **cached** and are only re-downloaded intermittently to cut down on network connections. If you create a survey online, you may not immediately see it on your device. To test the survey, force a cache refresh by deleting and re-running your app or reseting the iOS simulator.

Like all Apptentive interactions, Surveys are targeted at an event you engage in your app:

``` objective-c
	[[ATConnect sharedConnection] engage:@"completed_in_app_purchase" fromViewController:viewController];
```

Engaging the `completed_in_app_purchase` event above will allow you to show a survey after users of your app complete an in-app purchase. Target the event during the survey creation process:  

![Target a survey to an event.](https://raw.github.com/apptentive/apptentive-ios/readme/etc/screenshots/survey_target_event.png)

When your survey goes live, it will be presented to app users who engage an in-app purchase event:  

![Apptentive Survey screenshot.](https://raw.github.com/apptentive/apptentive-ios/readme/etc/screenshots/survey_screenshot.png)


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

#### Customization

For information on customizing the UI and text of `apptentive-ios`, please see [Customization](https://github.com/apptentive/apptentive-ios/blob/master/docs/Customization.md).

## Testing Apptentive Features

Apptentive interactions are only shown if the conditions set on your Apptentive dashboard are met. Your Rating Prompt might only show 3 days after installing the app, for example.

This can make some Apptentive features somewhat hard to invoke and test. An interaction may or may not be shown whenever you engage and event in your app.

Please see the [Apptentive testing guide](docs/testing_guide.md) for directions on how to test that the Rating Prompt, Surveys, and other Apptentive features have been configured correctly.

