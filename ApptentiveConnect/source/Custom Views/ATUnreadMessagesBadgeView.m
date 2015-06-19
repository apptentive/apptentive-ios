//
//  ATUnreadMessagesBadgeView.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 6/19/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATUnreadMessagesBadgeView.h"
#import "ATConnect.h"

@interface ATUnreadMessagesBadgeView ()

@property (strong, nonatomic) UILabel *label;

@end

@implementation ATUnreadMessagesBadgeView

+ (instancetype)unreadMessageCountViewBadge {
	CGFloat diameter = 28.0;
	
	ATUnreadMessagesBadgeView *badge = [[self alloc] initWithFrame:CGRectMake(0, 0, diameter, diameter)];
	badge.backgroundColor = [UIColor colorWithRed:237.0/255.0 green:31.0/255.0 blue:51.0/255.0 alpha:1];
	badge.layer.cornerRadius = diameter / 2;
	badge.layer.masksToBounds = YES;
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, diameter, diameter)];
	[label setText:[NSString stringWithFormat:@"%lu", (unsigned long)[[ATConnect sharedConnection] unreadMessageCount]]];
	[label setTextColor:[UIColor whiteColor]];
	[label setBackgroundColor:[UIColor clearColor]];
	[label setFont:[UIFont systemFontOfSize:16.0f]];
	[label sizeToFit];
	[label setCenter:CGPointMake(badge.frame.size.width / 2, badge.frame.size.height / 2)];
	
	badge.label = label;
	[badge addSubview:label];
	
	return badge;
}

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unreadMessageCountChanged:) name:ATMessageCenterUnreadCountChangedNotification object:nil];
	}
	
	return self;
}

- (void)unreadMessageCountChanged:(NSNotification *)notification {
	NSNumber *unreadMessageCount = notification.userInfo[@"count"] ?: @0;
	self.label.text = [NSString stringWithFormat:@"%@", unreadMessageCount];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
