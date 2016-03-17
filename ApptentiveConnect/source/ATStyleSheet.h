//
//  ATStyleSheet.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 3/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ApptentiveStyle <NSObject>

- (UIFont *)fontForStyle:(NSString *)textStyle;
- (UIColor *)colorForStyle:(NSString *)style;

@end

extern NSString * const ApptentiveStyleSheetDidUpdateNotification;

extern NSString * const ApptentiveTextStyleHeaderTitle;
extern NSString * const ApptentiveTextStyleHeaderMessage;
extern NSString * const ApptentiveTextStyleMessageDate;
extern NSString * const ApptentiveTextStyleMessageSender;
extern NSString * const ApptentiveTextStyleMessageStatus;
extern NSString * const ApptentiveTextStyleMessageCenterStatus;
extern NSString * const ApptentiveTextStyleSurveyInstructions;
extern NSString * const ApptentiveTextStyleDoneButton;
extern NSString * const ApptentiveTextStyleButton;
extern NSString * const ApptentiveTextStyleSubmitButton;

extern NSString * const ApptentiveColorHeaderBackground;
extern NSString * const ApptentiveColorFooterBackground;
extern NSString * const ApptentiveColorFailure;
extern NSString * const ApptentiveColorSeparator;
extern NSString * const ApptentiveColorBackground;

@interface ATStyleSheet : NSObject <ApptentiveStyle>

@property (strong, nonatomic) NSString *fontFamily;
@property (strong, nonatomic) NSString * _Nullable lightFaceAttribute;
@property (strong, nonatomic) NSString * _Nullable regularFaceAttribute;
@property (strong, nonatomic) NSString * _Nullable mediumFaceAttribute;
@property (strong, nonatomic) NSString * _Nullable boldFaceAttribute;

@property (strong, nonatomic) UIColor *primaryColor;
@property (strong, nonatomic) UIColor *secondaryColor;
@property (strong, nonatomic) UIColor *failureColor;
@property (strong, nonatomic) UIColor *backgroundColor;
@property (strong, nonatomic) UIColor *separatorColor;

@property (assign, nonatomic) CGFloat sizeAdjustment;

- (void)setFontDescriptor:(UIFontDescriptor *)fontDescriptor forStyle:(NSString *)style;
- (void)setColor:(UIColor *)color forStyle:(NSString *)style;

@end

NS_ASSUME_NONNULL_END
