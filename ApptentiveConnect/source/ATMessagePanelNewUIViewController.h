//
//  ATMessagePanelNewUIViewController.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 12/3/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATMessagePanelViewController.h"

NSString *const ATMessagePanelPresentingViewControllerSwizzledDidRotateNotification;

@interface ATMessagePanelNewUIViewController : ATMessagePanelViewController {
	// Used when handling view rotation.
	CGRect lastSeenPresentingViewControllerFrame;
	CGAffineTransform lastSeenPresentingViewControllerTransform;
}

@property (nonatomic, retain) IBOutlet UIImageView *backgroundImageView;
@property (nonatomic, retain) IBOutlet UIView *buttonFrame;
@property (nonatomic, retain) IBOutlet UIButton *sendButtonNewUI;
@property (nonatomic, retain) IBOutlet UIView *sendButtonPading;
@property (nonatomic, retain) IBOutlet UIButton *cancelButtonNewUI;
@property (nonatomic, retain) IBOutlet UIView *cancelButtonPading;

@end
