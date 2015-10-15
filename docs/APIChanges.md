This document tracks changes to the API between versions.

# 2.1.0

 * Apptentive Push Notifications will, if possible, now trigger a message fetch in the background. To enable background fetch, several API and project changes are needed:
 * Added `didReceiveRemoteNotification:fromViewController:fetchCompletionHandler:` API method for passing App Delegate remote notifications to Apptentive.
 * To enable Message Center background fetch, you should use the `...fetchCompletionHandler:` versions of `...didReceiveRemoteNotification:...` on the App Delegate and on ATConnect.
 * To enable Message Center background fetch, your app must set Remote Notifications as a valid Background Mode. This mode can be enabled in Xcode via your Target's Capabilities tab, or by adding the value `remote-notification` as a `UIBackgroundMode` in your app's Info.plist.
 * A `BOOL` return type has been added to the ATConnect `didReceiveRemoteNotification:...` methods. The return value indicates if the Push Notification was sent by Apptentive. 
 * The `completionHandler` block will be called by Apptentive when the message fetch is completed. To ensure that messages can be retrieved, please do not call the `completionHandler` block yourself if the notification was sent by Apptentive.
 * If the Push Notification was *not* sent by Apptentive, the parent app is responsible for calling the `completionHandler` block.

# 2.0.2

 * ATConnect's tintColor property is now deprecated in favor of using UIAppearance properties. See the iOS Customization Guide for details. 

