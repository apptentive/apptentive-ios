//
//  ATHUDView.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/28/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import "ATHUDView.h"
#import "ATConnect.h"
#import <QuartzCore/QuartzCore.h>

@interface ATHUDView (Private)
- (void)setup;
- (void)teardown;
- (void)animateIn;
- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;
@end

@implementation ATHUDView
@synthesize label, markType, markColor, size, cornerRadius;

- (id)initWithWindow:(UIWindow *)window {
    if ((self = [super initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)])) {
        [self setup];
        parentView = window;
    }
    return self;
}


- (void)dealloc {
    [self teardown];
    self.markColor = nil;
    [super dealloc];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect b = self.frame;
    b.size = self.size;
    self.frame = b;
    self.layer.cornerRadius = self.cornerRadius;
    
    [label sizeToFit];
    
    // Inset everything by the corner radius.
    CGRect insetRect = CGRectInset(self.bounds, self.cornerRadius, self.cornerRadius);
    CGRect iconRect = insetRect;
    CGFloat labelTopPadding = 2.0;
    iconRect.size.height -= (label.bounds.size.height + labelTopPadding);
    CGRect labelRect = label.bounds;
    labelRect.size.width = insetRect.size.width;
    labelRect.origin.x = iconRect.origin.x;
    labelRect.origin.y = iconRect.origin.y + iconRect.size.height + labelTopPadding;
    
    if (markType == ATHUDCheckmark) {
        unichar ch = 0x2714; //0xE29C94; // Checkmark character in Apple Symbols
        NSString *check = [NSString stringWithCharacters:&ch length:1];
        iconLabel.text = check;
        iconLabel.font = [UIFont boldSystemFontOfSize:120.0];//iconRect.size.height];
    } else if (markType == ATHUDQuestionMark) {
        iconLabel.font = [UIFont boldSystemFontOfSize:107.0];
        iconLabel.text = @"?";
    }
    
    label.frame = labelRect;
    iconLabel.textColor = self.markColor;
    iconLabel.frame = iconRect;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
/*
 - (void)drawRect:(CGRect)rect {
    [[UIColor blackColor] set];
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextFillRect(c, rect);
}
 */

- (void)show {
    [self animateIn];
}
@end

@implementation ATHUDView (Private)
- (void)setup {
    [self setUserInteractionEnabled:NO];
    
    label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.opaque = NO;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont boldSystemFontOfSize:17.0];
    label.textAlignment = UITextAlignmentCenter;
    label.lineBreakMode = UILineBreakModeTailTruncation;
    label.adjustsFontSizeToFitWidth = YES;
    [self addSubview:label];
    
    NSString *iconPath = nil;
    if ([[UIScreen mainScreen] scale] > 1.0) {
        iconPath = [[ATConnect resourceBundle] pathForResource:@"at_checkmark@2x" ofType:@"png"];
    } else {
        iconPath = [[ATConnect resourceBundle] pathForResource:@"at_checkmark" ofType:@"png"];
    }
    UIImage *iconImage = [[UIImage alloc] initWithContentsOfFile:iconPath];
    icon = [[UIImageView alloc] initWithImage:iconImage];
    [iconImage release];
    iconImage = nil;
    [iconPath release];
    iconPath = nil;
    
    self.markColor = [UIColor whiteColor];
    iconLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    iconLabel.backgroundColor = [UIColor clearColor];
    iconLabel.opaque = NO;
    //iconLabel.font = [UIFont fontWithName:@"Apple Symbols" size:102.0];
    iconLabel.textAlignment = UITextAlignmentCenter;
    iconLabel.adjustsFontSizeToFitWidth = YES;
    iconLabel.clipsToBounds = NO;
    [self addSubview:iconLabel];
    
    self.size = CGSizeMake(100.0, 100.0);
    self.cornerRadius = 10.0;
    self.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
    self.opaque = NO;
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

- (void)teardown {
    [icon removeFromSuperview];
    [icon release];
    icon = nil;
    [label removeFromSuperview];
    [label release];
    label = nil;
    self.markColor = nil;
}

- (void)animateIn {
    self.alpha = 1.0;
    [self layoutSubviews];
    [parentView addSubview:self];
    self.center = parentView.center;
    [parentView bringSubviewToFront:self];
    
    NSLog(@"starting animation");
    [UIView beginAnimations:@"animateIn" context:NULL];
    [UIView setAnimationDuration:3.0];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    self.alpha = 1.0;
    [UIView commitAnimations];
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    if ([animationID isEqualToString:@"animateIn"]) {
        NSLog(@"b");
        [UIView beginAnimations:@"animateOut" context:NULL];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDuration:2.0];
        self.alpha = 0.0;
        [UIView commitAnimations];
    } else {
        NSLog(@"c");
        [self removeFromSuperview];
    }
}
@end
