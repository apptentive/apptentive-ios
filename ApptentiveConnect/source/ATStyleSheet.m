//
//  ATStyleSheet.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 3/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATStyleSheet.h"
#import "ATConnect.h"

//NSString * const ApptentiveStyleSheetDidUpdateNotification = @"com.apptentive.stylesheetDidUpdate";

NSString * const ApptentiveTextStyleHeaderTitle = @"com.apptentive.headerTitle";
NSString * const ApptentiveTextStyleHeaderMessage = @"com.apptentive.headerMessage";
NSString * const ApptentiveTextStyleMessageDate = @"com.apptentive.messageDate";
NSString * const ApptentiveTextStyleMessageSender = @"com.apptentive.messageSender";
NSString * const ApptentiveTextStyleMessageStatus = @"com.apptentive.messageStatus";
NSString * const ApptentiveTextStyleMessageCenterStatus = @"com.apptentive.messageCenterStatus";
NSString * const ApptentiveTextStyleSurveyInstructions = @"com.apptentive.surveyInstructions";
NSString * const ApptentiveTextStyleDoneButton = @"com.apptentive.doneButton";
NSString * const ApptentiveTextStyleButton = @"com.apptentive.button";
NSString * const ApptentiveTextStyleSubmitButton = @"com.apptentive.submitButton";

NSString * const ApptentiveColorHeaderBackground = @"com.apptentive.headerBackgroundColor";
NSString * const ApptentiveColorFooterBackground = @"com.apptentive.footerBackgroundColor";
NSString * const ApptentiveColorFailure = @"com.apptentive.failureColor";
NSString * const ApptentiveColorSeparator = @"com.apptentive.separatorColor";
NSString * const ApptentiveColorBackground = @"com.apptentive.backgroundColor";

@interface ATStyleSheet ()

@property (strong, nonatomic) NSMutableDictionary *fontDescriptorOverrides;
@property (strong, nonatomic) NSMutableDictionary *colorOverrides;

@property (strong, nonatomic) NSMutableDictionary *fontTable;

+ (NSArray *)UIKitTextStyles;
+ (NSArray *)apptentiveTextStyles;
+ (NSArray *)apptentiveColorStyles;

+ (NSNumber *)sizeForTextStyle:(NSString *)textStyle;
+ (NSInteger)weightForTextStyle:(NSString *)textStyle;

+ (NSString *)defaultFontFamilyName;
- (UIFontDescriptor *)fontDescriptorForStyle:(NSString *)textStyle;
- (NSString *)faceAttributeForWeight:(NSInteger)weight;

@end

@implementation ATStyleSheet

// TODO: Adjust for content size category?
+ (NSInteger)weightForTextStyle:(NSString *)textStyle {
	static NSDictionary<NSString *, NSNumber *> *faceForStyle;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		faceForStyle = @{
						 ApptentiveTextStyleHeaderTitle: @300,
						 ApptentiveTextStyleHeaderMessage: @400,
						 ApptentiveTextStyleMessageDate: @700,
						 ApptentiveTextStyleMessageSender: @700,
						 ApptentiveTextStyleMessageStatus: @700,
						 ApptentiveTextStyleMessageCenterStatus: @700,
						 ApptentiveTextStyleSurveyInstructions: @400,
						 ApptentiveTextStyleButton: @400,
						 ApptentiveTextStyleDoneButton: @700,
						 ApptentiveTextStyleSubmitButton: @500
						 };
	});
	return faceForStyle[textStyle].integerValue;
}

