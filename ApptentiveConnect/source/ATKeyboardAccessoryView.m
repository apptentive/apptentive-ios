//
//  ATKeyboardAccessoryView.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/24/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import "ATKeyboardAccessoryView.h"
#import "ATConnect.h"
#import <QuartzCore/QuartzCore.h>

@implementation ATKeyboardAccessoryView
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            height = 20.0;
        } else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            height = 20.0;
        } else {
            height = 20.0;
        }
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.clipsToBounds = YES;
        textLabel = [[UILabel alloc] initWithFrame:self.frame];
        textLabel.opaque = NO;
        textLabel.backgroundColor = [UIColor clearColor];
        textLabel.font = [UIFont boldSystemFontOfSize:16.0];
        textLabel.textColor = [UIColor colorWithRed:0.57 green:0.77 blue:0.92 alpha:1.0];
        textLabel.shadowColor = [UIColor blackColor];
        textLabel.shadowOffset = CGSizeMake(0.0, 1.0);
        textLabel.text = ATLocalizedString(@"Powered by Apptentive", @"Keyboard accessory text advertising Apptentive.");
        [textLabel sizeToFit];
        textLabel.textAlignment = UITextAlignmentCenter;
        
        
        CGRect tf = textLabel.frame;
        tf.origin.x += 5.0;
        //tf.origin.y += 5.0;
        textLabel.frame = tf;
        
        textContainerView = [[UIView alloc] initWithFrame:textLabel.frame];
        textContainerView.opaque = NO;
        textContainerView.userInteractionEnabled = NO;
        [textContainerView addSubview:textLabel];
        [textContainerView sizeToFit];
        CGRect cf = textContainerView.frame;
        cf.size.height += 10.0;
        cf.size.width += 10.0;
        textContainerView.frame = cf;
        textContainerView.layer.cornerRadius = 4.0;
        textContainerView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.7];
        
        [self addSubview:textContainerView];
        
        
        CGRect f = self.frame;
        f.size.height = textLabel.bounds.size.height + 5.0;
        self.frame = f;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)dealloc {
    [textLabel removeFromSuperview];
    [textLabel release];
    textLabel = nil;
    [textContainerView removeFromSuperview];
    [textContainerView release];
    textContainerView = nil;
    [super dealloc];
}

@end
