//
//  ATMessageCenterInputView.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 7/14/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATMessageCenterInputView.h"

@implementation ATMessageCenterInputView

- (void)awakeFromNib {
	self.containerView.layer.borderColor = [UIColor colorWithRed:200.0/255.0 green:199.0/255.0 blue:204.0/255.0 alpha:1.0].CGColor;
	self.sendBar.layer.borderColor = [UIColor colorWithRed:200.0/255.0 green:199.0/255.0 blue:204.0/255.0 alpha:1.0].CGColor;
	
	self.containerView.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
	self.sendBar.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
}

@end
