//
//  AppDelegate.m
//  FeedbackDemo
//
//  Created by Frank Schmitt on 4/30/15.
//  Copyright (c) 2015 Apptentive. All rights reserved.
//

#import "AppDelegate.h"
#import "ATConnect.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#warning Please set your API key and app ID before running.
	// To find your API key, log into http://be.apptentive.com/,
	// select your app, click Settings, and click API & Development.
	[ATConnect sharedConnection].apiKey = @"ApptentiveApiKey";
	
	// To find your app ID, log into http://itunesconnect.apple.com/,
	// click My Apps, select an app, and look for its Apple ID.
	[ATConnect sharedConnection].appID = @"ExampleAppID";
	
	return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Warn developer if API key or app ID are not set.
	if ([[ATConnect sharedConnection].apiKey isEqualToString:@"ApptentiveApiKey"]) {
		[[[UIAlertView alloc] initWithTitle:@"Please Set API Key" message:@"This demo app will not work properly until you set your API key in AppDelegate.m" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
	} else if ([[ATConnect sharedConnection].appID isEqualToString:@"ExampleAppID"]) {
		[[[UIAlertView alloc] initWithTitle:@"Please Set App ID" message:@"This demo app won't be able to show your app in the app store until you set your App ID in AppDelegate.m" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
	}
}

@end
