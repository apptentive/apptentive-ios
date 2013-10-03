# Apptentive iOS SDK

The Apptentive iOS SDK lets you provide a powerful and simple channel to your customers. With it, you can manage your app's ratings, let your customers give you feedback, respond to customer feedback, show surveys at specific points within your app, and more.

There have been many recent API changes for the 1.0 release. Please see `docs/APIChanges.md`.

Note: For developers with apps created before June 28, 2013, please contact us to have your account upgraded to the new Message Center UI on our website.

## Install Guide

This guide will walk you through implementing Apptentive within your iOS app. Below is a video demonstration of how quick and easy this integration is.

[![iOS Install Guide Video](etc/screenshots/iOS-video.png?raw=true "iOS Install Guide Video")](https://vimeo.com/73020193)

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
pod 'apptentive-ios',   '~> 1.0.1'
```

##### Install Pods

Now you can install the dependencies in your project. Run this command in your Xcode project directory in Terminal:

```
$ pod install
```

-

### Setup Xcode Project

First, drag the `ApptentiveConnect.xcodeproj` project file (located in the `Apptentive Connect` folder of our source code) to your project in Xcode 4 and add it as a subproject.

![ApptentiveConnect drag](etc/screenshots/iOS-apptentive-connect.png?raw=true)

------------------------------------------------------------------------------------

Next, in order to use `ApptentiveConnect`, your project must link against the
following frameworks:

* CoreData
* CoreText
* CoreGraphics
* CoreTelephony
* Foundation
* QuartzCore
* StoreKit
* SystemConfiguration
* UIKitj

*Note:* If your app uses Core Data and you listen for Core Data related notifications, you will
want to filter them based upon your managed object context. Learn more from [Apple's documentation](https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/CoreDataFramework/Classes/NSManagedObjectContext_Class/NSManagedObjectContext.html).

##### How To

1. Click on your Xcode project in the file browser sidebar.
2. Go to your Xcode project's `Build Phases` tab.
3. Expand "Link Binary With Libraries".
4. Click on the `+` button and add the frameworks listed above.

![iOS Frameworks](etc/screenshots/iOS-frameworks.png?raw=true)

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

![iOS Linker Flags](etc/screenshots/iOS-linker-flags.png?raw=true)

##### Add Apptentive Connect and Resources

1. Go back to your Xcode project's `Build Phases` tab.
2. Add the `ApptentiveConnect` and `ApptentiveResources` as targets in your project's `Target Dependencies`.

![iOS Target Dependencies](etc/screenshots/iOS-target-dependencies.png?raw=true)

##### Link Apptentive Library

Under `Link Binary With Libraries`, add `libApptentiveConnect.a`.

![Apptentive Library](etc/screenshots/iOS-apptentive-library.png?raw=true)

##### Build Apptentive Resources for iOS Devices

Building for iOS devices first works around a bug in Xcode 4.

1. In the upper right-hand corner of your Xcode window, click on your project name.
2. Select `Apptentive Resources`.
3. Click to the right of the arrow next to `Apptentive Resources`.
4. Select `iOS Devices`.
5. Under `Project` in your Mac's menu bar, click on `Build`.

##### Copy Apptentive Resources Bundle

1. In the file navigator, expand the ApptentiveConnect project.
2. Expand `Products`.
3. Under your Xcode project's `Build Phases`, expand `Copy Bundle Resources`.
4. Drag `ApptentiveResources.bundle` from the `ApptentiveConnect` products in the
file navigator into `Copy Bundle Resources`.

![iOS Bundle Resources](etc/screenshots/iOS-bundle-resources.png?raw=true)

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
3. Under implementation, edit the `applicationDidFinishLaunching` method to look like so:

``` objective-c
#include "ATConnect.h"
// ...
- (void)applicationDidFinishLaunching:(UIApplication *)application /* ... */ {
    ATConnect *connection = [ATConnect sharedConnection];
    connection.apiKey = @"<Your API Key>";
    // ...
}
```

If there isn't an `applicationDidFinishLaunching` method, add the above code snippet to your App Delegate's implementation.

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

![Message Center initial feedback](etc/screenshots/iOS-message-center.png?raw=true) ![alt text](etc/screenshots/space.png?raw=true) ![Message Center response](etc/screenshots/iOS-sample-message-center.png?raw=true)

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
    sharedFlow.appID = @"<Your iTunes App ID>";
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
NSSet *tags = [@"bigWin", @"endOfLevel", @"usedItem"];

if ([ATSurveys hasSurveyAvailableWithTags:tags]) {
    [ATSurveys presentSurveyControllerWithTags:tags fromViewController:viewController];
}
```

Note: Tags for a particular survey are set on the Apptentive website.

To show a survey without tags, use:

```objective-c
if ([ATSurveys hasSurveyAvailableWithNoTags]) {
    [ATSurveys presentSurveyControllerWithNoTagsFromViewController:viewController];
}
```

New surveys will be retrieved automatically. When a new survey becomes available,
the `ATSurveyNewSurveyAvailableNotification` notification will be sent.

```objective-c
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

![Popup](etc/screenshots/rating.png?raw=true)
