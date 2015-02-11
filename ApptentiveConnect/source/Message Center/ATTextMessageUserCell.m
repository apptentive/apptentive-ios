//
//  ATTextMessageUserCell.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/9/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "ATTextMessageUserCell.h"
#import "ATUtilities.h"

@implementation ATTextMessageUserCell {
	CGFloat horizontalCellPadding;
}

@synthesize dateLabel, chatBubbleContainer, userIcon, messageBubbleImage, usernameLabel, messageText, composingBubble, composing, showDateLabel, tooLong;
@synthesize cellType;

- (void)setup {
	horizontalCellPadding = CGRectGetWidth(self.bounds) - CGRectGetWidth(self.messageText.bounds);
	
	self.messageText.delegate = self;
	NSTextCheckingType types = NSTextCheckingTypeLink;
	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://"]]) {
		types |= NSTextCheckingTypePhoneNumber;
	}
	if ([ATUtilities osVersionGreaterThanOrEqualTo:@"5"]) {
		self.messageText.enabledTextCheckingTypes = types;
	}
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) {
		[self setup];
	}
	return self;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	[self setup];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	[super setSelected:selected animated:animated];

	// Configure the view for the selected state
}

- (void)setComposing:(BOOL)comp {
	if (composing != comp) {
		composing = comp;
		if (composing) {
			self.showDateLabel = NO;
		}
		[self setNeedsLayout];
	}
}

- (void)setShowDateLabel:(BOOL)show {
	if (showDateLabel != show) {
		showDateLabel = show;
		[self setNeedsLayout];
	}
}

- (void)setTooLong:(BOOL)isTooLong {
	if (tooLong != isTooLong) {
		tooLong = isTooLong;
		self.tooLongLabel.hidden = !tooLong;
		ATLogDebug(@"setting too long to %d", tooLong);
		if (tooLong) {
			NSString *fullText = NSLocalizedString(@"Show full message.", @"Message bubble text for very long messages.");
			self.tooLongLabel.text = fullText;
		}
		[self setNeedsLayout];
	}
}

- (void)layoutSubviews {
	[super layoutSubviews];
	if (showDateLabel == NO || composing) {
		self.dateLabel.hidden = YES;
		CGRect chatBubbleRect = self.chatBubbleContainer.frame;
		chatBubbleRect.size.height = self.bounds.size.height;
		chatBubbleRect.origin.y = 0;
		self.chatBubbleContainer.frame = chatBubbleRect;
	} else {
		self.dateLabel.hidden = NO;
		CGRect dateLabelRect = self.dateLabel.frame;
		CGRect chatBubbleRect = self.chatBubbleContainer.frame;
		chatBubbleRect.size.height = self.bounds.size.height - dateLabelRect.size.height;
		chatBubbleRect.origin.y = dateLabelRect.size.height;
		self.chatBubbleContainer.frame = chatBubbleRect;
	}
	self.chatBubbleContainer.hidden = composing;
	self.composingBubble.hidden = !composing;
}

- (void)dealloc {
	messageText.delegate = nil;
	[userIcon release], userIcon = nil;
	[messageBubbleImage release], messageBubbleImage = nil;
	[messageText release], messageText = nil;
	[composingBubble release], composingBubble = nil;
	[dateLabel release], dateLabel = nil;
	[chatBubbleContainer release], chatBubbleContainer = nil;
	[usernameLabel release], usernameLabel = nil;
	[_tooLongLabel release];
	[super dealloc];
}

- (CGFloat)cellHeightForWidth:(CGFloat)width {
	CGFloat cellHeight = 0;
	
	do { // once
		if (self.isComposing) {
			cellHeight += 60;
			break;
		}
		if (showDateLabel) {
			cellHeight += self.dateLabel.bounds.size.height;
		}
		cellHeight += self.usernameLabel.bounds.size.height;
		CGFloat textWidth = width - horizontalCellPadding;
		CGFloat heightPadding = 19 + 6;
		CGSize textSize = [self.messageText sizeThatFits:CGSizeMake(textWidth, CGFLOAT_MAX)];
		cellHeight += MAX(60, textSize.height + heightPadding);
	} while (NO);
	return cellHeight;
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
