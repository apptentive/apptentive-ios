//
//  ATHUDView.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/28/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATHUDView.h"
#import "ATBackend.h"
#import "ATConnect.h"
#import "ATUtilities.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

#define DRAW_ROUND_RECT 0


@interface ATHUDView ()
- (void)setup;
- (void)animateIn;
- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;

@property (strong, nonatomic) UIWindow *parentWindow;
@property (strong, nonatomic) UIImageView *icon;
@property (nonatomic, strong, readwrite) UILabel *label;

@end


@implementation ATHUDView

- (id)initWithWindow:(UIWindow *)window {
	if ((self = [super initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)])) {
		_parentWindow = window;
		[self setup];
	}
	return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
#if !DRAW_ROUND_RECT
	self.layer.cornerRadius = self.cornerRadius;
#endif

	[self.label sizeToFit];

	CGFloat labelTopPadding = 2.0;
	CGSize imageSize = self.icon.image.size;
	[self.label sizeToFit];
	CGSize labelSize = [self.label sizeThatFits:CGSizeMake(200.0, self.label.bounds.size.height)];

	CGRect imageRect = CGRectMake(0.0, 0.0, imageSize.width, imageSize.height);
	CGRect labelRect = CGRectMake(0.0, imageSize.height + labelTopPadding, labelSize.width, labelSize.height);

	CGRect allRect = CGRectUnion(imageRect, labelRect);
	CGFloat squareLength = MAX(allRect.size.width, allRect.size.height);
	squareLength = ceil(squareLength + 2.0 * self.cornerRadius);

	CGRect insetAllRect = CGRectMake(0.0, 0.0, squareLength, squareLength);
	insetAllRect.size.width = squareLength;
	insetAllRect.size.height = squareLength;
	insetAllRect = ATCGRectOfEvenSize(insetAllRect);

	// Center imageRect.
	CGRect finalImageRect = imageRect;
	finalImageRect.origin.y += self.cornerRadius;
	if (finalImageRect.size.width < insetAllRect.size.width) {
		finalImageRect.origin.x += floorf((insetAllRect.size.width - imageRect.size.width) / 2.0);
	}

	// Center labelRect.
	CGRect finalLabelRect = labelRect;
	finalLabelRect.origin.y += self.cornerRadius;
	if (finalLabelRect.size.width < insetAllRect.size.width) {
		finalLabelRect.origin.x += floorf((insetAllRect.size.width - finalLabelRect.size.width) / 2.0);
	}

	self.bounds = CGRectIntegral(insetAllRect);

	switch ([UIApplication sharedApplication].statusBarOrientation) {
		case UIInterfaceOrientationLandscapeRight:
			self.transform = CGAffineTransformMakeRotation(M_PI_2);
			break;

		case UIInterfaceOrientationLandscapeLeft:
			self.transform = CGAffineTransformMakeRotation(-M_PI_2);
			break;

		case UIInterfaceOrientationPortraitUpsideDown:
			self.transform = CGAffineTransformMakeRotation(M_PI);
			break;

		default:
			break;
	}

	CGPoint centerPoint = self.parentWindow.center;
	CGPoint orientationAdjustedCenterPoint = CGPointMake(MIN(centerPoint.x, centerPoint.y), MAX(centerPoint.x, centerPoint.y));

	self.center = CGPointMake(floorf(orientationAdjustedCenterPoint.x), floorf(orientationAdjustedCenterPoint.y));

	self.label.frame = CGRectIntegral(finalLabelRect);
	self.icon.frame = CGRectIntegral(finalImageRect);
}

- (void)show {
	[self animateIn];
}

#if DRAW_ROUND_RECT
- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();

	CGRect roundRect = CGRectMake(0.0, 0.0, self.bounds.size.width, self.bounds.size.height);
	CGFloat radius = self.cornerRadius;

	CGContextSaveGState(context);
	CGContextTranslateCTM(context, self.bounds.origin.x, self.bounds.origin.y);
	CGContextBeginPath(context);
	CGContextSetGrayFillColor(context, 0.0, 0.8);


	CGContextBeginPath(context);
	CGContextMoveToPoint(context, CGRectGetMinX(roundRect) + radius, CGRectGetMinY(roundRect));
	CGContextAddArc(context, CGRectGetMaxX(roundRect) - radius, CGRectGetMinY(roundRect) + radius, radius, 3 * M_PI / 2, 0, 0);
	CGContextAddArc(context, CGRectGetMaxX(roundRect) - radius, CGRectGetMaxY(roundRect) - radius, radius, 0, M_PI / 2, 0);
	CGContextAddArc(context, CGRectGetMinX(roundRect) + radius, CGRectGetMaxY(roundRect) - radius, radius, M_PI / 2, M_PI, 0);
	CGContextAddArc(context, CGRectGetMinX(roundRect) + radius, CGRectGetMinY(roundRect) + radius, radius, M_PI, 3 * M_PI / 2, 0);
	CGContextClosePath(context);

	CGContextFillPath(context);
	CGContextRestoreGState(context);
}
#endif

#pragma mark - Private

- (void)setup {
	self.fadeOutDuration = 3.0;
	self.transform = [ATUtilities viewTransformInWindow:self.parentWindow];

	[self setUserInteractionEnabled:NO];

	self.label = [[UILabel alloc] initWithFrame:CGRectZero];
	self.label.backgroundColor = [UIColor clearColor];
	self.label.opaque = NO;
	self.label.textColor = [UIColor whiteColor];
	self.label.font = [UIFont boldSystemFontOfSize:17.0];
	self.label.textAlignment = NSTextAlignmentCenter;
	self.label.lineBreakMode = NSLineBreakByWordWrapping;
	self.label.adjustsFontSizeToFitWidth = YES;
	self.label.numberOfLines = 0;
	[self addSubview:self.label];

	UIImage *iconImage = [ATBackend imageNamed:@"at_checkmark"];
	self.icon = [[UIImageView alloc] initWithImage:iconImage];
	self.icon.backgroundColor = [UIColor clearColor];
	self.icon.opaque = NO;
	[self addSubview:self.icon];

	self.size = CGSizeMake(100.0, 100.0);
	self.cornerRadius = 10.0;
#if DRAW_ROUND_RECT
	self.backgroundColor = [UIColor clearColor];
#else
	self.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
#endif
	self.opaque = NO;
	[self setNeedsLayout];
	[self setNeedsDisplay];
}

- (void)animateIn {
	self.alpha = 1.0;
	[self layoutSubviews];
	self.windowLevel = UIWindowLevelAlert;
	[self makeKeyAndVisible];
	self.center = self.parentWindow.center;

	[UIView beginAnimations:@"animateIn" context:NULL];
	[UIView setAnimationDuration:self.fadeOutDuration];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	self.alpha = 1.0;
	[UIView commitAnimations];
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	if ([animationID isEqualToString:@"animateIn"]) {
		[UIView beginAnimations:@"animateOut" context:NULL];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDuration:2.0];
		self.alpha = 0.0;
		[UIView commitAnimations];
	} else {
		[[self.parentWindow window] makeKeyAndVisible];
	}
}
@end
