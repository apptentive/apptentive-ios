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
	CGContextScaleCTM(context, 1.0, 1.0);
	UIBezierPath *bezierPath = [UIBezierPath bezierPath];
	
	[bezierPath moveToPoint:CGPointMake(9.5, 17)];
	[bezierPath addCurveToPoint:CGPointMake(14.5, 12) controlPoint1:CGPointMake(13.4, 14.8) controlPoint2:CGPointMake(14.5, 12)];
	[bezierPath addCurveToPoint:CGPointMake(6, 0) controlPoint1:CGPointMake(14.5, 12) controlPoint2:CGPointMake(9, 0)];
	[bezierPath addCurveToPoint:CGPointMake(5, 6) controlPoint1:CGPointMake(5.3000002, 0) controlPoint2:CGPointMake(5, 3.5)];
	[bezierPath addCurveToPoint:CGPointMake(0, 18) controlPoint1:CGPointMake(5, 14.5) controlPoint2:CGPointMake(0, 18)];
	[bezierPath addCurveToPoint:CGPointMake(9.5, 17) controlPoint1:CGPointMake(0, 18) controlPoint2:CGPointMake(5.5999999, 19.200001)];
	[bezierPath closePath];
	if (_direction == ATMessageBubbleArrowDirectionRight) {
		[bezierPath applyTransform:CGAffineTransformMakeScale(-1, 1)];
		[bezierPath applyTransform:CGAffineTransformMakeTranslation(15, -7.5)];
	} else {
		[bezierPath applyTransform:CGAffineTransformMakeTranslation(6, -7.5)];
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
