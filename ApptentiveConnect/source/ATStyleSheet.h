//
//  ATStyleSheet.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 3/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const ApptentiveStyleSheetDidUpdateNotification;
extern NSString * const ApptentiveColorKey;

extern NSString * const ApptentiveTextStyleMessageDate;

@interface ATStyleSheet : NSObject

+ (instancetype)styleSheet;
+ (NSString *)defaultFontFamilyName;
+ (NSDictionary <NSString *, UIFont *>*)defaultFonts;

@property (strong, nonatomic) NSString *fontFamily;
@property (assign, nonatomic) CGFloat sizeAdjustment;
@property (assign, nonatomic) BOOL useDynamicType;

- (UIFontDescriptor *)preferredFontDescriptorWithTextStyle:(NSString *)textStyle;

@end

NS_ASSUME_NONNULL_END
