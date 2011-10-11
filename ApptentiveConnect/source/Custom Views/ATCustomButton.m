//
//  ATCustomButton.m
//  CustomWindow
//
//  Created by Andrew Wooster on 9/24/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import "ATCustomButton.h"
#import "ATBackend.h"
#import <QuartzCore/QuartzCore.h>

@implementation ATCustomButton

- (id)initWithButtonStyle:(ATCustomButtonStyle)style {
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	if (style == ATCustomButtonStyleCancel) {
		[button setTitle:NSLocalizedString(@"Cancel", @"Cancel button title") forState:UIControlStateNormal];
		button.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
		button.titleLabel.shadowOffset = CGSizeMake(0.0, 1.0);
		
		[button setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[button setTitleColor:[UIColor colorWithRed:130./256. green:130./256. blue:130./256. alpha:1.0] forState:UIControlStateNormal];
		//[button setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
		[button setBackgroundImage:[ATBackend imageNamed:@"at_cancel_bg"] forState:UIControlStateNormal];
		[button setBackgroundImage:[ATBackend imageNamed:@"at_cancel_highlighted_bg"] forState:UIControlStateHighlighted];
		button.layer.cornerRadius = 4.0;
		button.layer.masksToBounds = YES;
		button.layer.borderWidth = 0.5;
		button.layer.borderColor = [UIColor colorWithRed:171./256. green:171./256. blue:171./256. alpha:1.0].CGColor;
		button.layer.shadowColor = [UIColor whiteColor].CGColor;
		button.layer.shadowOffset = CGSizeMake(0.0, 1.0);
		button.layer.shadowRadius = 2.0;
		CGSize s = [button.titleLabel.text sizeWithFont:button.titleLabel.font];
		[button sizeToFit];
		CGRect f = [button frame];
		f.size.height = 30.0;
		f.size.width = s.width + 20.0;
		button.frame = f;
	}
	
	
	self = [super initWithCustomView:button];
	[button release], button = nil;
	if (self) {
		
	}
	return self;
}

- (void)setAction:(SEL)action forTarget:(id)target {
	if ([[self customView] isKindOfClass:[UIButton class]]) {
		UIButton *button = (UIButton *)[self customView];
		[button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
	}
}
@end
