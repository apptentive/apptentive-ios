//
//  FeedbackDemoAppDelegate.m
//  FeedbackDemo
//
//  Created by Andrew Wooster on 3/18/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "FeedbackDemoAppDelegate.h"
#import "ATConnect.h"
#import "ATAppRatingFlow.h"
#import "defines.h"
#import "ATSurveys.h"

@implementation FeedbackDemoAppDelegate
@synthesize window=_window;

@synthesize navigationController=_navigationController;
- (void)resetApptentiveRatings {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults removeObjectForKey:@"ATAppRatingFlowRatedAppKey"];
	[defaults removeObjectForKey:@"ATAppRatingFlowDeclinedToRateThisVersionKey"];
	[defaults removeObjectForKey:@"ATAppRatingFlowUserDislikesThisVersionKey"];
	[defaults removeObjectForKey:@"ATAppRatingFlowLastUsedVersionKey"];
	[defaults removeObjectForKey:@"ATAppRatingFlowLastPromptDateKey"];
	[defaults synchronize];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	[self resetApptentiveRatings];
	// Override point for customization after application launch.
	// Add the navigation controller's view to the window and display.
	if ([self.window respondsToSelector:@selector(setRootViewController:)]) {
		[self.window setRootViewController:self.navigationController];
	} else {
		[self.window addSubview:self.navigationController.view];
	}
	[self.window makeKeyAndVisible];
	[[ATConnect sharedConnection] setApiKey:kApptentiveAPIKey];
	
	[[ATConnect sharedConnection] addIntegration:@"feedback_demo_integration_configuration" withConfiguration:@{@"fake_apiKey": @"ABC-123-XYZ"}];
	
	ATAppRatingFlow *flow = [ATAppRatingFlow sharedRatingFlowWithAppID:kApptentiveAppID];
	[flow showRatingFlowFromViewControllerIfConditionsAreMet:self.navigationController];
	
	double delayInSeconds = 2.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		BOOL didEngageInteraction = [[ATConnect sharedConnection] engage:@"app.launch" fromViewController:self.navigationController];
		if (didEngageInteraction) {
			NSLog(@"Successfully engaged an interaction for code point \"app.launch\"");
		} else {
			NSLog(@"Did not engage any interactions for code point \"app.launch\"");
		}
	});
	
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
	/*
	 Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	 Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	 */
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	/*
	 Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	 If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	 */
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	/*
	 Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	 */
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	/*
	 Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	 */
	[[ATAppRatingFlow sharedRatingFlow] showRatingFlowFromViewControllerIfConditionsAreMet:self.navigationController];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	/*
	 Called when the application is about to terminate.
	 Save data if appropriate.
	 See also applicationDidEnterBackground:.
	 */
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [[ATConnect sharedConnection] didReceiveRemoteNotification:userInfo fromViewController:self.navigationController];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
	[[ATConnect sharedConnection] didReceiveRemoteNotification:userInfo fromViewController:self.navigationController];
}

- (void)dealloc {
	[_window release], _window = nil;
	[_navigationController release], _navigationController = nil;
	[super dealloc];
}
@end
