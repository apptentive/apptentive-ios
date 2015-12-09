# Migration to Apptentive v2.0.0

If you have integrated a previous version of the Apptentive SDK, you will need to keep in mind the following changes in our version 2.0.0 release.

## iOS Version Support

Apptentive SDK version 2.0.0 has a deployment target of iOS 7.0, which will support iOS 7, 8, and 9. In the 2.0.0 release we have dropped support for iOS 5 and 6.

## Message Center

Version 2.0.0 introduces a new version of Message Center. Please ensure that the new Message Center UI displays properly in your app.

Message Center is still presented via the `presentMessageCenterFromViewController:` method.

### Feedback Dialog has been Removed

The Feedback Dialog one-way message tool has been removed from version 2.0.0 in favor of simply displaying Message Center.

In previous versions, people used the Feedback Dialog to submit their first message. Thereafter, they were sent to Message Center to read replies or send additional feedback.

There was formerly an option to disable Message Center and *only* accept messages via the one-way Feedback Dialog. This option has been removed in version 2.0.0.

Rather than using one-way messages via the Feedback Dialog, you should use a custom "Status Message" on your Apptentive dashboard to set proper expectations of reply.

### Message Center is Retrieved from Server

Message Center text is now sent to devices from the Apptentive backend. Much of this text is editable on a per-app basis via your Apptentive dashboard. These remote strings allow you to customize Message Center copy and localization at any point without issuing an app update.

As a consequence, we are **unable to show Message Center** until that device syncs at least one time with the Apptentive servers. This sync should normally happen very quickly after the very first launch of the app.

If the first sync has not yet occurred, Apptentive displays a "We're attempting to connect" message rather than the (unavailable) Message Center. This view will be seen only rarely in the actual usage of your app, but do be aware that you may see it in development if you try to launch Message Center immediately after a fresh install.

The new API method `canShowMessageCenter` has been added to indicate whether Message Center has been synced and can be displayed. If that method returns `NO` you can, for example, hide the "Message Center" button in your interface.

## Name and Email Address Properties

The API for adding Name and Email Address details has been simplified in version 2.0.0.

Programmatically setting the new `personName` or `personEmailAddress` properties on `ATConnect` will pre-populate the respective fields in Message Center.

Please be aware that setting `personName` or `personEmailAddress` will **immediately overwrite** anything the person had previously typed in those fields.

The person using your app will be given the opportunity to change those details. However, setting the properties programmatically again will overwrite the user-inputted values.

We have also removed the `initialUserName` and `initialUserEmailAddress` properties in favor of the above `personName` and `personEmailAddress`.

## Push Notifications

The new method `setPushNotificationIntegration:withDeviceToken:` has been added to add a single Push Notification provider. To register for push notifications, call this method with one of the enumerated `ATPushProvider`s plus the device token from `application:didRegisterForRemoteNotificationsWithDeviceToken`.

In light of this new method, we have removed the legacy integration API methods:  
 - `addIntegration:withConfiguration:`
 - `addIntegration:withDeviceToken:`
 - `removeIntegration:`
 - `addApptentiveIntegrationWithDeviceToken:`
 - `addUrbanAirshipIntegrationWithDeviceToken:`
 - `addAmazonSNSIntegrationWithDeviceToken:`
 - `addParseIntegrationWithDeviceToken:`.

 Apptentive Push Notifications will, if possible, now trigger a message fetch in the background. To enable background fetch, several API and project changes are needed:
- To enable Message Center background fetch, you should use the `...fetchCompletionHandler:` versions of `...didReceiveRemoteNotification:...` on the App Delegate and on ATConnect.
 - To enable Message Center background fetch, your app must set Remote Notifications as a valid Background Mode. This mode can be enabled in Xcode via your Target's Capabilities tab, or by adding the value `remote-notification` as a `UIBackgroundMode` in your app's Info.plist.
 - A `BOOL` return type has been added to the ATConnect `didReceiveRemoteNotification:...` methods. The return value indicates if the Push Notification was sent by Apptentive.
 - The `completionHandler` block will be called by Apptentive when the message fetch is completed. To ensure that messages can be retrieved, please do not call the `completionHandler` block yourself if the notification was sent by Apptentive.
 - If the Push Notification was *not* sent by Apptentive, the parent app is responsible for calling the `completionHandler` block.


## Removed Legacy Properties

We have removed the `useMessageCenter`, `initiallyUseMessageCenter`, and `initiallyHideBranding` properties from the API. Please make sure to update your code if you are setting any of these properties.

Using Message Center and Hiding Branding are now set via the configuration on your Apptentive dashboard.

## Determining if Interactions will be Shown

The method `willShowInteractionForEvent:` has been marked as deprecated and renamed to `canShowInteractionForEvent:`. This terminology matches the new API method `canShowMessageCenter`.
