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

@implementation ATDefaultMessageCenterTheme
- (UIView *)titleViewForMessageCenterViewController:(ATMessageCenterViewController *)vc {
	return [[[ATDefaultMessageCenterTitleView alloc] initWithFrame:vc.navigationController.navigationBar.bounds] autorelease];
}

- (void)configureSendButton:(UIButton *)sendButton forMessageCenterViewController:(ATMessageCenterViewController *)vc {
	UIImage *sendImage = [[ATBackend imageNamed:@"at_send_button_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(13, 13, 13, 13)];
	[sendButton setBackgroundImage:sendImage forState:UIControlStateNormal];
	[sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[sendButton.titleLabel setShadowOffset:CGSizeMake(0, -1)];
	[sendButton setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.4] forState:UIControlStateDisabled];
}
@end
