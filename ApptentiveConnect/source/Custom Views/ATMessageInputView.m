//
//  ATMessageInputView.m
//  ResizingTextView
//
//  Created by Andrew Wooster on 3/29/13.
//  Copyright (c) 2013 Andrew Wooster. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "ATMessageInputView.h"
#import "ATConnect_Private.h"
#import "ATUtilities.h"

UIEdgeInsets insetsForView(UIView *v) {
	CGRect frame = v.frame;
	CGRect superBounds = v.superview.bounds;
	return UIEdgeInsetsMake(frame.origin.y, frame.origin.x, superBounds.size.height - frame.size.height - frame.origin.y, superBounds.size.width - frame.size.width - frame.origin.x);
}

@interface ATMessageInputView ()
- (void)resizeTextViewWithString:(NSString *)string animated:(BOOL)animated;
- (void)validateTextField;
@end

@implementation ATMessageInputView {
	CGFloat minHeight;
	CGFloat textFieldEdgeInsetHeight;
	CGFloat minTextFieldHeight;
	CGFloat maxTextFieldHeight;
	NSUInteger maxNumberOfLines;
	UIEdgeInsets textViewInsets;
	
	UIEdgeInsets textViewContentInset;
}
@synthesize sendButton, attachButton, delegate, text, allowsEmptyText;

- (void)awakeFromNib {
	[super awakeFromNib];
	maxNumberOfLines = 5;
	
	textViewInsets = insetsForView(textView);
	
	textView.delegate = self;
	minHeight = self.bounds.size.height;
	textFieldEdgeInsetHeight = 4;
	minTextFieldHeight = textView.font.lineHeight + (2 * textFieldEdgeInsetHeight);
	maxTextFieldHeight = textView.font.lineHeight * maxNumberOfLines + (2 * textFieldEdgeInsetHeight);
	
	textView.backgroundColor = [UIColor clearColor];
	
	textView.autoresizingMask = UIViewAutoresizingNone;
	if ([ATUtilities osVersionGreaterThanOrEqualTo:@"7"]) {
		textViewContentInset = UIEdgeInsetsMake(-textFieldEdgeInsetHeight, 0, -textFieldEdgeInsetHeight, 0);
		textView.backgroundColor = [UIColor whiteColor];
		textView.layer.borderColor = [UIColor colorWithRed:222/255. green:222/255. blue:230/255. alpha:1].CGColor;
		textView.layer.borderWidth = 1;
		textView.layer.cornerRadius = 6;
		self.backgroundColor = [UIColor colorWithRed:248/255. green:248/255. blue:248/255. alpha:1];
	} else {
		//TODO: Get rid of magic numbers here.
		textViewContentInset = UIEdgeInsetsMake(-textFieldEdgeInsetHeight, -2, -textFieldEdgeInsetHeight, 0);
	}
	textView.contentInset = textViewContentInset;
	textView.showsHorizontalScrollIndicator = NO;
	
	[self.sendButton setTitle:ATLocalizedString(@"Send", @"Send button title") forState:UIControlStateNormal];
	
	[self validateTextField];
	[self resizeTextViewWithString:textView.text animated:NO];
}

- (void)dealloc {
	delegate = nil;
	textView.delegate = nil;
	[textView release], textView = nil;
	[sendButton release], sendButton = nil;
	[attachButton release], attachButton = nil;
	[backgroundImageView release], backgroundImageView = nil;
	[text release], text = nil;
	[super dealloc];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	CGRect textFrame = textView.frame;
	textFrame.origin.x = textViewInsets.left;
	textFrame.size.width = self.bounds.size.width - textViewInsets.left - textViewInsets.right;
	textView.frame = textFrame;
	textView.contentInset = textViewContentInset;
	[self resizeTextViewWithString:textView.text animated:NO];
}

- (BOOL)resignFirstResponder {
	[super resignFirstResponder];
	return textView.resignFirstResponder;
}

