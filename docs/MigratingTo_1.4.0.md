# Migration to Apptentive v1.4.0

If you have integrated a previous version of Apptentive's ratings, you will need to migrate to our new
**Interaction** and **Event** based API. The new API provides a generic interface through which all future
**Interactions** will be displayed.

## Ratings

### Displaying Ratings

The previous method for showing the rating flow, `showRatingFlowFromViewControllerIfConditionsAreMet:`, has been deprecated. You will need to replace it with a call to `engage:fromViewController:`. The parameter `eventLabel` is a string that identifies each specific place in your code where you call `engage:`.

Rather than calling `showRatingFlowFromViewControllerIfConditionsAreMet:`, you should now seed your app with a variety of events. Then, on the Apptentive dashboard, you will create a Rating Prompt Interaction and target it to run in response to one of the events that you have created.

By default, the new Ratings Prompt will be triggered by the `init` event:

	[[ATConnect sharedConnection] engage:@"init" fromViewController:self];

You can alternately target it to another event in your app, such as "completed_level" or "logged_in", via your Apptentive dashboard.

### Logging Significant Events

If you were previously using `logSignificantEvent` to guide the Rating Prompt, you will instead need to log unique significant events using the `engage:fromViewController:` method as described above.

Multiple unique types of events can now be used to determine if an Interaction, such as the Rating Prompt, should be shown. That interaction could be run only for people who have triggered the events "logged_in" AND "completed_in_app_purchase". The now-deprecated `logSignificantEvent` was a single counter of significant events; the new system is much more powerful.

### Setting  up Interactions on the website

Any previous Ratings Prompt configuration settings on the server have been migrated to use the new system. Old SDKs will continue to
work for previous client versions. In order to use the new system, you will need go to *Interactions -> Ratings Prompt*,
and then select *Who &amp; When*. You will notice that these settings are almost identical to the previous settings.
However, you will need to select the name of the event which will display the Ratings Prompt under *When will this
be shown?*. If you are targeting significant events, you will also need to enable this event in the *The ratings prompt
will be displayed if:* section.

If you are trying to configure the Ratings Prompt with events, and you have never sent the intended events to the server,
you can manually add them so that they can be used in the Ratings Prompt configuration. Simply go to *Interactions ->
Events*, and enter the new event names. Events that have been recorded by your app will also appear in this list.

**Note:** The old Ratings Prompt settings required you to use a value of zero to turn off each piece of the ratings
logic. The new Ratings Prompt logic will treat a zero value literally. To turn it off, simply uncheck the appropriate
field.

##### Server Configuration

![Using Custom Events](https://raw.githubusercontent.com/skykelsey/apptentive-android/rating_interaction_docs/etc/screenshots/ratings_prompt_interaction_config.png)

## Upgrade Messages

Prior to version 1.4.0, Upgrade Messages were displayed using the "app.launch" event. Starting with 1.4.0, Upgrade Messages will instead be targeted to the "init" event, which should be logged when your app's UI is finished initializing. If you previously used Upgrade Messages with an older version of the SDK, please ensure that the "init" event is logged and that you have tested displaying Upgrade Messages.

## Surveys

Prior to version 1.5.0, Surveys were displayed using `presentSurveyControllerWithTags:fromViewController:`. You would pass in a set of tags and, if the tags matched an available survey, a survey with those tags would be displayed.

In version 1.5.0, Surveys have moved entirely to the Engagement Framework. Like all other interactions, Surveys are created on the Apptentive website and targeted at an *event* you log with `engage:fromViewController`.

The previous methods for showing a survey, `presentSurveyControllerWithNoTagsFromViewController:` and `presentSurveyControllerWithTags:fromViewController:`, have been deprecated. You will need to replace them in 1.5.0 with a call to `engage:fromViewController:`.

Rather than using Tags to segment surveys, you will now use the logic editor on the Apptentive website. You can target a survey using a variety of device and person attributes. You can also show the survey only to people who have logged a certain number of events.

For example, you might have previously created a survey with the tags "hasEmail", "completedInAppPurchase", and "completedGame":

	[ATSurveys presentSurveyControllerWithTags:[NSSet setWithArray:@[@"hasEmail", @"completedInAppPurchase", @"completedGame"]] fromViewController:viewController];

In the new system, you do not need to log those tags when you want to show the survey. Instead, you should create an event when you may want to present a survey:  

	[[ATConnect sharedConnection] engage:@"completedGame" fromViewController:viewController];

Then, on the Apptentive website, create a survey targeted at the event "completedGame". Use the logic editor to set the conditions for showing that survey:

 - Player has an email address.
 - Player has hit the "completedInAppPurchase" event at least once.
 
By moving the survey invocation to a single event, and the survey conditions to the event logic editor, you are now better able to target surveys without re-releasing to the App Store.