# 2.0.0

 * ApptentiveConnect now has a deployment target of iOS 7.0, which will support iOS 7, 8, and 9. In the 2.0.0 release we have dropped support for iOS 5 and 6.
 * The ApptentiveConnect project has been converted to use Automatic Reference Counting (ARC).
 * Message Center UI has been redesigned and improved. Message Center strings and settings are now delivered from the server, allowing you to make remote changes at any time from the Apptentive dashboard.
 * The one-way Feedback Dialog has been removed in favor of Message Center and two-way conversations.
 * Added `canShowMessageCenter` method. If SDK has not yet synced with Apptentive, you will be unable to display Message Center. Use `canShowMessageCenter to determine if Message Center is ready to be displayed. If Message Center is not ready you could, for example, hide the "Message Center" button in your interface.
 * Added `BOOL` return value to the `presentMessageCenterFromViewController:` methods. Indicates if Message Center was displayed. If `NO`, a "We're attempting to connect" view is displayed instead.
 * Added `canShowInteractionForEvent:` and deprecated `willShowInteractionForEvent:` to better match the `canShowMessageCenter` naming convention.
 * Added `personName` and `personEmailAddress` properties to `ATConnect`. Set these to pre-populate the respective field in Message Center.
 * Removed `initialUserName` and `initialUserEmailAddress` properties in favor of the above `personName` and `personEmailAddress`.
 * Added Apptentive Push Notifications, which can be activated via your Apptentive dashboard. You can now implement Push Notifications for new Message Center messages without needing your own Urban Airship, Parse, or Amazon SNS account.
 * Added `setPushNotificationIntegration:withDeviceToken:` method for setting a Push Notification Provider. Use the `ATPushProvider` enum to specify a service provider, along with the `deviceToken` from `application:didRegisterForRemoteNotificationsWithDeviceToken:`. Currently supported Push Notification service providers include Apptentive, Urban Airship, Amazon SNS, and Parse.
 * In light of the new `setPushNotificationIntegration:withDeviceToken:` method, removed the legacy integration API methods: `addIntegration:withConfiguration:`, `addIntegration:withDeviceToken:`, `removeIntegration:`, `addApptentiveIntegrationWithDeviceToken:`, `addUrbanAirshipIntegrationWithDeviceToken:`, `addAmazonSNSIntegrationWithDeviceToken:`, and `addParseIntegrationWithDeviceToken:`.
 * Removed `useMessageCenter`, `initiallyUseMessageCenter`, and `initiallyHideBranding` properties.
 * Added `-unreadMessageCountAccessoryView:(BOOL)apptentiveHeart`, a method that returns a UIView that can be used to display the current number of unread messages in Message Center (with an optional Apptentive heart logo). This is designed to be set as the `accessoryView` in a `UITableViewCell` that launches Message Center.
 * Message Center is still presented via the `presentMessageCenterFromViewController:` API. However, if the device has not yet synced with Apptentive, Message Center will be unavailable and a "We're attempting to connect" screen will be displayed instead. This should occur rarely in production apps, but you may see it during development.
 * Added an in-app banner that can be displayed when new Message Center messages arrive. This banner is toggled via the Apptentive dashboard, not via an API method. Implement the `viewControllerForInteractionsWithConnection:` delegate method to pass a View Controller from which to display Message Center after this banner is tapped. If no View Controller is provided, the SDK will attempt to find and use the top-most View Controller.

# 1.6.0

 * Added `willShowInteractionForEvent:` method for determining if an interaction will be shown the next time you engage the given event.
 * Renamed `engage:(NSString *)...` parameter name from `eventLabel` to `event`.

# 1.5.7

 * Added `ATSurveyShownNotification` notification when a survey is shown.

# 1.5.5

 * Added `addParseIntegrationWithDeviceToken:` for integrating with Parse's Push Notification service.

# 1.5.4
 * Changed the App Store rating URL to open the "Reviews" tab directly in iOS 7.1+.

 * Added API methods for attaching `customData` and `extendedData` to events:  
  - `engage:withCustomData:fromViewController:`
  - `engage:withCustomData:withExtendedData:fromViewController:`

 * Added methods to easily construct `extendedData` dictionaries in the specific Apptentive format:  
  - `extendedDataDate:`
  - `extendedDataLocationForLatitude:longitude:`
  - `extendedDataCommerceWithTransactionID:affiliation:revenue:shipping:tax:currency:commerceItems:`
  - `extendedDataCommerceItemWithItemID:name:category:price:quantity:currency:`

# 1.5.3

 * Added ability to remotely hide Apptentive branding in your app via the Apptentive dashboard, contingent upon your account plan.
 * Added `initiallyHideBranding` property, which hides Apptentive branding in the time prior to the app's initial configuration being retrieved.
 * Removed `showTagLine` property, which has been replaced by `initiallyHideBranding` and the remote configuration.

# 1.5.1

 * The `showTagLine` property of `ATConnect` now makes the "Powered By Apptentive" logo in Message Center unclickable.
 * The language code used for delivering localizations now uses `[[NSLocale preferredLanguages] firstObject]` rather than the `NSLocaleLanguageCode` locale component.

# 1.5.0

Surveys are now targeted at Apptentive events via your online dashboard. Log events in your app by calling `engage:fromViewController`.

* Removed `ASurveys.h` header file.
* Moved `ATSurveySentNotification` and `ATSurveyIDKey` from `ATAppRatingFlow` to `ATConnect`.
* Removed `ATSurveyNewSurveyAvailableNotification`.
* Removed `ATAppRatingFlow.h` header file.
* Moved `apiKey` property from `ATAppRatingFlow` to `ATConnect`.
* Moved `ATAppRatingFlowUserAgreedToRateAppNotification` notification from `ATAppRatingFlow` to `ATConnect`.

# 1.4.3

* Added `debuggingOptions` property on ATConnect that allows the developer to specify debug logging preferences for their app.

# 1.4.2

* Added `addAmazonSNSIntegrationWithDeviceToken:` method for integrating with Amazon Web Services (AWS) Simple Notification Service (SNS).

# 1.4.0

* Argument `codePoint` renamed to `eventLabel` in `engage:fromViewController:`

# 1.3.0

* Added convenience methods for integrating with Apptentive:
 - `addIntegration:withDeviceToken:`
 - `addUrbanAirshipIntegrationWithDeviceToken:`

# 1.2.9

The `initialUserEmailAddress` can now be updated after a user sends feedback with no email address.

# 1.2.7

Added a `BOOL` return type to the `engage:` method.

Added the property `initiallyUseMessageCenter` to set the local, initial Message Center setting. This will be overridden by the server-based Message Center configuration when it is downloaded.

## ATConnect

* Replace `- (void)engage:fromViewController:' with `- (BOOL)engage:fromViewController:`
* Added `initiallyUseMessageCenter` property.

# 1.2.6

We added a workaround for inherited `tintColor` values which don't look good with our UI.

We also added some new methods for adding files to the user's feedback. The files will not be shown in message center, and are useful for sending debug logs.

## ATConnect

* Added `@property tintColor` for overriding the tint color in our UI, in case you're using one that doesn't work well with it in your app.
* Added `- (void)sendAttachmentText:(NSString *)text`
* Added `- (void)sendAttachmentImage:(UIImage *)image`
* Added `- (void)sendAttachmentFile:(NSData *)fileData withMimeType:(NSString *)mimeType`

# 1.2.5

## ATAppRatingFlow

* Added `openAppStore` method that immediately opens the app's page on the App Store without going through the Apptentive Ratings Flow.

# 1.2.4

## ATConnect

Added methods for configuring 3rd-party integration services and handling incoming push notifications. Current support for Urban Airship.

