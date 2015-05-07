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

@property (assign, nonatomic) CGFloat minHeight;
@property (assign, nonatomic) CGFloat textFieldEdgeInsetHeight;
@property (assign, nonatomic) CGFloat minTextFieldHeight;
@property (assign, nonatomic) CGFloat maxTextFieldHeight;
@property (assign, nonatomic) NSUInteger maxNumberOfLines;
@property (assign, nonatomic) UIEdgeInsets textViewInsets;

@property (assign, nonatomic) UIEdgeInsets textViewContentInset;
@property (strong, nonatomic) IBOutlet ATMessageTextView *textView;
@property (strong, nonatomic) IBOutlet UIImageView *backgroundImageView;

@end

@implementation ATMessageInputView

- (void)awakeFromNib {
	[super awakeFromNib];
	self.maxNumberOfLines = 5;
	
	self.textViewInsets = insetsForView(self.textView);
	
	self.textView.delegate = self;
	self.minHeight = self.bounds.size.height;
	self.textFieldEdgeInsetHeight = 4;
	self.minTextFieldHeight = self.textView.font.lineHeight + (2 * self.textFieldEdgeInsetHeight);
	self.maxTextFieldHeight = self.textView.font.lineHeight * self.maxNumberOfLines + (2 * self.textFieldEdgeInsetHeight);
	
	self.textView.backgroundColor = [UIColor clearColor];
	
	self.textView.autoresizingMask = UIViewAutoresizingNone;
	if ([ATUtilities osVersionGreaterThanOrEqualTo:@"7"]) {
		self.textViewContentInset = UIEdgeInsetsMake(-self.textFieldEdgeInsetHeight, 0, -self.textFieldEdgeInsetHeight, 0);
		self.textView.backgroundColor = [UIColor whiteColor];
		self.textView.layer.borderColor = [UIColor colorWithRed:222/255. green:222/255. blue:230/255. alpha:1].CGColor;
		self.textView.layer.borderWidth = 1;
		self.textView.layer.cornerRadius = 6;
		self.backgroundColor = [UIColor colorWithRed:248/255. green:248/255. blue:248/255. alpha:1];
	} else {
		//TODO: Get rid of magic numbers here.
		self.textViewContentInset = UIEdgeInsetsMake(-self.textFieldEdgeInsetHeight, -2, -self.textFieldEdgeInsetHeight, 0);
	}
	self.textView.contentInset = self.textViewContentInset;
	self.textView.showsHorizontalScrollIndicator = NO;
	
	[self.sendButton setTitle:ATLocalizedString(@"Send", @"Send button title") forState:UIControlStateNormal];
	
	[self validateTextField];
	[self resizeTextViewWithString:self.textView.text animated:NO];
}

- (void)dealloc {
	self.textView.delegate = nil;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	CGRect textFrame = self.textView.frame;
	textFrame.origin.x = self.textViewInsets.left;
	textFrame.size.width = self.bounds.size.width - self.textViewInsets.left - self.textViewInsets.right;
	self.textView.frame = textFrame;
	self.textView.contentInset = self.textViewContentInset;
	[self resizeTextViewWithString:self.textView.text animated:NO];
}

