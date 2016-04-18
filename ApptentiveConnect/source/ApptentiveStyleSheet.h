//
//  ApptentiveStyleSheet.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 3/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The ApptentiveStyle protocol allows extensive customization of the fonts and colors used by the Apptentive SDK's UI.
 
 A class implementing this protocol must handle resizing text according to the applications content size to support dynamic type.
 */
@protocol ApptentiveStyle <NSObject>

/**
 @param textStyle the text style whose font should be returned.
 @return the font to use for the given style.
 */
- (UIFont *)fontForStyle:(NSString *)textStyle;

/**
 @param style the style whose color should be returned.
 @return the color to use for the given style.
 */
- (UIColor *)colorForStyle:(NSString *)style;

@end

/// The text style for the title text of the greeting view in Message Center.
extern NSString *const ApptentiveTextStyleHeaderTitle;

/// The text style for the message text of the greeting view in Message Center.
extern NSString *const ApptentiveTextStyleHeaderMessage;

/// The text style for the date lables in Message Center.
extern NSString *const ApptentiveTextStyleMessageDate;

/// The text style for the message sender text in Message Center.
extern NSString *const ApptentiveTextStyleMessageSender;

/// The text style for the message status text in Message Center.
extern NSString *const ApptentiveTextStyleMessageStatus;

/// The text style for the message center status text in Message Center.
extern NSString *const ApptentiveTextStyleMessageCenterStatus;

/// The text style for the survey description text.
extern NSString *const ApptentiveTextStyleSurveyInstructions;

/// The text style for buttons that make changes when tapped.
extern NSString *const ApptentiveTextStyleDoneButton;

/// The text style for buttons that cancel or otherwise don't make changes when tapped.
extern NSString *const ApptentiveTextStyleButton;

/// The text style for the the submit button on Surveys.
extern NSString *const ApptentiveTextStyleSubmitButton;

/// The text style for text input fields.
extern NSString *const ApptentiveTextStyleTextInput;


/// The background color for headers in Message Center and Surveys.
extern NSString *const ApptentiveColorHeaderBackground;

/// The background color for the footer in Surveys.
extern NSString *const ApptentiveColorFooterBackground;

/// The foreground color for text and borders indicating a failure of validation or sending.
extern NSString *const ApptentiveColorFailure;

/// The foreground color for borders in Message Center and Surveys.
extern NSString *const ApptentiveColorSeparator;

/// The background color for cells in Message Center and Surveys.
extern NSString *const ApptentiveColorBackground;

/// The background color for table- and collection views.
extern NSString *const ApptentiveColorCollectionBackground;

/// The background color for text input fields. Changing this may render placeholder invisible.
extern NSString *const ApptentiveColorTextInputBackground;

/// The background color for message cells in Message Center.
extern NSString *const ApptentiveColorMessageBackground;

/// The background color for reply cells in Message Center.
extern NSString *const ApptentiveColorReplyBackground;

/// The background color for context cells in Message Center.
extern NSString *const ApptentiveColorContextBackground;


/**
 
 The ApptentiveStyleSheet class is a default implementation of the ApptentiveStyle protocol. 
 
 You can set the font family, describe the various font faces to be used in various situations, and set the colors for various styles. 
 Additionally you can specify overrides for the color and (if appropriate) font for various UI elements. 
 
 This class can be used as-is or subclassed for finer-grained control over styling.
 
 ## Font Families and Faces
 
 You can view a list of fonts shipped with iOS at http://iosfonts.com/. The value for the `fontFamily` property is
 the font name as listed in the heading for each font. The default is the system font for the device.
 
 You will likely have to specify a modifier for one or more
 weights of the font. By default, the modifier is the capitalized name of the face attribute, preceded by a dash 
 (for example, the default value for `lightFaceAttribute` is "Light", which corresponds to a suffix of "-Light").
 
 If you would like to use a face with no suffix, set the face attribute to `nil`. If the font you choose has
 fewer weights than the four listed here, you can set two or more of the face attributes to the same value.

 */
@interface ApptentiveStyleSheet : NSObject <ApptentiveStyle>

/// The font family to be used in the Apptentive UI
@property (strong, nonatomic) NSString *fontFamily;

/// The font face suffix for a light weight of the font.
@property (strong, nonatomic, nullable) NSString *lightFaceAttribute;

/// The font face suffix for a regular/book weight of the font.
@property (strong, nonatomic, nullable) NSString *regularFaceAttribute;

/// The font face suffix for a medium weight of the font.
@property (strong, nonatomic, nullable) NSString *mediumFaceAttribute;

/// The font face suffix for a bold weight of the font.
@property (strong, nonatomic, nullable) NSString *boldFaceAttribute;

/**
 The primary text color to use in the Apptentive UI. Defaults to black. 
 
 @note This color should be easily readable when contrasted against the value for the `backgroundColor` property.
 */
@property (strong, nonatomic) UIColor *primaryColor;

/**
The secondary text color to use in the Apptentive UI. Defaults to #8E8E93.
 
 @note This color should be readable when contrasted against the value for the `backgroundColor` property, but should
 typically be lower contrast than the value for the `primaryColor` property.
*/
@property (strong, nonatomic) UIColor *secondaryColor;

/**
 The color to use for text and borders that indicate failure. Defaults to #DA3547.

 @note This color should be easily readable when contrasted against the value for the `backgroundColor` property.
 */
@property (strong, nonatomic) UIColor *failureColor;

/// The color to use for the text background. Defaults to white.
@property (strong, nonatomic) UIColor *backgroundColor;

/// The color to use for lines separating parts of the Apptentive UI.
@property (strong, nonatomic) UIColor *separatorColor;

/// The color to use for the background of collection views and grouped table views.
@property (strong, nonatomic) UIColor *collectionBackgroundColor;

/// A global multiplier applied to all font sizes other than those with explicit overrides.
@property (assign, nonatomic) CGFloat sizeAdjustment;

/** 
 Explicitly overrides the font for a particular style of text. 
 
 @param fontDescriptor A descriptor for the font that should be used in place of the default.
 @param style The style whose font should be overridden.

 @note Setting an override will prevent text in that style from respecting the device's dynamic type settings.
*/
- (void)setFontDescriptor:(UIFontDescriptor *)fontDescriptor forStyle:(NSString *)style;

/**
 Explicitly overrides the color for a particular style.
 
 @param color The color that should be used in place of the default.
 @param style The style whose color should be overridden.
 */
- (void)setColor:(UIColor *)color forStyle:(NSString *)style;

@end

NS_ASSUME_NONNULL_END
