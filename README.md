# Apptentive iOS SDK

The Apptentive iOS SDK provides a simple and powerful channel to communicate in-app with your customers.

Use Apptentive features to improve your app's App Store ratings, collect and respond to customer feedback, show surveys at specific points within your app, and more.

## Install Guide

Apptentive can be installed manually as an Xcode subproject or via the dependency manager CocoaPods.

The following guides explain the integration process:

 - [Xcode project setup guide](http://www.apptentive.com/docs/ios/setup/xcode/)
 - [CocoaPods installation guide](http://www.apptentive.com/docs/ios/setup/cocoapods)
 
 As of version 3.3.1, we also support Carthage. 

## Using Apptentive in your App

After integrating the Apptentive SDK into your project, you can [begin using Apptentive features in your app](http://www.apptentive.com/docs/ios/integration/).

To begin using the SDK, import the SDK and create a configuration object with your Apptentive App Key and Apptentive App Signature (found in the [API section of your Apptentive dashboard](https://be.apptentive.com/apps/current/settings/api)).

``` objective-c
@import Apptentive;
...
ApptentiveConfiguration = [ApptentiveConfiguration configurationWithApptentiveKey:@"<#Your Apptentive App Key#>" apptentiveSignature:@"<#Your Apptentive App Signature#>"];
[Apptentive registerWithConfiguration:configuration];
...
[Apptentive.shared engage:@"event_name", from: viewController];
```

Or, in Swift:

``` Swift
import Apptentive
...
if let configuration = ApptentiveConfiguration(apptentiveKey: "<#Your Apptentive App Key#>", apptentiveSignature: "<#Your Apptentive App Signature#>") {
	Apptentive.register(with: configuration)
}
...
Apptentive.shared.engage(event: "event_name", from: viewController)
```

Later, on your Apptentive dashboard, you will target these events with Apptentive features such as Message Center, Ratings Prompts, and Surveys.

Please see our [iOS integration guide](http://www.apptentive.com/docs/ios/integration/) for more on this subject.

## API Documentation

Please see our docs site for the Apptentive iOS SDK's [API documentation](http://www.apptentive.com/docs/ios/api/Classes/Apptentive.html).

Apptentive's [API changelog](docs/APIChanges.md) is also updated with each release of the SDK.

## Testing Apptentive Features

Please see the [Apptentive testing guide](http://www.apptentive.com/docs/ios/testing/) for directions on how to test that the Rating Prompt, Surveys, and other Apptentive features have been configured correctly.

# Apptentive Example App

To see an example of how the Apptentive iOS SDK can be integrated with your app, take a look at the `iOSExample` app in the `Example` directory in this repository.

The example app shows you how to integrate using CocoaPods, set your Apptentive App Key and Apptentive App Signature, engage events, and integrate with Message Center. See the `README.md` file in the `Example` directory for more information.

## Contributing

Our client code is completely [open source](LICENSE.txt), and we welcome contributions to the Apptentive SDK! If you have an improvement or bug fix, please first read our [contribution agreement](CONTRIBUTING.md).

## Reporting Issues

If you experience an issue with the Apptentive SDK, please [open a GitHub issue](https://github.com/apptentive/apptentive-ios/issues?direction=desc&sort=created&state=open).

If the request is urgent, please contact <mailto:support@apptentive.com>.
