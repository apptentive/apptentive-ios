//
//  ATDefaultTextView.m
//  DemoApp
//
//  Created by Andrew Wooster on 3/16/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import "ATDefaultTextView.h"


@interface ATDefaultTextView ()
@property (nonatomic, copy) UIColor *originalTextColor;
@property (nonatomic, copy) UIColor *placeholderTextColor;
@end

@interface ATDefaultTextView (Private)
- (void)setup;
- (void)setupPlaceholder;
- (void)beganEditing:(NSNotification *)notification;
- (void)endedEditing:(NSNotification *)notification;
@end

@implementation ATDefaultTextView
@synthesize placeholder;
@synthesize originalTextColor, placeholderTextColor;

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

- (void)dealloc {
    self.originalTextColor = nil;
    self.placeholder = nil;
    [super dealloc];
}

- (void)setPlaceholder:(NSString *)newPlaceholder {
    if (placeholder != newPlaceholder) {
        [placeholder release];
        placeholder = nil;
        placeholder = [newPlaceholder retain];
        if (!self.text || [@"" isEqualToString:self.text]) {
            [self setupPlaceholder];
        }
    }
}

- (void)setTextColor:(UIColor *)newTextColor {
    [super setTextColor:newTextColor];
    if (![self.textColor isEqual:self.placeholderTextColor] && ![self.textColor isEqual:self.originalTextColor]) {
        self.originalTextColor = self.textColor;
    }
}
@end


@implementation ATDefaultTextView (Private)

- (void)setup {
    self.placeholderTextColor = [UIColor lightGrayColor];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beganEditing:) name:UITextViewTextDidBeginEditingNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endedEditing:) name:UITextViewTextDidEndEditingNotification object:self];
    [self setupPlaceholder];
}

- (void)setupPlaceholder {
    self.text = self.placeholder;
    if (!self.originalTextColor) {
        self.originalTextColor = self.textColor;
    }
    self.textColor = self.placeholderTextColor;
}

- (void)beganEditing:(NSNotification *)notification {
    if (notification.object == self) {
        if (self.text && self.placeholder && [self.placeholder isEqualToString:self.text]) {
            self.text = @"";
            self.textColor = [[self.originalTextColor copy] autorelease];
        }
    }
}

- (void)endedEditing:(NSNotification *)notification {
    if (notification.object == self) {
        if (self.placeholder && [@"" isEqualToString:self.text]) {
            [self setupPlaceholder];
        }
    }
}
@end
