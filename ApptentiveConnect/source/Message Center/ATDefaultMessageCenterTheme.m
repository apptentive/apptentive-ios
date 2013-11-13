//
//  ATDefaultMessageCenterTheme.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/24/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATDefaultMessageCenterTheme.h"

#import "ATBackend.h"
#import "ATDefaultMessageCenterTitleView.h"
#import "ATUtilities.h"

@implementation ATDefaultMessageCenterTheme
- (UIView *)titleViewForMessageCenterViewController:(ATMessageCenterBaseViewController *)vc {
	return [[[ATDefaultMessageCenterTitleView alloc] initWithFrame:vc.navigationController.navigationBar.bounds] autorelease];
}

- (void)configureSendButton:(UIButton *)sendButton forMessageCenterViewController:(ATMessageCenterViewController *)vc {
	if ([ATUtilities osVersionGreaterThanOrEqualTo:@"7"]) {
		[sendButton setTitleColor:nil forState:UIControlStateNormal];
		[sendButton setTitleShadowColor:nil forState:UIControlStateNormal];
	} else {
		UIImage *sendImageBase = [ATBackend imageNamed:@"at_send_button_flat"];
		UIImage *sendImage = nil;
		if ([sendImageBase respondsToSelector:@selector(resizableImageWithCapInsets:)]) {
			sendImage = [sendImageBase resizableImageWithCapInsets:UIEdgeInsetsMake(12, 49, 13, 13)];
		} else {
			sendImage = [sendImageBase stretchableImageWithLeftCapWidth:49 topCapHeight:12];
		}
		[sendButton setBackgroundImage:sendImage forState:UIControlStateNormal];
		[sendButton.titleLabel setShadowOffset:CGSizeMake(0, 1)];
		[sendButton setTitleColor:[UIColor colorWithWhite:0.0 alpha:0.7] forState:UIControlStateNormal];
		[sendButton setTitleShadowColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateNormal];
		[sendButton setTitleShadowColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateDisabled];
		[sendButton setTitleColor:[UIColor colorWithWhite:0.0 alpha:0.3] forState:UIControlStateDisabled];
		//[sendButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateDisabled];
	}
}

- (void)configureAttachmentsButton:(UIButton *)button forMessageCenterViewController:(ATMessageCenterBaseViewController *)vc {
	[button setTitle:@"" forState:UIControlStateNormal];
	
	if ([ATUtilities osVersionGreaterThanOrEqualTo:@"7"]) {
		UIImage *cameraImage = [[ATBackend imageNamed:@"at_camera_button_v7"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
		[button setImage:cameraImage forState:UIControlStateNormal];
	} else {
		[button setImage:[ATBackend imageNamed:@"at_plus_button_flat"] forState:UIControlStateNormal];
	}
}

- (UIImage *)backgroundImageForMessageForMessageCenterViewController:(ATMessageCenterBaseViewController *)vc {
	UIImage *flatInputBackgroundImage = [ATBackend imageNamed:@"at_flat_input_bg"];
	UIEdgeInsets capInsets = UIEdgeInsetsMake(16, 44, flatInputBackgroundImage.size.height - 16 - 1, flatInputBackgroundImage.size.width - 44 - 1);
	
	UIImage *resizableImage = nil;
	if ([flatInputBackgroundImage respondsToSelector:@selector(resizableImageWithCapInsets:)]) {
		resizableImage = [flatInputBackgroundImage resizableImageWithCapInsets:capInsets];
	} else {
		resizableImage = [flatInputBackgroundImage stretchableImageWithLeftCapWidth:capInsets.left topCapHeight:capInsets.top];
	}
	return resizableImage;
}
@end
