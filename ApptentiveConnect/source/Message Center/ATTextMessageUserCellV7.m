//
//  ATTextMessageUserCellV7.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/14/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "ATTextMessageUserCellV7.h"
#import "ATBackend.h"
#import "ATMessageSender.h"

@implementation ATTextMessageUserCellV7
- (void)setup {
	NSMutableAttributedString *s = [[NSMutableAttributedString alloc] init];
	if (self.message.body) {
		NSDictionary *attrs = @{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleBody]};
		NSAttributedString *body = [[[NSAttributedString alloc] initWithString:self.message.body attributes:attrs] autorelease];
		[s appendAttributedString:body];
	}
	self.textView.attributedText = s;
	[s release], s = nil;
	
	self.textContainerView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.7];
	self.textContainerView.layer.cornerRadius = 6;
	
	self.userIconView.image = [ATBackend imageNamed:@"at_mc_user_icon"];
	self.userIconView.imageURL = [NSURL URLWithString:self.message.sender.profilePhotoURL];
	self.userIconView.layer.cornerRadius = self.userIconView.bounds.size.width*0.5;
	self.userIconView.layer.masksToBounds = YES;
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
	[_textView release];
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

- (CGFloat)cellHeightForWidth:(CGFloat)width {
	static CGFloat textDiff = -1;
	if (textDiff == -1) {
		CGRect textRectAbsolute = [self convertRect:self.textView.frame fromView:self.textView.superview];
		CGFloat textWidthDiff = textRectAbsolute.origin.x + (self.bounds.size.width - CGRectGetMaxX(textRectAbsolute));
		textDiff = textWidthDiff;
	}
	CGSize textViewSize = [self.textView sizeGivenWidth:width - textDiff];
	return MAX(textViewSize.height + 12, 58);
}
@end
