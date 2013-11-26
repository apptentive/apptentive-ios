//
//  ATTextMessageDevCellV7.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/23/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "ATTextMessageDevCellV7.h"
#import "ATBackend.h"
#import "ATMessageSender.h"

@implementation ATTextMessageDevCellV7
- (void)setup {
	NSMutableAttributedString *s = [[NSMutableAttributedString alloc] init];
	if (self.message.body) {
		NSDictionary *attrs = @{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleBody]};
		NSAttributedString *body = [[[NSAttributedString alloc] initWithString:self.message.body attributes:attrs] autorelease];
		[s appendAttributedString:body];
	}
	self.messageLabel.attributedText = s;
	[s release], s = nil;
	
	self.textContainerView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.7];
	self.textContainerView.layer.cornerRadius = 6;
	
	self.userIconView.image = [ATBackend imageNamed:@"at_mc_user_icon"];
	self.userIconView.imageURL = [NSURL URLWithString:self.message.sender.profilePhotoURL];
	self.userIconView.layer.cornerRadius = self.userIconView.bounds.size.width*0.5;
	self.userIconView.layer.masksToBounds = YES;
	
	self.messageLabel.delegate = self;
	UIDataDetectorTypes types = UIDataDetectorTypeLink;
	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://"]]) {
		types |= UIDataDetectorTypePhoneNumber;
	}
	self.messageLabel.dataDetectorTypes = types;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	[self setup];
}

- (void)dealloc {
	[_textContainerView release];
	[_messageLabel release];
	[_userIconView release];
	[super dealloc];
}

- (void)setMessage:(ATTextMessage *)message {
	if (_message != message) {
		[_message release], _message = nil;
		_message = [message retain];
		
		[self setup];
	}
}

#pragma mark TTTAttributedLabelDelegate
- (void)attributedLabel:(ATTTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
	if ([[UIApplication sharedApplication] canOpenURL:url]) {
		[[UIApplication sharedApplication] openURL:url];
	}
}

- (void)attributedLabel:(TTTATTRIBUTEDLABEL_PREPEND(TTTAttributedLabel) *)label
didSelectLinkWithPhoneNumber:(NSString *)phoneNumber {
	NSString *phoneString = [NSString stringWithFormat:@"tel:%@", phoneNumber];
	NSURL *url = [NSURL URLWithString:phoneString];
	if ([[UIApplication sharedApplication] canOpenURL:url]) {
		[[UIApplication sharedApplication] openURL:url];
	}
}
@end
