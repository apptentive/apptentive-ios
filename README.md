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

In your target's _Build Settings_ section, add the following path to your 
_Header Search Paths_ settings:

    $(BUILT_PRODUCTS_DIR)/usr/local/include

In your target's _Build Phases_ section, add the _ApptentiveResources_ and
_ApptentiveConnect_ targets to your _Target Dependencies_.

Then, add _libApptentiveConnect.a_ to _Link Binary With Libraries_

Finally, add a _Run Script_ build phase with the contents:

    #!/bin/sh
    rm -rf "$BUILT_PRODUCTS_DIR/FeedbackDemo.app/ApptentiveResources.bundle"
    mv "$BUILT_PRODUCTS_DIR/ApptentiveResources.bundle" "$BUILT_PRODUCTS_DIR/FeedbackDemo.app/"

This will copy the _ApptentiveResources.bundle_ resource bundle into your
application bundle.

That should be it!

Now, you can show the Apptentive feedback UI from a _UIViewController_ with:

    #include "ATConnect.h"
    …
    [ATConnect presentFeedbackControllerFromViewController:yourViewController];
    
Easy!
