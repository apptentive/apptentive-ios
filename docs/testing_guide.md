# Testing your Apptentive integration



## Dedicated test API key

We recommend using a dedicated test API key when exploring Apptentive features.

Create a new app on your Apptentive dashboard, then find its API key in your app settings. Set the test API key in your iOS project:  

	[ATConnect sharedConnection].apiKey = @"your_test_api_key";

Using the test API key will allow you to modify Apptentive settings without fear of annoying the users of your live app.

## Testing the Rating Prompt

#### Set criteria and limits

When your app is live and in the hands of customers, you won't want to annoy them with a rating prompt the first time they open the app. Your settings should prevent the rating prompt from being shown too early or if the person has not frequently used your app.

These safe rating ratings prompts work well in the App Store, but they're very hard to test. You don't want to wait 3 days to see your prompt.

Instead, on you Test account, select criteria that are easier to trigger:  

	[SCREENSHOT]

Setting the "days after install" and "app launches" to 1 will ensure that the rating prompt is shown the first time its event is engaged.

#### Target the Rating Prompt to an Event

Engage a new event in your application, "test_event":  

	[[ATConnect sharedConnection] engage:@"test_event" fromViewController:viewController];

Run your app, then engage the event by calling the above method. The best way to accomplish this is to hook the method up to a button in your app that you can easily press at will.

Once a single instance of your event has been recorded, you can target a rating prompt to that event. Select the Rating Prompt from your dashboard's Interaction's tab. In the "Who & When" section, you can now select "test_event" from the event target menu:

![Target a rating prompt to an event.](https://raw.github.com/apptentive/apptentive-ios/readme/etc/screenshots/rating_prompt_target_event.png)


#### Trigger the Rating Prompt

Start by reseting your iOS simulator and/or deleting the app from your device. This ensures that only new data is used.

Be sure to set ATConnect's `apiKey` to the Test app API key you set up previously.

Run the app, and wait approximately 30 seconds for your Apptentive settings to be downloaded.

Now, engage your test event:  

	[[ATConnect sharedConnection] engage:@"test_event" fromViewController:viewController];

You should see the rating prompt pop up. "Do you love app_name?"


## Testing Surveys

Surveys are easier to test, as they do not have the same complicated logic as the rating prompt.

Create a new survey via your Apptentive dashboard. When creating the survey you will be prompted to target the survey to a particular event:  

![Target a survey to an event.](https://raw.github.com/apptentive/apptentive-ios/readme/etc/screenshots/survey_target_event.png)

As with the rating prompt, you will engage this same event in your app to trigger the survey:  

	[[ATConnect sharedConnection] engage:@"completed_in_app_purchase" fromViewController:viewController];

Reset your iOS simulator and delete the app from your device to force a refresh of the Apptentive cache. When you run the app again, the new survey you created will be downloaded to your device.

Engaging the target event should then display the survey
