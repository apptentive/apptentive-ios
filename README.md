Apptentive iOS SDK
==================

This iOS library allows you to add a quick and easy in-app-feedback mechanism
to your iOS applications. Feedback is sent to the Apptentive web service.

Quickstart
==========

There are no external dependencies for this SDK.

Sample Application
------------------
The sample application FeedbackDemo demonstrates how to integrate the SDK
with your application.

The demo app includes the normal feedback flow, which can be activated by
clicking the Feedback button. It's a two screen process, the first gathering
feedback and screenshot, the second gathering contact information for 
followup:

![Feedback Screen](apptentive-ios/raw/master/etc/screenshots/feedback_iphone.png)
![Contact Info Screen](apptentive-ios/raw/master/etc/screenshots/contact_iphone.png)

The rating flow can be activated by clicking on the Ratings button. It asks
the user if they are happy with the app. If not, then a simplified feedback
window is opened. If they are happy with the app, they are prompted to rate
the app in the App Store:

![Popup](apptentive-ios/raw/master/etc/screenshots/rating.png)
![Simplified Feedback](apptentive-ios/raw/master/etc/screenshots/feedback_simple_iphone.png)


Required Frameworks (Xcode 3 & 4)
---------------------------------
In order to use `ApptentiveConnect`, your project must link against the
following frameworks:

* CoreGraphics
* CoreTelephony
* Foundation
* QuartzCore
* SystemConfiguration
* UIKit

Project Settings for Xcode 4
----------------------------

There is a video demoing integration in Xcode 4 here:
http://vimeo.com/23710908

Drag the `ApptentiveConnect.xcodeproj` project to your project in Xcode 4 and
add it as a subproject. You can do the same with a workspace.

In your target's `Build Settings` section, add the following to your 
`Other Linker Flags` settings:

    -ObjC -all_load

In your target's `Build Phases` section, add the `ApptentiveConnect` and
`ApptentiveResources` targets to your `Target Dependencies`.

Then, add `libApptentiveConnect.a` to `Link Binary With Libraries`

Build the `ApptentiveResources` target for iOS devices. Then, add the
`ApptentiveResources.bundle` from the `ApptentiveConnect` products in the
file navigator into your `Copy Bundle Resources` build phase. Building
for iOS devices first works around a bug in Xcode 4.

Now, drag `ATConnect.h` from `ApptentiveConnect.xcodeproj` to your app's 
file list.

Now see "Using the Library", below, for instructions on using the library in your code.

Project Settings for Xcode 3
----------------------------

There is a video demoing integration in Xcode 3 here:
http://vimeo.com/23566166

Drag the `ApptentiveConnect.xcodeproj` project to your project in Xcode.

In your build settings for All Configurations for your target, add the following 
to `Other Linker Flags`:

    -ObjC -all_load

Inspect your application target by selecting the target and pressing `Cmd+I`, then
in the General settings tab, add `ApptentiveConnect` and `ApptentiveResources` as
direct dependencies.

Now, disclose the contents of the `ApptentiveConnect.xcodeproj` in Xcode and drag
`libApptentiveConnect.a` to your target's `Link Binary With Libraries` build phase,
and `ApptentiveResources.bundle` to your target's `Copy Bundle Resources` build phase.

Finally, drag `ATConnect.h` from `ApptentiveConnect.xcodeproj` to your app's file list.

Now see "Using the Library", below, for instructions on using the library in your code.

Using the Library
-----------------

`ApptentiveConnect` queues feedback and attempts to upload in the background. This
is intended to provide as quick a mechanism for submitting feedback as possible.

In order for queued/interrupted feedback uploads to continue uploading, we 
recommending instantiating `ATConnect` and setting the API key at application
startup, like:

``` objective-c
#include "ATConnect.h"
// ...
- (void)applicationDidFinishLaunching:(UIApplication *)application /* ... */ {
    ATConnect *connection = [ATConnect sharedConnection];
    connection.apiKey = kApptentiveAPIKey;
    // ...
}
```

Where `kApptentiveAPIKey` is an `NSString` containing your API key. As soon
as you set the API key on the shared connection object, any queued feedback
will start to upload, pending network availability. You also should not have
to set the API key again on the shared connection object.

Now, you can show the Apptentive feedback UI from a `UIViewController` with:

``` objective-c
#include "ATConnect.h"
// ...
ATConnect *connection = [ATConnect sharedConnection];
[connection presentFeedbackControllerFromViewController:self];
```

Easy!


App Rating Flow
---------------
`ApptentiveConnect` now provides an app rating flow similar to other projects
such as [appirator](https://github.com/arashpayan/appirater). To use it, add
the `ATAppRatingFlow.h` header file to your project.

Then, at startup, instantiate a shared `ATAppRatingFlow` object with your 
iTunes app ID (see "Finding Your iTunes App ID" below):

``` objective-c
#include "ATAppRatingFlow.h"
// ...
- (void)applicationDidFinishLaunching:(UIApplication *)application /* ... */ {
    ATAppRatingFlow *sharedFlow = [ATAppRatingFlow sharedRatingFlowWithAppID:@"<your iTunes app ID>"];
    // The parameter is a BOOL indicating whether a rating dialog can be 
    // shown here.
    [sharedFlow appDidLaunch:YES viewController:self.navigationController];
    
    // ...
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    ATAppRatingFlow *sharedFlow = [ATAppRatingFlow sharedRatingFlowWithAppID:@"<your iTunes app ID>"];
    [sharedFlow appDidEnterForeground:YES viewController:self.navigationController];
}
```

The `viewController` parameter is necessary in order to be able to show the 
feedback view controller if a user is unhappy with your app.

**Finding Your iTunes App ID**
In [iTunesConnect](https://itunesconnect.apple.com/), go to "Manage Your 
Applications" and click on your application. In the "App Information" 
section of the page, look for the "Apple ID". It will be a number. This is
your iTunes applicaiton ID.
