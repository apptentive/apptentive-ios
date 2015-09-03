//
//  ATDefaultTextView.m
//  DemoApp
//
//  Created by Andrew Wooster on 3/16/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATDefaultTextView.h"
#import "ATUtilities.h"

@interface ATDefaultTextView ()

@property (strong, nonatomic) UILabel *placeholderLabel;

@end

@implementation ATDefaultTextView

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		[self setup];
	}
	return self;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	[self setup];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	[self setupPlaceholder];
}

- (void)setPlaceholder:(NSString *)newPlaceholder {
	if (_placeholder != newPlaceholder) {
		_placeholder = newPlaceholder;
		[self setupPlaceholder];
	}
}

- (void)setPlaceholderColor:(UIColor *)newPlaceholderColor {
	if (_placeholderColor != newPlaceholderColor) {
		_placeholderColor = newPlaceholderColor;
		[self setupPlaceholder];
	}
}

- (BOOL)isDefault {
	if (!self.text || [self.text length] == 0) return YES;
	return NO;
}

- (void)drawRect:(CGRect)rect {
	if (self.at_drawRectBlock) {
		self.at_drawRectBlock(self, rect);
	}
}

#pragma mark - Private

- (void)setup {
	self.text = @"";
	self.placeholderLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	self.placeholderLabel.userInteractionEnabled = NO;
	self.placeholderLabel.backgroundColor = [UIColor clearColor];
	self.placeholderLabel.opaque = NO;
	self.placeholderLabel.textColor = self.placeholderColor ?: [UIColor lightGrayColor];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEdit:) name:UITextViewTextDidBeginEditingNotification object:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEdit:) name:UITextViewTextDidChangeNotification object:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEdit:) name:UITextViewTextDidEndEditingNotification object:self];
	[self setupPlaceholder];
	self.contentMode = UIViewContentModeRedraw;
}

- (void)setupPlaceholder {
	if ([self isDefault]) {
		self.placeholderLabel.text = self.placeholder;
		self.placeholderLabel.font = self.font;
		self.placeholderLabel.textColor = self.placeholderColor ?: [UIColor lightGrayColor];
		self.placeholderLabel.textAlignment = self.textAlignment;
		self.placeholderLabel.numberOfLines = 0;
		self.placeholderLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		[self.placeholderLabel sizeToFit];
		[self addSubview:self.placeholderLabel];
		
		CGFloat paddingX = 0;
		CGPoint origin = CGPointZero;
		
		if ([ATUtilities osVersionGreaterThanOrEqualTo:@"7"]) {
			paddingX = 4;
			origin = CGPointMake(4, 8);
		} else {
			paddingX = 8;
			origin = CGPointMake(8, 8);
		}
		
		CGRect b = self.placeholderLabel.bounds;
		b.size.width = self.bounds.size.width - paddingX*2.0;
		self.placeholderLabel.bounds = b;
		CGRect f = self.placeholderLabel.frame;
		f.origin = origin;
		self.placeholderLabel.frame = f;
		[self sendSubviewToBack:self.placeholderLabel];
	} else {
		[self.placeholderLabel removeFromSuperview];
	}
}

- (void)didEdit:(NSNotification *)notification {
	if (notification.object == self) {
		[self setupPlaceholder];
	}
}

@end
