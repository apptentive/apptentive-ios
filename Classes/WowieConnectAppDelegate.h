//
//  WowieConnectAppDelegate.h
//  WowieConnect
//
//  Created by Michael Saffitz on 12/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WowieConnectViewController;

@interface WowieConnectAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    WowieConnectViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet WowieConnectViewController *viewController;

@end
