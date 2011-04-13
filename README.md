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
In order to use _ApptentiveConnect_, your project must link against the
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
add the _ApptentiveConnect.xcodeproj_ to your workspace as a child of your
project.

In your target's _Build Settings_ section, add the following to your 
_Other Linker Flags_ settings:

    -ObjC -all_load

In your target's _Build Phases_ section, add the _ApptentiveConnect_ target
to your _Target Dependencies_.

Then, add _libApptentiveConnect.a_ to _Link Binary With Libraries_

As the last build phase, add a _Copy Files_ build phase, set the destination
to _Wrapper_, leave _Subpath_ blank and _Copy only when installing_ unchecked.
Then, drag _ApptentiveResources.bundle_ from 
_ApptentiveConnect.xcodeproj/Products_ in Xcode into the file list.

This will copy the _ApptentiveResources.bundle_ resource bundle into your
application bundle as the last step of the build.

Now, for the final step. This is a workaround for a bug in Xcode 4: drag
_ATConnect.h_ from _ApptentiveConnect.xcodeproj_ to your app's file list.

That should be it!

Project Settings for Xcode 3
----------------------------
Drag the _ApptentiveConnect.xcodeproj_ project to your project in Xcode.

In your build settings for All Configurations for your target, add the following 
to _Other Linker Flags_:

    -ObjC -all_load

Inspect your application target by selecting the target and pressing _Cmd+I_, then
in the General settings tab, add _ApptentiveConnect_ and _ApptentiveResources_ as
direct dependencies.

Now, disclose the contents of the _ApptentiveConnect.xcodeproj_ in Xcode and drag
_libApptentiveConnect.a_ to your target's _Link Binary With Libraries_ build phase,
and _ApptentiveResources.bundle_ to your target's _Copy Bundle Resources_ build phase.

Finally, drag _ATConnect.h_ from _ApptentiveConnect.xcodeproj_ to your app's file list.

That should be it!

Using the Library
-----------------

_ApptentiveConnect_ queues feedback and attempts to upload in the background. This
is intended to provide as quick a mechanism for submitting feedback as possible.

In order for queued/interrupted feedback uploads to continue uploading, we 
recommending instantiating _ATConnect_ and setting the API key at application
startup, like:

    #include "ATConnect.h"
    …
    - (void)applicationDidFinishLaunching:(UIApplication *)application … {
        ATConnect *connection = [ATConnect sharedConnection];
        connection.apiKey = kApptentiveAPIKey;
        …
    }

Where _kApptentiveAPIKey_ is an _NSString_ containing your API key. As soon
as you set the API key on the shared connection object, any queued feedback
will start to upload, pending network availability. You also should not have
to set the API key again on the shared connection object.

Now, you can show the Apptentive feedback UI from a _UIViewController_ with:

    #include "ATConnect.h"
    …
    
    ATConnect *connection = [ATConnect sharedConnection];
    [connection presentFeedbackControllerFromViewController:self];
    
Easy!

BUGS TO BE AWARE OF
-------------------
Xcode 4 won't correctly rebuild static libraries inside a workspace when the source has changed. If you change the source of _ApptentiveConnect_ when
working on your app, you must do a _Product > Clean_ before building and
running your app.

Adding _ATConnect.h_ to your project, above, is necessary due to a bug in
Xcode 4 when archiving your app.
