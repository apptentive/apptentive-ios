//
//  ATMessagePanelNewUIViewController.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 12/3/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATMessagePanelViewController.h"

@interface ATMessagePanelNewUIViewController : ATMessagePanelViewController {
	// Used when handling view rotation.
	CGRect lastSeenPresentingViewControllerFrame;
	CGAffineTransform lastSeenPresentingViewControllerTransform;
}

@property (nonatomic, strong) IBOutlet UIImageView *backgroundImageView;
@property (nonatomic, strong) IBOutlet UIView *buttonFrame;
@property (nonatomic, strong) IBOutlet UIButton *sendButtonNewUI;
@property (nonatomic, strong) IBOutlet UIView *sendButtonPadding;
@property (nonatomic, strong) IBOutlet UIButton *cancelButtonNewUI;
@property (nonatomic, strong) IBOutlet UIView *cancelButtonPadding;

@end
