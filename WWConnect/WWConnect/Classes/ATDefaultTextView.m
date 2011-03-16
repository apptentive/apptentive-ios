//
//  ATDefaultTextView.m
//  DemoApp
//
//  Created by Andrew Wooster on 3/16/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import "ATDefaultTextView.h"


@interface ATDefaultTextView ()
@property (nonatomic, retain) UIColor *originalTextColor;
@end

@interface ATDefaultTextView (Private)
- (void)setup;
- (void)setupPlaceholder;
- (void)beganEditing:(NSNotification *)notification;
- (void)endedEditing:(NSNotification *)notification;
@end

@implementation ATDefaultTextView
@synthesize placeholder;
@synthesize originalTextColor;

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

@end


@implementation ATDefaultTextView (Private)

- (void)setup {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beganEditing:) name:UITextViewTextDidBeginEditingNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endedEditing:) name:UITextViewTextDidEndEditingNotification object:self];
    [self setupPlaceholder];
}

- (void)setupPlaceholder {
    self.text = self.placeholder;
    self.originalTextColor = self.textColor;
    self.textColor = [UIColor lightGrayColor];
}

- (void)beganEditing:(NSNotification *)notification {
    if (notification.object == self) {
        if (self.text && self.placeholder && [self.placeholder isEqualToString:self.text]) {
            self.text = @"";
            self.textColor = self.originalTextColor;
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
