//
//  ATInteractionUpgradeMessageViewController.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 10/16/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ATInteraction;

@interface ATInteractionUpgradeMessageViewController : UIViewController

@property (nonatomic, retain) ATInteraction *upgradeMessageInteraction;

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet UIView *contentView;
@property (nonatomic, retain) IBOutlet UIImageView *appIconView;
@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) IBOutlet UIView *okButtonBackgroundView;
@property (nonatomic, retain) IBOutlet UIImageView *poweredByApptentiveIconView;

@property (nonatomic, retain)UIImage *backgroundImage;
@property (nonatomic, retain) IBOutlet UIImageView *backgroundImageView;

- (id)initWithInteraction:(ATInteraction *)interaction;

- (IBAction)okButtonPressed:(id)sender;

@end
