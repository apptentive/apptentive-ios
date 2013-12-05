//
//  ATMessageBubbleArrowViewV7.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/27/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATMessageBubbleArrowViewV7.h"

@implementation ATMessageBubbleArrowViewV7

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.color = [UIColor whiteColor];
		self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	self.color = [UIColor whiteColor];
	self.backgroundColor = [UIColor clearColor];
}

- (void)dealloc {
	[_color release], _color = nil;
	[super dealloc];
}

- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSaveGState(context);
	CGContextScaleCTM(context, 0.5, 0.5);
	if (_direction == ATMessageBubbleArrowDirectionLeft) {
		UIBezierPath *bezierPath = [UIBezierPath bezierPath];
		[bezierPath moveToPoint: CGPointMake(18.5, 18.5)];
		[bezierPath addCurveToPoint: CGPointMake(10, 1) controlPoint1: CGPointMake(8.87, 13.45) controlPoint2: CGPointMake(10, 1)];
		[bezierPath addCurveToPoint: CGPointMake(24, 8) controlPoint1: CGPointMake(10, 1) controlPoint2: CGPointMake(18.63, 7.47)];
		[bezierPath addCurveToPoint: CGPointMake(32, 13) controlPoint1: CGPointMake(29.37, 8.53) controlPoint2: CGPointMake(31.54, 7.58)];
		[bezierPath addCurveToPoint: CGPointMake(18.5, 18.5) controlPoint1: CGPointMake(32.46, 18.42) controlPoint2: CGPointMake(28.13, 23.55)];
		[bezierPath closePath];
		[self.color setFill];
		[bezierPath fill];
	} else {
		CGContextSaveGState(context);
		UIBezierPath *bezierPath = [UIBezierPath bezierPath];
		[bezierPath moveToPoint: CGPointMake(2.49, 18.5)];
		[bezierPath addCurveToPoint: CGPointMake(10.99, 1) controlPoint1: CGPointMake(12.12, 13.45) controlPoint2: CGPointMake(10.99, 1)];
		[bezierPath addCurveToPoint: CGPointMake(-3.01, 8) controlPoint1: CGPointMake(10.99, 1) controlPoint2: CGPointMake(2.36, 7.47)];
		[bezierPath addCurveToPoint: CGPointMake(-11.01, 13) controlPoint1: CGPointMake(-8.37, 8.53) controlPoint2: CGPointMake(-10.54, 7.58)];
		[bezierPath addCurveToPoint: CGPointMake(2.49, 18.5) controlPoint1: CGPointMake(-11.47, 18.42) controlPoint2: CGPointMake(-7.14, 23.55)];
		[bezierPath closePath];
		[bezierPath applyTransform:CGAffineTransformMakeTranslation(25, 0)];
		[self.color setFill];
		[bezierPath fill];
	}
	CGContextRestoreGState(context);
}


- (void)setDirection:(ATMessageBubbleArrowDirection)newDirection {
	if (_direction != newDirection) {
		_direction = newDirection;
		[self setNeedsDisplay];
	}
}

- (void)setColor:(UIColor *)color {
	if (_color != color) {
		[_color release], _color = nil;
		_color = [color retain];
		[self setNeedsDisplay];
	}
}
@end
