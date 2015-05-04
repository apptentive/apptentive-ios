//
//  ATMessageInputView.h
//  ResizingTextView
//
//  Created by Andrew Wooster on 3/29/13.
//  Copyright (c) 2013 Andrew Wooster. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ATDefaultTextView.h"

@protocol ATMessageInputViewDelegate;
@class ATMessageTextView;

@interface ATMessageInputView : UIView <UITextViewDelegate>@property (nonatomic, strong) IBOutlet UIButton *sendButton;
@property (nonatomic, weak) NSObject<ATMessageInputViewDelegate> *delegate;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *placeholder;
@property (nonatomic, assign) BOOL allowsEmptyText;
@property (nonatomic, strong) UIImage *backgroundImage;
@property (nonatomic, strong) IBOutlet UIButton *attachButton;
@end

@protocol ATMessageInputViewDelegate <NSObject>
- (void)messageInputView:(ATMessageInputView *)inputView didChangeHeight:(CGFloat)height;
- (void)messageInputViewDidChange:(ATMessageInputView *)inputView;
- (void)messageInputViewSendPressed:(ATMessageInputView *)inputView;
- (void)messageInputViewAttachPressed:(ATMessageInputView *)inputView;
@end


@interface ATMessageTextView : ATDefaultTextView
@property (nonatomic, assign) BOOL overflowing;
@end
