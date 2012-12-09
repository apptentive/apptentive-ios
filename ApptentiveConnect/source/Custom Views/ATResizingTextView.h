//
//  ATResizingTextView.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/1/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ATResizingTextViewDelegate;

typedef enum {
	ATResizingTextViewStyleIOS,
	ATResizingTextViewStyleV2
} ATResizingTextViewStyle;

@interface ATResizingTextView : UIView <UITextViewDelegate>
@property (nonatomic, assign) IBOutlet NSObject<ATResizingTextViewDelegate> *delegate;
@property (nonatomic, assign) NSUInteger maximumVeritcalLines;
@property (nonatomic, assign) ATResizingTextViewStyle style;

#pragma mark ATDefaultTextView
@property (nonatomic, retain) NSString *placeholder;
- (BOOL)isDefault;

#pragma mark UITextView
@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) UIFont *font;

@end


@protocol ATResizingTextViewDelegate <NSObject>
- (void)resizingTextView:(ATResizingTextView *)textView willChangeHeight:(CGFloat)height;
- (void)resizingTextView:(ATResizingTextView *)textView didChangeHeight:(CGFloat)height;

@optional
- (BOOL)resizingTextViewShouldBeginEditing:(ATResizingTextView *)textView;
- (BOOL)resizingTextViewShouldEndEditing:(ATResizingTextView *)textView;

- (void)resizingTextViewDidBeginEditing:(ATResizingTextView *)textView;
- (void)resizingTextViewDidEndEditing:(ATResizingTextView *)textView;

- (BOOL)resizingTextView:(ATResizingTextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
- (void)resizingTextViewDidChange:(ATResizingTextView *)textView;

- (void)resizingTextViewDidChangeSelection:(ATResizingTextView *)textView;
@end
