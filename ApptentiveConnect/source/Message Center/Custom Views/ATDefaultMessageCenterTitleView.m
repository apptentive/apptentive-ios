//
//  ATDefaultMessageCenterTitleView.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/3/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATDefaultMessageCenterTitleView.h"

#import "ATBackend.h"
#import "ATConnect.h"
#import "ATAppConfigurationUpdater.h"

@implementation ATDefaultMessageCenterTitleView
@synthesize title;
@synthesize imageView;

- (void)setup {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *titleString = [defaults objectForKey:ATAppConfigurationMessageCenterTitleKey];
	if (titleString == nil) {
		titleString = ATLocalizedString(@"Message Center", @"Message Center title text");
	}
	
	self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	//self.backgroundColor = [UIColor clearColor];
	UIImage *image = [ATBackend imageNamed:@"at_apptentive_icon_small"];
	imageView = [[UIImageView alloc] initWithImage:image];
	[self addSubview:imageView];
	title = [[UILabel alloc] initWithFrame:CGRectZero];
	title.text = titleString;
	title.font = [UIFont boldSystemFontOfSize:20.];
	title.textColor = [UIColor whiteColor];
	title.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
	title.textAlignment = UITextAlignmentLeft;
	title.lineBreakMode = UILineBreakModeMiddleTruncation;
	title.backgroundColor = [UIColor clearColor];
	title.opaque = NO;
	title.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[self addSubview:title];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self setup];
    }
    return self;
}

- (void)awakeFromNib {
	[self setup];
}

- (void)dealloc {
	[title release], title = nil;
	[imageView release], imageView = nil;
	[super dealloc];
}

- (void)layoutSubviews {
	CGFloat padding = 4;
	CGRect imageRect = self.imageView.frame;
	
	[title sizeToFit];
	CGFloat titleWidth = title.bounds.size.width;
	if (titleWidth > self.bounds.size.width) {
		titleWidth -= imageRect.size.width + padding;
	}
	
	CGFloat titleOriginX = floor(self.bounds.size.width*0.5 - titleWidth*0.5) + imageRect.size.width;
	imageRect.origin.x = titleOriginX - imageRect.size.width - padding;
	imageRect.origin.y = floor(self.bounds.size.height*0.5 - imageRect.size.height*0.5);
	self.imageView.frame = imageRect;
	
	CGRect titleRect = self.title.frame;
	titleRect.origin.x = titleOriginX;
	titleRect.size.width = titleWidth;
	titleRect.size.height = self.bounds.size.height;
	self.title.frame = titleRect;
}
@end
