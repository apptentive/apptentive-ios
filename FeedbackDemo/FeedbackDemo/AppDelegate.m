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
    if ([self setupTestFlight]) {
        return YES;
    }
    
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
    [self showAPIKeyWarning];
    
    // Uncomment the following line to register for Push Notifications in the Feedback Demo app
    //[self registerForRemoteNotifications];
}

- (BOOL)setupTestFlight {
    NSDictionary *plist = [[NSBundle mainBundle] infoDictionary];
    
    NSString *testFlightAPIKey = plist[@"ATTestFlightAPIKey"];
    if (testFlightAPIKey) {
        [ATConnect sharedConnection].apiKey = testFlightAPIKey;
        
        [self registerForRemoteNotifications];
    }
    
    NSString *testFlightAppID = plist[@"ATTestFlightAppIDKey"];
    if (testFlightAppID) {
        [ATConnect sharedConnection].appID = testFlightAppID;
    }
    
    return (testFlightAPIKey != nil);
}

- (void)showAPIKeyWarning {
    if ([[ATConnect sharedConnection].apiKey isEqualToString:@"ApptentiveApiKey"]) {
        NSLog(@"---");
        NSLog(@"---");
        NSLog(@"Please set Apptentive API Key! This demo app will not work properly until you set your API key in AppDelegate.m");
        NSLog(@"---");
        NSLog(@"---");
    }
    
    if ([[ATConnect sharedConnection].appID isEqualToString:@"ExampleAppID"]) {
        NSLog(@"---");
        NSLog(@"---");
        NSLog(@"Please Set App ID! This demo app won't be able to show your app in the app store until you set your App ID in AppDelegate.m");
        NSLog(@"---");
        NSLog(@"---");
    }
}

- (void)registerForRemoteNotifications {
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert categories:nil];
        
        [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
    } else {
        UIRemoteNotificationType notificationTypes = UIRemoteNotificationTypeAlert;
        
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:notificationTypes];
    }
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Enable Push Notifications for New Messages
    [[ATConnect sharedConnection] setPushNotificationIntegration:ATPushProviderApptentive withDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Failed to Register for Remote Notifications with Error: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    UIViewController *viewController = self.window.rootViewController;
    
    BOOL apptentiveNotification = [[ATConnect sharedConnection] didReceiveRemoteNotification:userInfo fromViewController:viewController];
    
    if (!apptentiveNotification) {
        // If the notification did not come from Apptentive, you should handle it yourself.
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    UIViewController *viewController = self.window.rootViewController;
    
    BOOL apptentiveNotification = [[ATConnect sharedConnection] didReceiveRemoteNotification:userInfo fromViewController:viewController fetchCompletionHandler:completionHandler];
    
    if (apptentiveNotification) {
        // If the notification came from Apptentive, the `completionHandler` block will be called automatically.
    } else {
        // If the notification did not come from Apptentive, you are responsible for calling the `completionHandler` block.
        completionHandler(UIBackgroundFetchResultNoData);
    }
}
 
@end
