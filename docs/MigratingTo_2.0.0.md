# Migration to Apptentive v2.0.0

If you have integrated a previous version of the Apptentive SDK, you will need to keep in mind the following changes in our version 2.0.0 release.

## Message Center

Version 2.0.0 introduces a new version of Message Center. Please ensure that the new Message Center UI displays properly in your app.

Message Center is still presented via the `presentMessageCenterFromViewController:` method.

### Feedback Dialog has been Removed

The Feedback Dialog one-way message tool has been removed from version 2.0.0 in favor of simply displaying Message Center. 

In previous versions, people used the Feedback Dialog to submit their first message. Thereafter, they were sent to Message Center to read replies or send additional feedback.

There was formerly an option to disable Message Center and *only* accept messages via the one-way Feedback Dialog. This option has been removed in version 2.0.0.

Rather than using one-way messages via the Feedback Dialog, you should use a custom "Status Message" on your Apptentive dashboard to set proper expectations of reply.

### Message Center is Retrieved from Server

Message Center text is now sent to devices from the Apptentive backend. Much of this text is editable on a per-app basis via your Apptentive dashboard. These remote strings allow you to customize Message Center at any point without issuing an app update.

As a consequence, we are unable to show Message Center until that device syncs at least one time with the Apptentive servers. This sync should normally happen very quickly after the very first launch of the app.

If the first sync has not yet occurred, Apptentive displays a "We're attempting to connect" message rather than the (unavailable) Message Center. This view will be seen only rarely in the actual usage of your app, but do be aware that you may see it in development if you try to launch Message Center immediately after a fresh install.

The new API method `canShowMessageCenter` has been added to indicate whether Message Center has been synced and can be displayed. If that method returns `NO` you can, for example, hide the "Message Center" button in your interface.

## Name and Email Address Properties

The API for adding Name and Email Address details has been simplified in version 2.0.0.

Programmatically setting the new `personName` or `personEmailAddress` properties on `ATConnect` will pre-populate the respective fields in Message Center.

The person using your app will be given the opportunity to change those details. However, setting the properties programmatically again will overwrite the user-inputted values. 

Please be aware that setting `personName` or `personEmailAddress` will immediately overwrite anything the person had previously typed in those fields.

We have also removed the `initialUserName` and `initialUserEmailAddress` properties in favor of the above `personName` and `personEmailAddress`.

## Removed Legacy Properties

We have removed the `useMessageCenter`, `initiallyUseMessageCenter`, and `initiallyHideBranding` properties from the API. Please make sure to update your code if you are setting any of these properties.

Using Message Center and Hiding Branding are now set via the configuration on your Apptentive dashboard.

## Determining if Interactions will be Shown

The method `willShowInteractionForEvent:` has been marked as deprecated and replaced by `canShowInteractionForEvent:`. This terminology matches the new API method `canShowMessageCenter`.
