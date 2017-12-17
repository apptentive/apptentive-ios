# Migration to Apptentive v5.0.0

If you have integrated a previous version of the Apptentive SDK, you will need to keep in mind the following changes in our version 4.0.0 release. For more information, please see our [Integration Reference](https://learn.apptentive.com/knowledge-base/ios-integration-reference/).

## New Asynchronous `engage` Methods

The `engage` methods no longer return a boolean value indicating whether an interaction was presented in response to the event being engaged. Instead, there are versions of each method that accept a completion handler that will be called with that result. 

For example, where previously you might have done the following:

```
let didShowMessageCenter = Apptentive.shared.presentMessageCenter(from: self)

if !didShowMessageCenter {
	print("message center was not shown")
}
```

You would now write:

```
Apptentive.shared.presentMessageCenter(from: self.window!.rootViewController!) { (success) in
	if !success {
		print("message center was not shown")
	}
}
```

Likewise the `canShowInteraction(forEvent:)` and `canShowMessageCenter()` methods were replaced by `queryCanShowInteraction(forEvent:,completion:)` and `queryCanShowMessageCenter(completion:)`. For example, to enable a Message Center button if Message Center is available, you could use code like the following: 

```
Apptentive.shared.queryCanShowMessageCenter { (canShow) in
	if canShow {
		// enable message center button
	}
}
```

## New `UNUserNotificationCenter` methods

You can use the User Notifications framework in your apps that target iOS 10 and later. 

If your app does not use push or local notifications for purposes other than Apptentive, you can simply set the current user notification center's delegate property to the Apptentive singleton:

```
UNUserNotificationCenter.current().delegate = Apptentive.shared
```

Alternative, if your app needs to respond to non-Apptentive push and local notifications, you can forward them as follows:

```
func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    // Pass in a view controller, or nil to have Apptentive create a new window for Message Center
	let handledByApptentive = Apptentive.shared.didReceveUserNotificationResponse(response, from: viewController, withCompletionHandler: completionHandler)

	if (!handledByApptentive) {
		// Handle the notification
		completionHandler()
	}
}

func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
	let handledByApptentive = Apptentive.shared.willPresent(notification, withCompletionHandler: completionHandler)

	if (!handledByApptentive) {
		// Decide how to present the notification
		completionHandler(.alert)
	}
}
```

Please note that in both cases you will still need to forward remote notifications to Apptentive for Apptentive push to work. 

