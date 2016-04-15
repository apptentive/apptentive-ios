# Migration to Apptentive v3.0.0

If you have integrated a previous version of the Apptentive SDK, you will need to keep in mind the following changes in our version 3.0.0 release. For more information, please see our [Integration Guide](https://docs.apptentive.com/ios/integration/).

## Renamed Classes and Constants

To avoid a namespace collision with a private iOS system framework, classes that previously used an `AT` prefix now use an `Apptentive` prefix. Additionally `ATConnect` has been renamed to simply `Apptentive`. Compatiblity aliases have been added for the `ATConnect` and `ATNavigationController` classes. 

Additionally a number of constants have had their names change from using an `AT` prefix to using an `Apptentive` prefix. The push provider and notification names are most likely to require updating in your code. 

## Renamed APIKey Property

The previous `apiKey` property has been renamed to `APIKey` to better follow Apple's naming convention. The previous capitalization is provided for compatibility, but has been deprecated. 

## Style Sheet Has Been added

A new style sheet property has been added to the `Apptentive` singleton that greatly expands your ability to customize the Apptentive UI. You can use the default `ApptentiveStyleSheet` instance, or create your own, either by subclassing or by implementing the `ApptentiveStyle` protocol.

Currently the style sheet is respected by the Survey and Message Center interactions.

You will need to import the `ApptentiveStyleSheet.h` file if you would like to use the built-in styles and you are integrating via source or using the static library.

You can find more information in our [Customization Guide](https://docs.apptentive.com/ios/customization/). 

## Survey Redesign

The surveys provided by the Apptentive SDK have been extensively redesigned, although their functionality remains the same.
