//
//  ATAutomatedMessageCellV7.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/12/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "ATAutomatedMessageCellV7.h"

#import "ATBackend.h"
#import "ATUtilities.h"

@implementation ATAutomatedMessageCellV7
- (void)setup {
	NSMutableAttributedString *s = [[NSMutableAttributedString alloc] init];
	if (self.message.title) {
		NSDictionary *attrs = @{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]};
		NSAttributedString *title = [[[NSAttributedString alloc] initWithString:self.message.title attributes:attrs] autorelease];
		[s appendAttributedString:title];
		if (self.message.body) {
			NSAttributedString *newline = [[[NSAttributedString alloc] initWithString:@"\n" attributes:attrs] autorelease];
			[s appendAttributedString:newline];
		}
	}
	if (self.message.body) {
		NSDictionary *attrs = @{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleBody]};
		NSAttributedString *body = [[[NSAttributedString alloc] initWithString:self.message.body attributes:attrs] autorelease];
		[s appendAttributedString:body];
	}
	self.messageLabel.attributedText = s;
	[s release], s = nil;
	
	if (self.message && !self.appIcon.image) {
		[self.appIcon setImage:[ATUtilities appIcon]];
		// Rounded corners
		UIImage *maskImage = [ATBackend imageNamed:@"at_update_icon_mask"];
		CALayer *maskLayer = [[CALayer alloc] init];
		maskLayer.contents = (id)maskImage.CGImage;
		maskLayer.frame = (CGRect){CGPointZero, self.appIcon.bounds.size};
		self.appIcon.layer.mask = maskLayer;
		[maskLayer release], maskLayer = nil;
	}
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
	[_messageLabel release];
	[_appIcon release];
	[super dealloc];
}

- (void)setMessage:(ATAutomatedMessage *)message {
	if (_message != message) {
		[_message release], _message = nil;
		_message = [message retain];
		
		[self setup];
	}
}
@end
