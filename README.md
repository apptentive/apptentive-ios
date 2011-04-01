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


Using the Library
-----------------
Now, you can show the Apptentive feedback UI from a _UIViewController_ with:

    #include "ATConnect.h"
    …
    
    ATConnect *connection = [ATConnect sharedConnection];
    connection.apiKey = kApptentiveAPIKey;
    
    [connection presentFeedbackControllerFromViewController:self];

Where _kApptentiveAPIKey_ is an _NSString_ containing your API key.
    
Easy!

BUGS TO BE AWARE OF
-------------------
Xcode 4 won't correctly rebuild static libraries inside a workspace when the source has changed. If you change the source of _ApptentiveConnect_ when
working on your app, you must do a _Product > Clean_ before building and
running your app.

Adding _ATConnect.h_ to your project, above, is necessary due to a bug in
Xcode 4 when archiving your app.