+ (NSNumber *)sizeForTextStyle:(NSString *)textStyle {
	static NSDictionary <NSString *, NSDictionary <NSString *, NSNumber *> *> *sizeForCategoryForStyle;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sizeForCategoryForStyle = @{
									ApptentiveTextStyleHeaderTitle: @{
											UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @28,
											UIContentSizeCategoryAccessibilityExtraExtraLarge: @28,
											UIContentSizeCategoryAccessibilityExtraLarge: @27,
											UIContentSizeCategoryAccessibilityLarge: @27,
											UIContentSizeCategoryAccessibilityMedium: @26,
											UIContentSizeCategoryExtraExtraExtraLarge: @26,
											UIContentSizeCategoryExtraExtraLarge: @25,
											UIContentSizeCategoryExtraLarge: @24,
											UIContentSizeCategoryLarge: @23,
											UIContentSizeCategoryMedium: @22,
											UIContentSizeCategorySmall: @21,
											UIContentSizeCategoryExtraSmall: @20
											},
									ApptentiveTextStyleHeaderMessage:  @{
											UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @22,
											UIContentSizeCategoryAccessibilityExtraExtraLarge: @21,
											UIContentSizeCategoryAccessibilityExtraLarge: @20,
											UIContentSizeCategoryAccessibilityLarge: @20,
											UIContentSizeCategoryAccessibilityMedium: @19,
											UIContentSizeCategoryExtraExtraExtraLarge: @19,
											UIContentSizeCategoryExtraExtraLarge: @18,
											UIContentSizeCategoryExtraLarge: @17,
											UIContentSizeCategoryLarge: @16,
											UIContentSizeCategoryMedium: @15,
											UIContentSizeCategorySmall: @14,
											UIContentSizeCategoryExtraSmall: @13
											},
									ApptentiveTextStyleMessageDate: @{
											UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @21,
											UIContentSizeCategoryAccessibilityExtraExtraLarge: @20,
											UIContentSizeCategoryAccessibilityExtraLarge: @19,
											UIContentSizeCategoryAccessibilityLarge: @19,
											UIContentSizeCategoryAccessibilityMedium: @18,
											UIContentSizeCategoryExtraExtraExtraLarge: @18,
											UIContentSizeCategoryExtraExtraLarge: @17,
											UIContentSizeCategoryExtraLarge: @16,
											UIContentSizeCategoryLarge: @15,
											UIContentSizeCategoryMedium: @14,
											UIContentSizeCategorySmall: @13,
											UIContentSizeCategoryExtraSmall: @12
											},
									ApptentiveTextStyleMessageSender: @{
											UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @21,
											UIContentSizeCategoryAccessibilityExtraExtraLarge: @20,
											UIContentSizeCategoryAccessibilityExtraLarge: @19,
											UIContentSizeCategoryAccessibilityLarge: @19,
											UIContentSizeCategoryAccessibilityMedium: @18,
											UIContentSizeCategoryExtraExtraExtraLarge: @18,
											UIContentSizeCategoryExtraExtraLarge: @17,
											UIContentSizeCategoryExtraLarge: @16,
											UIContentSizeCategoryLarge: @15,
											UIContentSizeCategoryMedium: @14,
											UIContentSizeCategorySmall: @13,
											UIContentSizeCategoryExtraSmall: @12
											},
									ApptentiveTextStyleMessageStatus: @{
											UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @18,
											UIContentSizeCategoryAccessibilityExtraExtraLarge: @17,
											UIContentSizeCategoryAccessibilityExtraLarge: @16,
											UIContentSizeCategoryAccessibilityLarge: @16,
											UIContentSizeCategoryAccessibilityMedium: @15,
											UIContentSizeCategoryExtraExtraExtraLarge: @15,
											UIContentSizeCategoryExtraExtraLarge: @14,
											UIContentSizeCategoryExtraLarge: @14,
											UIContentSizeCategoryLarge: @13,
											UIContentSizeCategoryMedium: @12,
											UIContentSizeCategorySmall: @12,
											UIContentSizeCategoryExtraSmall: @11
											},
									ApptentiveTextStyleMessageCenterStatus: @{
											UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @18,
											UIContentSizeCategoryAccessibilityExtraExtraLarge: @17,
											UIContentSizeCategoryAccessibilityExtraLarge: @16,
											UIContentSizeCategoryAccessibilityLarge: @16,
											UIContentSizeCategoryAccessibilityMedium: @15,
											UIContentSizeCategoryExtraExtraExtraLarge: @15,
											UIContentSizeCategoryExtraExtraLarge: @14,
											UIContentSizeCategoryExtraLarge: @14,
											UIContentSizeCategoryLarge: @13,
											UIContentSizeCategoryMedium: @12,
											UIContentSizeCategorySmall: @12,
											UIContentSizeCategoryExtraSmall: @11
											},
									ApptentiveTextStyleSurveyInstructions: @{
											UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @18,
											UIContentSizeCategoryAccessibilityExtraExtraLarge: @17,
											UIContentSizeCategoryAccessibilityExtraLarge: @16,
											UIContentSizeCategoryAccessibilityLarge: @16,
											UIContentSizeCategoryAccessibilityMedium: @15,
											UIContentSizeCategoryExtraExtraExtraLarge: @15,
											UIContentSizeCategoryExtraExtraLarge: @14,
											UIContentSizeCategoryExtraLarge: @14,
											UIContentSizeCategoryLarge: @13,
											UIContentSizeCategoryMedium: @12,
											UIContentSizeCategorySmall: @12,
											UIContentSizeCategoryExtraSmall: @11
											},
									ApptentiveTextStyleButton: @{
											UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @22,
											UIContentSizeCategoryAccessibilityExtraExtraLarge: @21,
											UIContentSizeCategoryAccessibilityExtraLarge: @20,
											UIContentSizeCategoryAccessibilityLarge: @20,
											UIContentSizeCategoryAccessibilityMedium: @19,
											UIContentSizeCategoryExtraExtraExtraLarge: @19,
											UIContentSizeCategoryExtraExtraLarge: @18,
											UIContentSizeCategoryExtraLarge: @17,
											UIContentSizeCategoryLarge: @16,
											UIContentSizeCategoryMedium: @15,
											UIContentSizeCategorySmall: @14,
											UIContentSizeCategoryExtraSmall: @13
											},
									ApptentiveTextStyleDoneButton: @{
											UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @22,
											UIContentSizeCategoryAccessibilityExtraExtraLarge: @21,
											UIContentSizeCategoryAccessibilityExtraLarge: @20,
											UIContentSizeCategoryAccessibilityLarge: @20,
											UIContentSizeCategoryAccessibilityMedium: @19,
											UIContentSizeCategoryExtraExtraExtraLarge: @19,
											UIContentSizeCategoryExtraExtraLarge: @18,
											UIContentSizeCategoryExtraLarge: @17,
											UIContentSizeCategoryLarge: @16,
											UIContentSizeCategoryMedium: @15,
											UIContentSizeCategorySmall: @14,
											UIContentSizeCategoryExtraSmall: @13
											},
									ApptentiveTextStyleSubmitButton: @{
											UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @26,
											UIContentSizeCategoryAccessibilityExtraExtraLarge: @26,
											UIContentSizeCategoryAccessibilityExtraLarge: @25,
											UIContentSizeCategoryAccessibilityLarge: @25,
											UIContentSizeCategoryAccessibilityMedium: @24,
											UIContentSizeCategoryExtraExtraExtraLarge: @24,
											UIContentSizeCategoryExtraExtraLarge: @23,
											UIContentSizeCategoryExtraLarge: @22,
											UIContentSizeCategoryLarge: @22,
											UIContentSizeCategoryMedium: @20,
											UIContentSizeCategorySmall: @19,
											UIContentSizeCategoryExtraSmall: @18
											}
									};
	});
	return sizeForCategoryForStyle[textStyle][[UIApplication sharedApplication].preferredContentSizeCategory];
}

