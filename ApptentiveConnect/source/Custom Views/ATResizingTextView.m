//
//  ATResizingTextView.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/1/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "ATResizingTextView.h"

#import "ATBackend.h"
#import "ATDefaultTextView.h"

@interface ATInternalDefaultTextView : ATDefaultTextView

@end

@interface ATResizingTextView ()
@property (nonatomic, retain) ATInternalDefaultTextView *internalTextView;

- (void)setup;
- (void)resizeTextView;
- (void)computeLineHeight;
@end

@implementation ATResizingTextView {
	CGFloat lineHeight;
	UIEdgeInsets textFieldInset;
	UIView *backgroundView;
}
@synthesize delegate;
@synthesize maximumVeritcalLines;
@synthesize style;
@synthesize internalTextView;

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		[self setup];
	}
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [super initWithCoder:aDecoder])) {
		[self setup];
	}
	return self;
}

- (void)setup {
	
	if (self.style == ATResizingTextViewStyleIOS) {
		self.backgroundColor = [UIColor clearColor];
		self.clipsToBounds = NO;
		if (!backgroundView) {
			backgroundView = [[UIImageView alloc] initWithImage:[[ATBackend imageNamed:@"at_resizing_text_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(15, 15, 15, 14)]];
			backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
			backgroundView.frame = CGRectInset(self.bounds, 0, 2);
			[self addSubview:backgroundView];
			[self sendSubviewToBack:backgroundView];
		}
	
		textFieldInset = UIEdgeInsetsMake(8, 7, 5, 0);
	} else {
		self.backgroundColor = [UIColor colorWithRed:217/255. green:217/255. blue:217/255. alpha:1];
		self.clipsToBounds = NO;
		if (backgroundView) {
			[backgroundView removeFromSuperview];
			[backgroundView release], backgroundView = nil;
		}
		self.layer.borderWidth = 2;
		self.layer.borderColor = [UIColor colorWithRed:60/255. green:154/255. blue:227/255. alpha:1].CGColor;
		self.layer.cornerRadius = 4;
		
		textFieldInset = UIEdgeInsetsMake(8, 0, 5, 0);
	}
	
	CGRect f = {
		.origin = {
			.x = textFieldInset.left,
			.y = textFieldInset.top
		},
		.size = {
			.width = self.frame.size.width - textFieldInset.left - textFieldInset.right,
			.height = self.frame.size.height - textFieldInset.top - textFieldInset.bottom
		}
	};
	f.size.width = f.size.width - (textFieldInset.left + textFieldInset.right);
	if (!internalTextView) {
		internalTextView = [[ATInternalDefaultTextView alloc] initWithFrame:f];
		internalTextView.clipsToBounds = NO;
		internalTextView.delegate = self;
		internalTextView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
		internalTextView.showsHorizontalScrollIndicator = NO;
		internalTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		
		[self addSubview:internalTextView];
	}
	[self computeLineHeight];
	self.maximumVeritcalLines = 3;
	[self.internalTextView setBackgroundColor:[UIColor clearColor]];
}

- (void)dealloc {
	[backgroundView release], backgroundView = nil;
	[internalTextView removeFromSuperview];
	[internalTextView release], internalTextView = nil;
	delegate = nil;
	[super dealloc];
}
/*
#pragma mark - Forward Invocation
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return [internalTextView methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    if ([internalTextView respondsToSelector:[anInvocation selector]]) {
        [anInvocation invokeWithTarget:internalTextView];
    } else {
        [super forwardInvocation:anInvocation];
    }
}
*/

- (BOOL)isDefault {
	return [internalTextView isDefault];
}

- (void)resizeTextView {
	CGRect currentFrame = self.frame;
	CGSize textSize = internalTextView.contentSize;
	CGSize textBounds = textSize;
	textBounds.height = MIN(textSize.height, lineHeight * maximumVeritcalLines);
	textBounds.height += (textFieldInset.bottom + textFieldInset.top);
	
	if (textBounds.height != currentFrame.size.height) {
//		[UIView animateWithDuration:0.3 animations:^(void) {
			[self.delegate resizingTextView:self willChangeHeight:textBounds.height];
			CGRect newFrame = currentFrame;
			newFrame.size.height = textBounds.height;
			self.frame = newFrame;
//		} completion:^(BOOL finished) {
			[self.delegate resizingTextView:self didChangeHeight:textBounds.height];
//		}];
	}
}

- (void)computeLineHeight {
	NSString *originalText = [internalTextView text];
	internalTextView.text = @"|";
	CGSize s = internalTextView.contentSize;
	lineHeight = s.height;
	internalTextView.text = originalText;
}

#pragma mark - Responder Chain
- (BOOL)becomeFirstResponder {
	return [internalTextView becomeFirstResponder];
}

- (BOOL)isFirstResponder {
	return [internalTextView isFirstResponder];
}

- (BOOL)resignFirstResponder {
	return [internalTextView resignFirstResponder];
}

#pragma mark - Accessors
- (NSString *)placeholder {
	return [internalTextView placeholder];
}

- (void)setPlaceholder:(NSString *)placeholder {
	[internalTextView setPlaceholder:placeholder];
}

- (NSString *)text {
	return [internalTextView text];
}

- (void)setText:(NSString *)text {
	[internalTextView setText:text];
	[self textViewDidChange:internalTextView];
}

- (UIFont *)font {
	return [internalTextView font];
}

- (void)setFont:(UIFont *)font {
	[internalTextView setFont:font];
	[self computeLineHeight];
}

- (void)setStyle:(ATResizingTextViewStyle)aStyle {
	if (style != aStyle) {
		style = aStyle;
		[self setup];
	}
}

#pragma mark - UITextViewDelegate
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
	if (self.delegate && [self.delegate respondsToSelector:@selector(resizingTextViewShouldBeginEditing:)]) {
		return [self.delegate resizingTextViewShouldBeginEditing:self];
	}
	return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
	if (self.delegate && [self.delegate respondsToSelector:@selector(resizingTextViewShouldEndEditing:)]) {
		return [self.delegate resizingTextViewShouldEndEditing:self];
	}
	return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
	if (self.delegate && [self.delegate respondsToSelector:@selector(resizingTextViewDidBeginEditing:)]) {
		[self.delegate resizingTextViewDidBeginEditing:self];
	}
	[self resizeTextView];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
	if (self.delegate && [self.delegate respondsToSelector:@selector(resizingTextViewDidEndEditing:)]) {
		[self.delegate resizingTextViewDidEndEditing:self];
	}
	[self resizeTextView];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	if (self.delegate && [self.delegate respondsToSelector:@selector(resizingTextView:shouldChangeTextInRange:replacementText:)]) {
		return [self.delegate resizingTextView:self shouldChangeTextInRange:range replacementText:text];
	}
	[self resizeTextView];
	return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
	if (self.delegate && [self.delegate respondsToSelector:@selector(resizingTextViewDidChange:)]) {
		[self.delegate resizingTextViewDidChange:self];
	}
	[self resizeTextView];
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
	if (self.delegate && [self.delegate respondsToSelector:@selector(textViewDidChangeSelection:)]) {
		[self.delegate resizingTextViewDidChangeSelection:self];
	}
	[self resizeTextView];
}
@end


@implementation ATInternalDefaultTextView
- (void)setContentInset:(UIEdgeInsets)aContentInset {
	ATLogDebug(@"content inset is: %@", NSStringFromUIEdgeInsets(aContentInset));
	[super setContentInset:aContentInset];
}

- (void)setContentOffset:(CGPoint)aContentOffset {
	/*
	if ([self isDecelerating] || [self isDragging]) {
		NSLog(@"scrolling offset is: %@", NSStringFromCGPoint(aContentOffset));
		NSLog(@"inset is: %@", NSStringFromUIEdgeInsets(self.contentInset));
	} else {
		CGFloat yDiff = self.contentSize.height - self.frame.size.height + self.contentInset.bottom;
		NSLog(@"yDiff: %f, %f", yDiff, aContentOffset.y);
	}*/
	/*
	if (aContentOffset.y > 0) {
		// Ignore attempts at animating this value.
		aContentOffset.y = 8;
	}*/
	[super setContentOffset:aContentOffset];
}

- (void)setContentSize:(CGSize)contentSize {
	if (self.contentSize.height > contentSize.height) {
		UIEdgeInsets inset = self.contentInset;
		inset.top = 0;
		inset.bottom = 0;
		self.contentInset = inset;
	}
	[super setContentSize:contentSize];
}
@end

