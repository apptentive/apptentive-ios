# Apptentive iOS SDK

The Apptentive iOS SDK provides a simple and powerful channel to communicate in-app with your customers.

Use Apptentive features to improve your app's App Store ratings, collect and respond to customer feedback, show surveys at specific points within your app, and more.

See our [Quick Start Guide](https://learn.apptentive.com/knowledge-base/ios-quick-start/) to get up and running as quickly as possible. 

For complete information on installing and using Apptentive, please see our [iOS integration reference](https://learn.apptentive.com/knowledge-base/ios-integration-reference/).

## Installation

Apptentive can be installed using CocoaPods or Carthage, or manually as an Xcode subproject. 

 - [CocoaPods installation guide](https://learn.apptentive.com/knowledge-base/ios-integration-reference/#cocoapods)
 - [Carthage installation guide](https://learn.apptentive.com/knowledge-base/ios-integration-reference/#carthage)
 - [Xcode project setup guide](https://learn.apptentive.com/knowledge-base/ios-integration-reference/#subproject)

## Using Apptentive in your App

To begin, you will have to [initialize the Apptentive SDK](https://learn.apptentive.com/knowledge-base/ios-integration-reference/#initialize-apptentive):

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

## API Documentation

Please see our Customer Learning Center for the Apptentive iOS SDK's [API documentation](https://learn.apptentive.com/knowledge-base/ios-sdk-api/).

Apptentive's [API changelog](docs/APIChanges.md) is also updated with each release of the SDK.

## Testing Apptentive Features

Please see the [Apptentive testing guide](https://learn.apptentive.com/knowledge-base/testing-your-apptentive-integration-ios/) for directions on how to test that the Rating Prompt, Surveys, and other Apptentive features have been configured correctly.

# Apptentive Example App

To see an example of how the Apptentive iOS SDK can be integrated with your app, take a look at the `iOSExample` app in the `Example` directory in this repository.

The example app shows you how to integrate using CocoaPods, set your Apptentive App Key and Apptentive App Signature, engage events, and integrate with Message Center. See the `README.md` file in the `Example` directory for more information.

## Contributing

Our client code is completely [open source](LICENSE.txt), and we welcome contributions to the Apptentive SDK! If you have an improvement or bug fix, please first read our [contribution agreement](CONTRIBUTING.md).

## Reporting Issues

If you experience an issue with the Apptentive SDK, please [open a GitHub issue](https://github.com/apptentive/apptentive-ios/issues?direction=desc&sort=created&state=open).

If the request is urgent, please contact <mailto:support@apptentive.com>.
