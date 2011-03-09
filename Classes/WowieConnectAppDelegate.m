//
//  WowieConnectAppDelegate.m
//  WowieConnect
//
//  Created by Michael Saffitz on 12/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "WowieConnectAppDelegate.h"

#import "WowieConnectViewController.h"
#import "WowieConnect.h"

@implementation WowieConnectAppDelegate


@synthesize window;
@synthesize viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // Override point for customization after application launch.
     
    [WowieConnect sharedInstanceWithAppKey:@"foo" andSecret:@"bar"];
    NSLog(@"done setting app key");
    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {

    // Save data if appropriate.
}

- (void)dealloc {

    [window release];
    [viewController release];
    [super dealloc];
}

@end
