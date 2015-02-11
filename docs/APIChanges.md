This document tracks changes to the API between versions.

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