- (BOOL)resignFirstResponder {
	[super resignFirstResponder];
	return self.textView.resignFirstResponder;
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
		CGRect rect = CGRectMake(0, 0, self.textView.bounds.size.width, 10000);
		CGRect insetRect = UIEdgeInsetsInsetRect(rect, self.textView.textContainerInset);
		insetRect = UIEdgeInsetsInsetRect(insetRect, self.textView.contentInset);
		insetRect = CGRectInset(insetRect, self.textView.textContainer.lineFragmentPadding, 0);
		
		CGFloat width = CGRectGetWidth(insetRect);
		NSDictionary *attrs = [self.textView typingAttributes];
		NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:string attributes:attrs];
		CGRect textSize = [attributedText boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
		
		CGFloat verticalPadding = rect.size.height - insetRect.size.height;
		CGFloat actualHeight = ceil(CGRectGetHeight(textSize) + verticalPadding);
		
		CGSize intrinsicContentSize = self.textView.contentSize;
		intrinsicContentSize.height = actualHeight;
		intrinsicContentSize.width = CGRectGetWidth(rect);
		
		newTextHeight = MIN(self.maxTextFieldHeight, intrinsicContentSize.height);
	} else {
#		pragma clang diagnostic push
#		pragma clang diagnostic ignored "-Wdeprecated-declarations"
		CGFloat textViewWidth = self.textView.bounds.size.width;
		CGSize optimisticSize = [string sizeWithFont:self.textView.font];
		CGSize pessimisticSize = [string sizeWithFont:self.textView.font constrainedToSize:CGSizeMake(textViewWidth, self.maxTextFieldHeight) lineBreakMode:NSLineBreakByWordWrapping];
		CGSize contentSize = self.textView.contentSize;
		
		if ([string hasSuffix:@"\n"]) {
			pessimisticSize.height += self.textView.font.lineHeight;
		} else if (contentSize.height - self.textView.font.lineHeight > pessimisticSize.height) {
			pessimisticSize.height = contentSize.height - self.textView.font.lineHeight + 2;
		}
		newTextHeight = MIN(self.maxTextFieldHeight, MAX(self.minTextFieldHeight, MAX(optimisticSize.height, pessimisticSize.height)));
		newTextHeight += -(self.textView.contentInset.top + self.textView.contentInset.bottom);
#		pragma clang diagnostic pop
	}
	CGFloat currentTextHeight = self.textView.bounds.size.height;
	CGFloat textHeightDelta = newTextHeight - currentTextHeight;
	
	CGRect newFrame = self.frame;
	CGFloat newHeight = MAX(self.minHeight, MIN(newTextHeight + self.textViewInsets.top + self.textViewInsets.bottom, newFrame.size.height + textHeightDelta));
	
	CGFloat heightDelta = newHeight - newFrame.size.height;
	newFrame.origin.y = newFrame.origin.y - heightDelta;
	newFrame.size.height = newFrame.size.height + heightDelta;
	
	CGRect newTextFrame = self.textView.frame;
	newTextFrame.origin.y = self.textViewInsets.top;
	newTextFrame.size.height = newTextHeight;
	
	NSTimeInterval time = animated ? 0.1 : 0;
	[UIView animateWithDuration:time animations:^{
		self.textView.overflowing = (BOOL)(newTextHeight >= self.maxTextFieldHeight);
		self.textView.scrollEnabled = self.textView.overflowing;
		self.frame = newFrame;
		self.textView.frame = newTextFrame;
	} completion:^(BOOL finished) {
		if (previousHeight != newFrame.size.height) {
			[self.delegate messageInputView:self didChangeHeight:newFrame.size.height];
		}
	}];
	
	// Apparent iOS 7 bug where last line of text is not scrolled into view when entering newline characters.
	if ([ATUtilities osVersionGreaterThanOrEqualTo:@"7.0"]) {
		CGRect caretRect = [self.textView caretRectForPosition:self.textView.selectedTextRange.start];
		if (!isnan(caretRect.origin.y) && !isinf(caretRect.origin.y)) {
			CGFloat overflow = caretRect.origin.y + caretRect.size.height - (self.textView.bounds.size.height + self.textView.contentOffset.y - self.textView.contentInset.bottom - self.textView.contentInset.top);
			if (overflow > 0){
				CGPoint offset = self.textView.contentOffset;
				offset.y += overflow + 12;
				
				[self.textView setContentOffset:offset animated:animated];
			}
		}
	}
}

- (void)validateTextField {
	if (self.allowsEmptyText) {
		self.sendButton.enabled = YES;
	} else {
		NSString *trimmedText = [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
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
	self.textView.text = string;
	// The text view delegate method is not called on a direct change to the text property.
	[self textViewDidChange:self.textView];
}

- (NSString *)text {
	return self.textView.text;
}

- (NSString *)placeholder {
	return [self.textView placeholder];
}

- (void)setPlaceholder:(NSString *)placeholder {
	[self.textView setPlaceholder:placeholder];
}

- (void)setAllowsEmptyText:(BOOL)allow {
	if (allow != self.allowsEmptyText) {
		self.allowsEmptyText = allow;
		[self validateTextField];
	}
}

- (void)setBackgroundImage:(UIImage *)backgroundImage {
	self.backgroundImageView.image = backgroundImage;
}

- (UIImage *)backgroundImage {
	return self.backgroundImageView.image;
}

#pragma mark UITextViewDelegate
- (void)textViewDidBeginEditing:(UITextView *)aTextView {
	[self resizeTextViewWithString:self.textView.text animated:YES];
	[self.delegate messageInputViewDidChange:self];
}

- (void)textViewDidEndEditing:(UITextView *)aTextView {
	[self resizeTextViewWithString:self.textView.text animated:YES];
	[self.delegate messageInputViewDidChange:self];
}

- (void)textViewDidChange:(UITextView *)aTextView {
	[self validateTextField];
	[self resizeTextViewWithString:self.textView.text animated:YES];
	[self.delegate messageInputViewDidChange:self];
}

- (BOOL)textView:(UITextView *)aTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)string {
	// We want to size for the new string, not the old.
	NSString *newString = [self.textView.text stringByReplacingCharactersInRange:range withString:string];
	[self resizeTextViewWithString:newString animated:YES];
	return YES;
}

- (void)textViewDidChangeSelection:(UITextView *)aTextView {
	NSRange selectedRange = [self.textView selectedRange];
	if (selectedRange.location != NSNotFound) {
		[self.textView scrollRangeToVisible:selectedRange];
	}
}
@end

@implementation ATMessageTextView

- (void)setContentOffset:(CGPoint)offset animated:(BOOL)animated {
	if (self.overflowing == NO) {
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
