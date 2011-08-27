//
//  ATKeyboardAccessoryView.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/24/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
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
        textLabel.font = [UIFont systemFontOfSize:16.0];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            textLabel.textColor = [UIColor colorWithRed:0.57 green:0.77 blue:0.92 alpha:1.0];
        } else {
            CGFloat g = 0.4;
            textLabel.textColor = [UIColor colorWithRed:g green:g blue:g alpha:1.0];
        }
        textLabel.text = ATLocalizedString(@"Feedback Powered by Apptentive", @"Keyboard accessory text advertising Apptentive.");
        [textLabel sizeToFit];
        textLabel.textAlignment = UITextAlignmentCenter;
        
        
        CGRect tf = textLabel.frame;
        tf.origin.x += 5.0;
        tf.origin.y += 1.0;
        //tf.origin.y += 5.0;
        textLabel.frame = tf;
        
        textContainerView = [[UIView alloc] initWithFrame:textLabel.frame];
        textContainerView.opaque = NO;
        textContainerView.userInteractionEnabled = NO;
        [textContainerView addSubview:textLabel];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) { // old way
            [textContainerView sizeToFit];
            CGRect cf = textContainerView.frame;
            cf.size.height += 10.0;
            cf.size.width += 10.0;
            textContainerView.frame = cf;
            textContainerView.layer.cornerRadius = 4.0;
            textContainerView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.7];
        } else {
            CGRect cf = textContainerView.frame;
            cf.origin.x = 0.0;
            cf.size.width = frame.size.width;
            cf.size.height += 10.0;
            textContainerView.frame = cf;
            textContainerView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.2];
        }
        
        [self addSubview:textContainerView];
        
        
        CGRect f = self.frame;
        f.size.height = textLabel.bounds.size.height + 5.0;
        self.frame = f;
        self.userInteractionEnabled = YES;
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