- (void)resizeTextViewWithString:(NSString *)string animated:(BOOL)animated {
	if (!string || [string length] == 0) {
		string = @"YWM";
	}
	CGFloat previousHeight = self.frame.size.height;
	
	CGFloat newTextHeight;
	
	if ([ATUtilities osVersionGreaterThanOrEqualTo:@"7"]) {
		if ([string hasSuffix:@"\n"]) {
			string = [NSString stringWithFormat:@"%@-", string];
		}
		CGRect rect = CGRectMake(0, 0, textView.bounds.size.width, 10000);
		CGRect insetRect = UIEdgeInsetsInsetRect(rect, textView.textContainerInset);
		insetRect = UIEdgeInsetsInsetRect(insetRect, textView.contentInset);
		insetRect = CGRectInset(insetRect, textView.textContainer.lineFragmentPadding, 0);
		
		CGFloat width = CGRectGetWidth(insetRect);
		NSDictionary *attrs = [textView typingAttributes];
		NSAttributedString *attributedText = [[[NSAttributedString alloc] initWithString:string attributes:attrs] autorelease];
		CGRect textSize = [attributedText boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
		
		CGFloat verticalPadding = rect.size.height - insetRect.size.height;
		CGFloat actualHeight = ceil(CGRectGetHeight(textSize) + verticalPadding);
		
		CGSize intrinsicContentSize = textView.contentSize;
		intrinsicContentSize.height = actualHeight;
		intrinsicContentSize.width = CGRectGetWidth(rect);
		
		newTextHeight = MIN(maxTextFieldHeight, intrinsicContentSize.height);
	} else {
#		pragma clang diagnostic push
#		pragma clang diagnostic ignored "-Wdeprecated-declarations"
		CGFloat textViewWidth = textView.bounds.size.width;
		CGSize optimisticSize = [string sizeWithFont:textView.font];
		CGSize pessimisticSize = [string sizeWithFont:textView.font constrainedToSize:CGSizeMake(textViewWidth, maxTextFieldHeight) lineBreakMode:NSLineBreakByWordWrapping];
		CGSize contentSize = textView.contentSize;
		
		if ([string hasSuffix:@"\n"]) {
			pessimisticSize.height += textView.font.lineHeight;
		} else if (contentSize.height - textView.font.lineHeight > pessimisticSize.height) {
			pessimisticSize.height = contentSize.height - textView.font.lineHeight + 2;
		}
		newTextHeight = MIN(maxTextFieldHeight, MAX(minTextFieldHeight, MAX(optimisticSize.height, pessimisticSize.height)));
		newTextHeight += -(textView.contentInset.top + textView.contentInset.bottom);
#		pragma clang diagnostic pop
	}
	CGFloat currentTextHeight = textView.bounds.size.height;
	CGFloat textHeightDelta = newTextHeight - currentTextHeight;
	
	CGRect newFrame = self.frame;
	CGFloat newHeight = MAX(minHeight, MIN(newTextHeight + textViewInsets.top + textViewInsets.bottom, newFrame.size.height + textHeightDelta));
	
	CGFloat heightDelta = newHeight - newFrame.size.height;
	newFrame.origin.y = newFrame.origin.y - heightDelta;
	newFrame.size.height = newFrame.size.height + heightDelta;
	
	CGRect newTextFrame = textView.frame;
	newTextFrame.origin.y = textViewInsets.top;
	newTextFrame.size.height = newTextHeight;
	
	NSTimeInterval time = animated ? 0.1 : 0;
	[UIView animateWithDuration:time animations:^{
		textView.overflowing = (BOOL)(newTextHeight >= maxTextFieldHeight);
		textView.scrollEnabled = textView.overflowing;
		self.frame = newFrame;
		textView.frame = newTextFrame;
	} completion:^(BOOL finished) {
		if (previousHeight != newFrame.size.height) {
			[self.delegate messageInputView:self didChangeHeight:newFrame.size.height];
		}
	}];
	
	// Apparent iOS 7 bug where last line of text is not scrolled into view when entering newline characters.
	if ([ATUtilities osVersionGreaterThanOrEqualTo:@"7.0"]) {
		CGRect caretRect = [textView caretRectForPosition:textView.selectedTextRange.start];
		if (!isnan(caretRect.origin.y) && !isinf(caretRect.origin.y)) {
			CGFloat overflow = caretRect.origin.y + caretRect.size.height - (textView.bounds.size.height + textView.contentOffset.y - textView.contentInset.bottom - textView.contentInset.top);
			if (overflow > 0){
				CGPoint offset = textView.contentOffset;
				offset.y += overflow + 12;
				
				[textView setContentOffset:offset animated:animated];
			}
		}
	}
}

- (void)validateTextField {
	if (self.allowsEmptyText) {
		self.sendButton.enabled = YES;
	} else {
		NSString *trimmedText = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		BOOL textIsEmpty = (trimmedText == nil || [trimmedText length] == 0);
		self.sendButton.enabled = !textIsEmpty;
	}
}

- (IBAction)sendPressed:(id)sender {
	[self.delegate messageInputViewSendPressed:self];
}

- (IBAction)attachPressed:(id)sender {
	[self.delegate messageInputViewAttachPressed:self];
}

#pragma mark Properties
- (void)setText:(NSString *)string {
	textView.text = string;
	// The text view delegate method is not called on a direct change to the text property.
	[self textViewDidChange:textView];
}

- (NSString *)text {
	return textView.text;
}

- (NSString *)placeholder {
	return [textView placeholder];
}

- (void)setPlaceholder:(NSString *)placeholder {
	[textView setPlaceholder:placeholder];
}

- (void)setAllowsEmptyText:(BOOL)allow {
	if (allow != allowsEmptyText) {
		allowsEmptyText = allow;
		[self validateTextField];
	}
}

- (void)setBackgroundImage:(UIImage *)backgroundImage {
	backgroundImageView.image = backgroundImage;
}

- (UIImage *)backgroundImage {
	return backgroundImageView.image;
}

#pragma mark UITextViewDelegate
- (void)textViewDidBeginEditing:(UITextView *)aTextView {
	[self resizeTextViewWithString:textView.text animated:YES];
	[self.delegate messageInputViewDidChange:self];
}

- (void)textViewDidEndEditing:(UITextView *)aTextView {
	[self resizeTextViewWithString:textView.text animated:YES];
	[self.delegate messageInputViewDidChange:self];
}

- (void)textViewDidChange:(UITextView *)aTextView {
	[self validateTextField];
	[self resizeTextViewWithString:textView.text animated:YES];
	[self.delegate messageInputViewDidChange:self];
}

- (BOOL)textView:(UITextView *)aTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)string {
	// We want to size for the new string, not the old.
	NSString *newString = [textView.text stringByReplacingCharactersInRange:range withString:string];
	[self resizeTextViewWithString:newString animated:YES];
	return YES;
}

- (void)textViewDidChangeSelection:(UITextView *)aTextView {
	NSRange selectedRange = [textView selectedRange];
	if (selectedRange.location != NSNotFound) {
		[textView scrollRangeToVisible:selectedRange];
	}
}
@end

@implementation ATMessageTextView
@synthesize overflowing;

- (void)setContentOffset:(CGPoint)offset animated:(BOOL)animated {
	if (overflowing == NO) {
		// Don't scroll if we're not overflowing.
		[super setContentOffset:CGPointZero animated:animated];
	} else if (offset.y < (self.contentSize.height - self.bounds.size.height + self.contentInset.bottom + self.contentInset.top)) {
		// If the text selection changes to contain text above the current text viewport,
		// we want to show the cursor.
		offset.y += self.contentInset.top;
		[super setContentOffset:offset animated:animated];
	} else {
		// Otherwise, scroll the bottom portion of the text view into the viewport.
		CGPoint scrollpoint = CGPointMake(offset.x, self.contentSize.height - self.bounds.size.height + self.contentInset.bottom);
		[super setContentOffset:scrollpoint animated:animated];
	}
}
@end
