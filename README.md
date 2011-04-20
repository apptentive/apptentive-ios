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
In Xcode 4, create a workspace with your application project in it. Then,
add the `ApptentiveConnect.xcodeproj` to your workspace as a child of your
project.

In your target's `Build Settings` section, add the following to your 
`Other Linker Flags` settings:

    -ObjC -all_load

In your target's `Build Phases` section, add the `ApptentiveConnect` target
to your `Target Dependencies`.

Then, add `libApptentiveConnect.a` to `Link Binary With Libraries`

As the last build phase, add a `Copy Files` build phase, set the destination
to `Wrapper`, leave `Subpath` blank and `Copy only when installing` unchecked.
Then, drag `ApptentiveResources.bundle` from 
`ApptentiveConnect.xcodeproj/Products` in Xcode into the file list.

This will copy the `ApptentiveResources.bundle` resource bundle into your
application bundle as the last step of the build.

Now, for the final step. This is a workaround for a bug in Xcode 4: drag
`ATConnect.h` from `ApptentiveConnect.xcodeproj` to your app's file list.

That should be it!

Project Settings for Xcode 3
----------------------------
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

That should be it!

Using the Library
-----------------

`ApptentiveConnect` queues feedback and attempts to upload in the background. This
is intended to provide as quick a mechanism for submitting feedback as possible.

In order for queued/interrupted feedback uploads to continue uploading, we 
recommending instantiating `ATConnect` and setting the API key at application
startup, like:

``` Objective-C
#include "ATConnect.h"
…
- (void)applicationDidFinishLaunching:(UIApplication *)application … {
    ATConnect *connection = [ATConnect sharedConnection];
    connection.apiKey = kApptentiveAPIKey;
    …
}
```

Where `kApptentiveAPIKey` is an `NSString` containing your API key. As soon
as you set the API key on the shared connection object, any queued feedback
will start to upload, pending network availability. You also should not have
to set the API key again on the shared connection object.

Now, you can show the Apptentive feedback UI from a `UIViewController` with:

``` Objective-C
#include "ATConnect.h"
…

ATConnect *connection = [ATConnect sharedConnection];
[connection presentFeedbackControllerFromViewController:self];
```

Easy!

BUGS TO BE AWARE OF
-------------------
Xcode 4 won't correctly rebuild static libraries inside a workspace when the source has changed. If you change the source of `ApptentiveConnect` when
working on your app, you must do a `Product > Clean` before building and
running your app.

Adding `ATConnect.h` to your project, above, is necessary due to a bug in
Xcode 4 when archiving your app.
