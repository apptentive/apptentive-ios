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
	UIBezierPath* bezierPath = [UIBezierPath bezierPath];
	[bezierPath moveToPoint: CGPointMake(0, 22)];
	[bezierPath addCurveToPoint: CGPointMake(11, 22) controlPoint1: CGPointMake(0.49, 21.81) controlPoint2: CGPointMake(10.29, 21.98)];
	[bezierPath addCurveToPoint: CGPointMake(13, 22) controlPoint1: CGPointMake(12.06, 22.04) controlPoint2: CGPointMake(13, 22)];
	[bezierPath addCurveToPoint: CGPointMake(17, 21) controlPoint1: CGPointMake(14.24, 21.93) controlPoint2: CGPointMake(16.47, 21.14)];
	[bezierPath addCurveToPoint: CGPointMake(22.49, 18.5) controlPoint1: CGPointMake(18.75, 20.54) controlPoint2: CGPointMake(21.99, 18.76)];
	[bezierPath addCurveToPoint: CGPointMake(30.99, 1) controlPoint1: CGPointMake(32.12, 13.45) controlPoint2: CGPointMake(30.99, 1)];
	[bezierPath addCurveToPoint: CGPointMake(16.99, 8) controlPoint1: CGPointMake(30.99, 1) controlPoint2: CGPointMake(22.36, 7.47)];
	[bezierPath addCurveToPoint: CGPointMake(10, 9) controlPoint1: CGPointMake(13.8, 8.31) controlPoint2: CGPointMake(11.31, 9.06)];
	[bezierPath addCurveToPoint: CGPointMake(0, 9) controlPoint1: CGPointMake(9.57, 8.98) controlPoint2: CGPointMake(0, 9)];
	[bezierPath addCurveToPoint: CGPointMake(0, 14) controlPoint1: CGPointMake(0, 9) controlPoint2: CGPointMake(0.1, 12.86)];
	[bezierPath addCurveToPoint: CGPointMake(0, 22) controlPoint1: CGPointMake(-0.11, 15.23) controlPoint2: CGPointMake(0, 22)];
	[bezierPath closePath];
	if (_direction == ATMessageBubbleArrowDirectionLeft) {
		[bezierPath applyTransform:CGAffineTransformMakeScale(-1, 1)];
		[bezierPath applyTransform:CGAffineTransformMakeTranslation(39, 0)];
	} else {
		[bezierPath applyTransform:CGAffineTransformMakeTranslation(1, 0)];
	}
	[self.color setFill];
	[bezierPath fill];
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