+ (NSArray *)UIKitTextStyles {
	static NSArray *_UIKitTextStyles;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		if ([[NSProcessInfo processInfo] respondsToSelector:@selector(isOperatingSystemAtLeastVersion:)] && [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){ 9, 0, 0}]) {
		_UIKitTextStyles = @[
							 UIFontTextStyleBody,
							 UIFontTextStyleCallout,
							 UIFontTextStyleCaption1,
							 UIFontTextStyleCaption2,
							 UIFontTextStyleFootnote,
							 UIFontTextStyleHeadline,
							 UIFontTextStyleSubheadline,
							 UIFontTextStyleTitle1,
							 UIFontTextStyleTitle2,
							 UIFontTextStyleTitle3,
							 ];
		} else {
			_UIKitTextStyles = @[
								 UIFontTextStyleBody,
								 UIFontTextStyleCaption1,
								 UIFontTextStyleCaption2,
								 UIFontTextStyleFootnote,
								 UIFontTextStyleHeadline,
								 UIFontTextStyleSubheadline,
								 ];
		}
	});
	return _UIKitTextStyles;
}

+ (NSArray *)apptentiveTextStyles {
	static NSArray *_apptentiveStyleNames;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_apptentiveStyleNames = @[
								  ApptentiveTextStyleHeaderTitle,
								  ApptentiveTextStyleHeaderMessage,
								  ApptentiveTextStyleMessageDate,
								  ApptentiveTextStyleMessageSender,
								  ApptentiveTextStyleMessageStatus,
								  ApptentiveTextStyleDoneButton,
								  ApptentiveTextStyleButton,
								  ApptentiveTextStyleSubmitButton
								  ];
	});
	return _apptentiveStyleNames;
}

+ (NSArray *)apptentiveColorStyles {
	static NSArray *_apptentiveColorStyles;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_apptentiveColorStyles = @[
								   ApptentiveColorHeaderBackground,
								   ApptentiveColorFooterBackground,
								   ApptentiveColorFailure
								   ];
	});
	return _apptentiveColorStyles;
}

+ (NSString *)defaultFontFamilyName {
	return [UIFont systemFontOfSize:[UIFont systemFontSize]].familyName;
}