`[[ATConnect sharedConnection] addIntegration:ATIntegrationKeyUrbanAirship withConfiguration:@{@"token": @"YourUrbanAirshipToken"}];`

* Added `addIntegration:withConfiguration:`
* Added `removeIntegration:`
* Added `didReceiveRemoteNotification:fromViewController:`

## ATAppRatingFlow

Added methods to determine if the Apptentive Rating Flow was shown for a particular call of `showRatingFlowFromViewControllerIfConditionsAreMet:`

* Replace `- (void)showRatingFlowFromViewControllerIfConditionsAreMet:` with `- (BOOL)showRatingFlowFromViewControllerIfConditionsAreMet:`
* Now posting `ATAppRatingDidNotPromptForEnjoymentNotification` NSNotification when rating flow is not shown.

# 1.2.2

## ATConnect

* Added `- (void)presentMessageCenterFromViewController:(UIViewController *)viewController withCustomData:(NSDictionary *)customData;`
* Added `- (void)engage:(NSString *)codePoint fromViewController:(UIViewController *)viewController;`
* Added `- (void)addIntegration:(NSString *)integration withToken:(NSString *)token;`
* Added `- (void)removeIntegration:(NSString *)integration;`

# 1.1.1

## ATConnect

* Deprecated `useMessageCenter` property.

# 1.1.0

We added a method for users who only want to send feedback, not use the entire Message Center.

## ATConnect

* Added `@property useMessageCenter`

# 1.0.1

We have deprecated a few methods and added some new methods where appropriate.

## ATConnect

* Deprecated `-addCustomData:withKey:`
* Deprecated `-removeCustomData:withKey:`
* Added `-addCustomPersonData:withKey:`
* Added `-removeCustomPersonData:withKey:`
* Added `-addCustomDeviceData:withKey:`
* Added `-removeCustomDeviceData:withKey:`

## ATAppRatingFlow

* Deprecated `appName`

# 1.0

The following changes from the 0.5.x series were made.

We are moving over to a unified message center, and while breaking the feedback API have decided to take the opportunity to clean up the ratings flow API as well. Below are detailed changes that have been made to the API, but from a simple perspective, you'll want to:

In feedback:

* Replace `-presentFeedbackControllerFromViewController:` with `-presentMessageCenterFromViewController:`.
* Replace `addAdditionalInfoToFeedback:withKey:` with `addCustomData:withKey:`.

In ratings:

* Replace `+sharedRatingFlowWithAppID:` with `+sharedRatingFlow`, and set the `appID` property.
* Remove calls to `-appDidEnterForeground:viewController:` and `-appDidLaunch:viewController:`.
* Add calls to `-showRatingFlowFromViewControllerIfConditionsAreMet:` where you want the ratings flow to show up.
* Replace `-userDidPerformSignificantEvent:viewController:` with `-logSignificantEvent`.

In surveys:

* Replace `+hasSurveyAvailable` with `+hasSurveyAvailableWithNoTags`.
* Remove calls to `+checkForAvailableSurveys`. This is now automatic.

## `ATConnect`

* `initialName` changed to `initialUserName`.
* `initialEmailAddress` changed to `initialUserEmailAddress`
* `+resourceBundle` is now private
* `ATLocalizedString` is now private
* Added `-presentMessageCenterFromViewController:`
* Added `-dismissMessageCenterAnimated:completion:`
* Added `-unreadMessageCount`
* Added `addCustomData:withKey:`
* Added `removeCustomDataWithKey:`

Feedback-related API has been removed.

* `shouldTakeScreenshot`
* `feedbackControllerType`
* `-presentFeedbackControllerFromViewController:`
* `-dismissFeedbackControllerAnimated:completion:`
* `-addAdditionalInfoToFeedback:withKey:`
* `-removeAdditionalInfoFromFeedbackWithKey:`

## `ATSurveys`

* Renamed `+hasSurveyAvailable` to `+hasSurveyAvailableWithNoTags`.
* Renamed `+presentSurveyControllerFromViewController:` to `+presentSurveyControllerWithNoTagsFromViewController:`
* Removed `+checkForAvailableSurveys`

## `ATAppRatingFlow`

* Renamed `+sharedRatingFlowWithAppID:` to `+sharedRatingFlow`
* Added `@property appID`.
* Removed `-appDidEnterForeground:viewController:`
* Removed `-appDidLaunch:viewController:`
* Removed `-userDidPerformSignificantEvent:viewController:`
* Added `-showRatingFlowFromViewControllerIfConditionsAreMet:`
* Added `-logSignificantEvent`
* `-showEnjoymentDialog:` is now private
* `-showRatingDialog:` is now private
