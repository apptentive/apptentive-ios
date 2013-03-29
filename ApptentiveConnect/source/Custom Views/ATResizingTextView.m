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
	UIEdgeInsets textFieldContentInset;
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
	} else if (self.style == ATResizingTextViewStyleV2) {
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
	} else if (self.style == ATResizingTextViewStyleV3) {
		self.backgroundColor = [UIColor clearColor];
		self.clipsToBounds = NO;
		internalTextView.clipsToBounds = YES;
		if (backgroundView) {
			[backgroundView removeFromSuperview];
			[backgroundView release], backgroundView = nil;
		}
		backgroundView = [[UIImageView alloc] initWithImage:[[ATBackend imageNamed:@"at_mc_text_input_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(16, 10, 16, 10)]];
		backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		CGRect backgroundFrame = CGRectInset(self.bounds, 0, 6);
		backgroundFrame.origin.y += 1;
		backgroundView.frame = backgroundFrame;
		[self addSubview:backgroundView];
		[self sendSubviewToBack:backgroundView];
		
		textFieldInset = UIEdgeInsetsMake(8, 0, 5, 0);
		textFieldContentInset = UIEdgeInsetsMake(2, 0, 2, 0);
	}

	CGRect f = {
		.origin = {
			.x = textFieldInset.left,
			.y = textFieldInset.top
		},
		.size = {
			.width = self.bounds.size.width - textFieldInset.left - textFieldInset.right,
			.height = self.bounds.size.height - textFieldInset.top - textFieldInset.bottom
		}
	};
	NSString *text = nil;
	if (internalTextView) {
		[internalTextView removeFromSuperview];
		text = internalTextView.text;
		[internalTextView release], internalTextView = nil;
	}
	if (!internalTextView) {
		internalTextView = [[ATInternalDefaultTextView alloc] initWithFrame:f];
		internalTextView.clipsToBounds = NO;
		internalTextView.delegate = self;
		internalTextView.contentInset = textFieldContentInset;
		internalTextView.showsHorizontalScrollIndicator = NO;
		internalTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		internalTextView.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.1];
		
		[self addSubview:internalTextView];
	}
	if (text) {
		internalTextView.text = text;
	}
	[self computeLineHeight];
	self.maximumVeritcalLines = 3;
	//[self.internalTextView setBackgroundColor:[UIColor clearColor]];
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
	CGRect currentBounds = self.bounds;
//	CGSize textSize = internalTextView.contentSize;
	CGSize minSize = [@"|SomeyExamp le text" sizeWithFont:internalTextView.font constrainedToSize:CGSizeMake(internalTextView.bounds.size.width, internalTextView.font.lineHeight)];
	CGSize maxTextSize = CGSizeMake(internalTextView.bounds.size.width, internalTextView.font.lineHeight * maximumVeritcalLines);
	CGSize textSize = [internalTextView.text sizeWithFont:internalTextView.font constrainedToSize:maxTextSize];
	if ([internalTextView.text hasSuffix:@"\n"]) {
		textSize.height += [internalTextView.font lineHeight];
	}
	CGFloat sizeDiff = currentBounds.size.height - internalTextView.bounds.size.height;
	CGFloat newHeight = MAX(minSize.height, MIN(textSize.height, maxTextSize.height));
//	newHeight += textFieldContentInset.bottom + textFieldContentInset.top;
//	newHeight += textFieldInset.bottom + textFieldInset.top;
	newHeight += sizeDiff;
	
	if (newHeight != currentBounds.size.height) {
//		[UIView animateWithDuration:0.3 animations:^(void) {
			[self.delegate resizingTextView:self willChangeHeight:newHeight];
			CGRect newFrame = self.frame;
			newFrame.size.height = newHeight;
		NSLog(@"minSize: %@", NSStringFromCGSize(minSize));
		NSLog(@"maxTextSize: %@", NSStringFromCGSize(maxTextSize));
		NSLog(@"textSize: %@", NSStringFromCGSize(textSize));
		NSLog(@"sizeDiff: %f", sizeDiff);
		NSLog(@"textFieldInset: %@", NSStringFromUIEdgeInsets(textFieldInset));
		NSLog(@"textFieldContentInset: %@", NSStringFromUIEdgeInsets(textFieldContentInset));
		NSLog(@"newHeight: %f", newHeight);
			
			self.frame = newFrame;
//		} completion:^(BOOL finished) {
			[self.delegate resizingTextView:self didChangeHeight:newHeight];
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
	//[self resizeTextView];
	return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
	if (self.delegate && [self.delegate respondsToSelector:@selector(resizingTextViewDidChange:)]) {
		[self.delegate resizingTextViewDidChange:self];
	}
	[self resizeTextView];
	[internalTextView scrollRangeToVisible:internalTextView.selectedRange];
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
	if (self.delegate && [self.delegate respondsToSelector:@selector(textViewDidChangeSelection:)]) {
		[self.delegate resizingTextViewDidChangeSelection:self];
	}
	[self resizeTextView];
	[internalTextView scrollRangeToVisible:internalTextView.selectedRange];
}
@end


@implementation ATInternalDefaultTextView
- (void)setContentInset:(UIEdgeInsets)aContentInset {
	//ATLogDebug(@"content inset is: %@", NSStringFromUIEdgeInsets(aContentInset));
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
/*
- (void)setContentSize:(CGSize)contentSize {
	if (self.contentSize.height > contentSize.height) {
		UIEdgeInsets inset = self.contentInset;
		inset.top = 0;
		inset.bottom = 0;
		self.contentInset = inset;
	}
	[super setContentSize:contentSize];
}*/
@end