+ (instancetype)styleSheet {
	static ATStyleSheet *_styleSheet;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_styleSheet = [[ATStyleSheet alloc] init];
	});
	return _styleSheet;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		_fontFamily = [[self class] defaultFontFamilyName];
		_primaryColor = [UIColor blackColor];
		_secondaryColor = [UIColor colorWithRed:142.0/255.0 green:142.0/255.0 blue:147.0/255.0 alpha:1.0];
		_failureColor = [UIColor colorWithRed:218.0/255.0 green:53.0/255.0 blue:71.0/255.0 alpha:1.0];
		_backgroundColor = [UIColor whiteColor];
		_separatorColor = [UIColor colorWithRed:199.0/255.0 green:200.0/255.0 blue:204.0/255.0 alpha:1.0];

		_lightFaceAttribute = @"Light";
		_regularFaceAttribute = @"Regular";
		_mediumFaceAttribute = @"Medium";
		_boldFaceAttribute = @"Bold";

		_sizeAdjustment = 1.0;

		_fontDescriptorOverrides = [NSMutableDictionary dictionary];
		_colorOverrides = [NSMutableDictionary dictionary];
	}
	return self;
}

- (void)setFontDescriptor:(UIFontDescriptor *)fontDescriptor forStyle:(NSString *)textStyle {
	[self.fontDescriptorOverrides setObject:fontDescriptor forKey:textStyle];
}

- (UIFontDescriptor *)fontDescriptorForStyle:(NSString *)textStyle {
	if (self.fontDescriptorOverrides[textStyle]) {
		return self.fontDescriptorOverrides[textStyle];
	}

	NSString *face = self.regularFaceAttribute;
	NSNumber *size = @(17.0);

	if ([[[self class] UIKitTextStyles] containsObject:textStyle]) {
		// fontDescriptorWithFamily doesn't properly override the font family for the system font :(
		UIFontDescriptor *modelFontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:textStyle];
		face = [self faceAttributeForFontDescriptor:modelFontDescriptor];
		size = [modelFontDescriptor objectForKey:UIFontDescriptorSizeAttribute];
	} else {
		face = [self faceAttributeForWeight:[[self class] weightForTextStyle:textStyle]];
		size = [[self class] sizeForTextStyle:textStyle];
	}

	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	attributes[UIFontDescriptorFamilyAttribute] = self.fontFamily;
	attributes[UIFontDescriptorSizeAttribute] = @(size.doubleValue * self.sizeAdjustment);

	if (face) {
		attributes[UIFontDescriptorFaceAttribute] = face;
	}

	return  [UIFontDescriptor fontDescriptorWithFontAttributes:attributes];;
}

- (NSString * _Nullable)faceAttributeForFontDescriptor:(UIFontDescriptor *)fontDescriptor {
	NSString *faceAttribute = [fontDescriptor objectForKey:UIFontDescriptorFaceAttribute];

	if ([faceAttribute isEqualToString:@"Light"]) {
		return self.lightFaceAttribute;
	} else if ([faceAttribute isEqualToString:@"Medium"]) {
		return self.mediumFaceAttribute;
	} else if ([faceAttribute isEqualToString:@"Bold"]) {
		return self.boldFaceAttribute;
	} else {
		return self.regularFaceAttribute;
	}
}

- (NSString *)faceAttributeForWeight:(NSInteger)weight {
	switch (weight) {
		case 300:
			return self.lightFaceAttribute;
		case 400:
		default:
			return self.regularFaceAttribute;
		case 500:
			return self.mediumFaceAttribute;
		case 700:
			return self.boldFaceAttribute;
	}
}

- (UIFont *)fontForStyle:(NSString *)textStyle {
	return [UIFont fontWithDescriptor:[self fontDescriptorForStyle:textStyle] size:0.0];
}

- (void)setColor:(UIColor *)color forStyle:(NSString *)style {
	[self.colorOverrides setObject:color forKey:style];
}

- (UIColor *)colorForStyle:(NSString *)style {
	UIColor *result = self.colorOverrides[style];

	if (result) {
		return result;
	}

	if ([style isEqualToString:ApptentiveColorFailure]) {
		return self.failureColor;
	} else if ([style isEqualToString:ApptentiveColorSeparator]) {
		return self.separatorColor;
	} else if ([style isEqualToString:ApptentiveColorHeaderBackground] || [style isEqualToString:ApptentiveColorBackground]) {
		return self.backgroundColor;
	} else if ([style isEqualToString:ApptentiveColorFooterBackground]) {
		return [self.backgroundColor colorWithAlphaComponent:0.5];
	} else if ([@[ApptentiveTextStyleHeaderMessage, ApptentiveTextStyleMessageDate, ApptentiveTextStyleMessageStatus, ApptentiveTextStyleMessageCenterStatus, ApptentiveTextStyleSurveyInstructions] containsObject:style]) {
		return self.secondaryColor;
	} else {
		return self.primaryColor;
	}

	return result;
}

@end

