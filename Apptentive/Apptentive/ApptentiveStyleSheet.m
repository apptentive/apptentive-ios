//
//  ApptentiveStyleSheet.m
//  Apptentive
//
//  Created by Frank Schmitt on 3/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveStyleSheet.h"
#import "Apptentive.h"

NS_ASSUME_NONNULL_BEGIN

ApptentiveStyleIdentifier ApptentiveTextStyleBody = @"com.apptentive.body";
ApptentiveStyleIdentifier ApptentiveTextStyleHeaderTitle = @"com.apptentive.header.title";
ApptentiveStyleIdentifier ApptentiveTextStyleHeaderMessage = @"com.apptentive.header.message";
ApptentiveStyleIdentifier ApptentiveTextStyleMessageDate = @"com.apptentive.message.date";
ApptentiveStyleIdentifier ApptentiveTextStyleMessageSender = @"com.apptentive.message.sender";
ApptentiveStyleIdentifier ApptentiveTextStyleMessageStatus = @"com.apptentive.message.status";
ApptentiveStyleIdentifier ApptentiveTextStyleMessageCenterStatus = @"com.apptentive.messageCenter.status";
ApptentiveStyleIdentifier ApptentiveTextStyleSurveyInstructions = @"com.apptentive.survey.question.instructions";
ApptentiveStyleIdentifier ApptentiveTextStyleDoneButton = @"com.apptentive.doneButton";
ApptentiveStyleIdentifier ApptentiveTextStyleButton = @"com.apptentive.button";
ApptentiveStyleIdentifier ApptentiveTextStyleSubmitButton = @"com.apptentive.submitButton";
ApptentiveStyleIdentifier ApptentiveTextStyleTextInput = @"com.apptentive.textInput";

ApptentiveStyleIdentifier ApptentiveColorHeaderBackground = @"com.apptentive.color.header.background";
ApptentiveStyleIdentifier ApptentiveColorFooterBackground = @"com.apptentive.color.footer.background";
ApptentiveStyleIdentifier ApptentiveColorFailure = @"com.apptentive.color.failure";
ApptentiveStyleIdentifier ApptentiveColorSeparator = @"com.apptentive.color.separator";
ApptentiveStyleIdentifier ApptentiveColorBackground = @"com.apptentive.color.cellBackground";
ApptentiveStyleIdentifier ApptentiveColorCollectionBackground = @"com.apptentive.color.collectionBackground";
ApptentiveStyleIdentifier ApptentiveColorTextInputBackground = @"com.apptentive.color.textInputBackground";
ApptentiveStyleIdentifier ApptentiveColorTextInputPlaceholder = @"com.apptentive.color.textInputPlaceholder";
ApptentiveStyleIdentifier ApptentiveColorMessageBackground = @"com.apptentive.color.messageBackground";
ApptentiveStyleIdentifier ApptentiveColorReplyBackground = @"com.apptentive.color.replyBackground";
ApptentiveStyleIdentifier ApptentiveColorContextBackground = @"com.apptentive.color.contextBackground";

NSString *const FontFamilyKey = @"FontFamily";
NSString *const LightFaceAttributeKey = @"LightFaceAttribute";
NSString *const RegularFaceAttributeKey = @"RegularFaceAttribute";
NSString *const MediumFaceAttributeKey = @"MediumFaceAttribute";
NSString *const BoldFaceAttributeKey = @"BoldFaceAttribute";
NSString *const PrimaryColorKey = @"PrimaryColor";
NSString *const SecondaryColorKey = @"SecondaryColor";
NSString *const FailureColorKey = @"FailureColor";
NSString *const BackgroundColorKey = @"BackgroundColor";
NSString *const SeparatorColorKey = @"SeparatorColor";
NSString *const CollectionBackgroundColorKey = @"CollectionBackgroundColor";
NSString *const PlaceholderColorKey = @"PlaceholderColor";
NSString *const SizeAdjustmentKey = @"SizeAdjustment";
NSString *const ColorOverridesKey = @"ColorOverrides";
NSString *const FontOverridesKey = @"FontOverrides";


@interface ApptentiveStyleSheet ()

@property (strong, nonatomic) NSMutableDictionary *fontDescriptorOverrides;
@property (strong, nonatomic) NSMutableDictionary *colorOverrides;

@property (strong, nonatomic) NSMutableDictionary *fontTable;
@property (nonatomic) BOOL didInheritColors;

+ (NSArray *)apptentiveTextStyles;
+ (NSArray *)apptentiveColorStyles;

+ (NSNumber *)sizeForTextStyle:(ApptentiveStyleIdentifier)textStyle;
+ (NSInteger)weightForTextStyle:(ApptentiveStyleIdentifier)textStyle;

+ (NSString *)defaultFontFamilyName;
- (UIFontDescriptor *)fontDescriptorForStyle:(ApptentiveStyleIdentifier)textStyle;
- (NSString *)faceAttributeForWeight:(NSInteger)weight;

@end


@implementation ApptentiveStyleSheet

// TODO: Adjust for content size category?
+ (NSInteger)weightForTextStyle:(ApptentiveStyleIdentifier)textStyle {
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
		  ApptentiveTextStyleSubmitButton: @500,
		  ApptentiveTextStyleTextInput: @400
	  };
	});
	return faceForStyle[textStyle].integerValue;
}

+ (NSNumber *)sizeForTextStyle:(ApptentiveStyleIdentifier)textStyle {
	static NSDictionary<NSString *, NSDictionary<NSString *, NSNumber *> *> *sizeForCategoryForStyle;
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
		  ApptentiveTextStyleHeaderMessage: @{
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
		  },
		  ApptentiveTextStyleTextInput: @{
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
	  };
	});
	return sizeForCategoryForStyle[textStyle][[UIApplication sharedApplication].preferredContentSizeCategory];
}

+ (NSArray *)UIKitTextStyles {
	static NSArray *_UIKitTextStyles;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
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
	static ApptentiveStyleSheet *_styleSheet;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
	  _styleSheet = [[ApptentiveStyleSheet alloc] init];
	});
	return _styleSheet;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		_fontFamily = [[self class] defaultFontFamilyName];
		_lightFaceAttribute = @"Light";
		_regularFaceAttribute = @"Regular";
		_mediumFaceAttribute = @"Medium";
		_boldFaceAttribute = @"Bold";

		_sizeAdjustment = 1.0;

		_secondaryColor = [UIColor colorWithRed:118.0 / 255.0 green:118.0 / 255.0 blue:122.0 / 255.0 alpha:1.0];
		_failureColor = [UIColor colorWithRed:218.0 / 255.0 green:53.0 / 255.0 blue:71.0 / 255.0 alpha:1.0];

		_fontDescriptorOverrides = [NSMutableDictionary dictionary];
		_colorOverrides = [NSMutableDictionary dictionary];
	}
	return self;
}

- (nullable instancetype)initWithContentsOfURL:(NSURL *)stylePropertyListURL {
	self = [self init];

	if (self) {
		NSDictionary *propertyList = [NSDictionary dictionaryWithContentsOfURL:stylePropertyListURL];

		if (propertyList == nil) {
			ApptentiveLogError(@"Style property list at URL %@ was unable to be loaded.", stylePropertyListURL);
			return nil;
		}

		_fontFamily = propertyList[FontFamilyKey] ?: _fontFamily;
		_lightFaceAttribute = propertyList[LightFaceAttributeKey] ?: _lightFaceAttribute;
		_regularFaceAttribute = propertyList[RegularFaceAttributeKey] ?: _regularFaceAttribute;
		_mediumFaceAttribute = propertyList[MediumFaceAttributeKey] ?: _mediumFaceAttribute;
		_boldFaceAttribute = propertyList[BoldFaceAttributeKey] ?: _boldFaceAttribute;

		_sizeAdjustment = propertyList[SizeAdjustmentKey] ? [propertyList[SizeAdjustmentKey] doubleValue] : _sizeAdjustment;

		_primaryColor = [[self class] colorFromHexString:propertyList[PrimaryColorKey]] ?: _primaryColor;
		_secondaryColor = [[self class] colorFromHexString:propertyList[SecondaryColorKey]] ?: _secondaryColor;
		_failureColor = [[self class] colorFromHexString:propertyList[FailureColorKey]] ?: _failureColor;
		_backgroundColor = [[self class] colorFromHexString:propertyList[BackgroundColorKey]] ?: _backgroundColor;
		_separatorColor = [[self class] colorFromHexString:propertyList[SeparatorColorKey]] ?: _separatorColor;
		_collectionBackgroundColor = [[self class] colorFromHexString:propertyList[CollectionBackgroundColorKey]] ?: _collectionBackgroundColor;
		_placeholderColor = [[self class] colorFromHexString:propertyList[PlaceholderColorKey]] ?: _placeholderColor;

		NSDictionary *colorOverrides = propertyList[ColorOverridesKey];

		if ([colorOverrides isKindOfClass:[NSDictionary class]]) {
			for (ApptentiveStyleIdentifier style in colorOverrides) {
				UIColor *color = [[self class] colorFromHexString:colorOverrides[style]];
				if (color) {
					[self setColor:color forStyle:style];
				} else {
					ApptentiveLogError(@"Property list color override for style %@ is not a valid hex string (e.g. #A1B2C3).", style);
				}
			}
		} else {
			ApptentiveLogError(@"Property list color overrides is not a valid dictionary.");
		}

		NSDictionary *fontOverrides = propertyList[FontOverridesKey];

		if ([fontOverrides isKindOfClass:[NSDictionary class]]) {
			for (ApptentiveStyleIdentifier style in fontOverrides) {
				NSString *fontName = fontOverrides[style][@"font"];
				NSNumber *fontSize = fontOverrides[style][@"size"];

				if (![fontName isKindOfClass:[NSString class]] || ![fontSize isKindOfClass:[NSNumber class]]) {
					ApptentiveLogError(@"Property list font override for style %@ has missing or invalid `font` (string) or `size` (number) value.");
					continue;
				}

				UIFontDescriptor *fontDescriptor = [UIFontDescriptor fontDescriptorWithName:fontName size:fontSize.doubleValue];

				if (fontDescriptor != nil) {
					[self setFontDescriptor:fontDescriptor forStyle:style];
				} else {
					ApptentiveLogError(@"Unable to create font descriptor with name %@ and size %f", fontName, fontSize.doubleValue);
				}
			}
		} else {
			ApptentiveLogError(@"Property list font overrides is not a valid dictionary.");
		}
	}

	return self;
}

+ (nullable UIColor *)colorFromHexString:(NSString *)hexString {
	if (hexString == nil) {
		return nil;
	}

	unsigned rgbValue = 0;
	NSScanner *scanner = [NSScanner scannerWithString:hexString];
	if ([scanner scanString:@"#" intoString:NULL] && [scanner scanHexInt:&rgbValue]) {
		return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16) / 255.0 green:((rgbValue & 0xFF00) >> 8) / 255.0 blue:(rgbValue & 0xFF) / 255.0 alpha:1.0];
	} else {
		return nil;
	}
}

- (UIColor *)appearanceColorForClass:(Class)klass property:(SEL)propertySelector default:(UIColor *)defaultColor {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	UIColor *whenContainedInColor = [[klass appearanceWhenContainedIn:[ApptentiveNavigationController class], nil] performSelector:propertySelector];
	if (whenContainedInColor) {
		return whenContainedInColor;
	}

	whenContainedInColor = [[klass appearance] performSelector:propertySelector];
	if (whenContainedInColor) {
		return whenContainedInColor;
	}
#pragma clang diagnostic pop

	return defaultColor;
}

- (void)inheritDefaultColors {
	_primaryColor = self.primaryColor ?: [self appearanceColorForClass:[UILabel class] property:@selector(textColor) default:[UIColor blackColor]];
	_separatorColor = self.separatorColor ?: [self appearanceColorForClass:[UITableView class] property:@selector(separatorColor) default:[UIColor colorWithRed:199.0 / 255.0 green:200.0 / 255.0 blue:204.0 / 255.0 alpha:1.0]];
	_backgroundColor = self.backgroundColor ?: [self appearanceColorForClass:[UITableViewCell class] property:@selector(backgroundColor) default:[UIColor whiteColor]];
	_collectionBackgroundColor = self.collectionBackgroundColor ?: [self appearanceColorForClass:[UITableView class] property:@selector(backgroundColor) default:[UIColor groupTableViewBackgroundColor]];
	_placeholderColor = self.placeholderColor ?: [UIColor colorWithRed:0 green:0 blue:25.0 / 255.0 alpha:56.0 / 255.0];
}

- (void)setFontDescriptor:(UIFontDescriptor *)fontDescriptor forStyle:(ApptentiveStyleIdentifier)textStyle {
	ApptentiveDictionarySetKeyValue(self.fontDescriptorOverrides, textStyle, fontDescriptor);
}

- (UIFontDescriptor *)fontDescriptorForStyle:(ApptentiveStyleIdentifier)textStyle {
	if (self.fontDescriptorOverrides[textStyle]) {
		return self.fontDescriptorOverrides[textStyle];
	}

	NSString *face;
	NSNumber *size;

	if ([textStyle isEqualToString:UIFontTextStyleBody] || [textStyle isEqualToString:ApptentiveTextStyleBody]) {
		// fontDescriptorWithFamily doesn't properly override the font family for the system font :(
		UIFontDescriptor *modelFontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
		face = [self faceAttributeForFontDescriptor:modelFontDescriptor];
		size = [modelFontDescriptor objectForKey:UIFontDescriptorSizeAttribute];
	} else {
		face = [self faceAttributeForWeight:[[self class] weightForTextStyle:textStyle]];
		size = [[self class] sizeForTextStyle:textStyle];
	}

	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	attributes[UIFontDescriptorFamilyAttribute] = self.fontFamily;
	attributes[UIFontDescriptorSizeAttribute] = @(size.doubleValue * self.sizeAdjustment);

	if (face.length > 0) {
		attributes[UIFontDescriptorFaceAttribute] = face;
	}

	return [UIFontDescriptor fontDescriptorWithFontAttributes:attributes];
	;
}

- (NSString *_Nullable)faceAttributeForFontDescriptor:(UIFontDescriptor *)fontDescriptor {
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

- (UIFont *)fontForStyle:(ApptentiveStyleIdentifier)textStyle {
	return [UIFont fontWithDescriptor:[self fontDescriptorForStyle:textStyle] size:0.0];
}

- (void)setColor:(UIColor *)color forStyle:(NSString *)style {
	ApptentiveDictionarySetKeyValue(self.colorOverrides, style, color);
}

- (UIColor *)interpolateAtPoint:(CGFloat)interpolation between:(UIColor *)color1 and:(UIColor *)color2 {
	CGFloat red1, green1, blue1, alpha1;
	[color1 getRed:&red1 green:&green1 blue:&blue1 alpha:&alpha1];

	CGFloat red2, green2, blue2, alpha2;
	[color2 getRed:&red2 green:&green2 blue:&blue2 alpha:&alpha2];

	CGFloat inverse = 1.0 - interpolation;

	return [UIColor colorWithRed:red1 * interpolation + red2 * inverse green:green1 * interpolation + green2 * inverse blue:blue1 * interpolation + blue2 * inverse alpha:alpha1 * interpolation + alpha2 * inverse];
}

- (UIColor *)colorForStyle:(NSString *)style {
	if (!self.didInheritColors) {
		[self inheritDefaultColors];
		self.didInheritColors = YES;
	}

	UIColor *result = self.colorOverrides[style];

	if (result) {
		return result;
	}

	if ([style isEqualToString:ApptentiveColorFailure]) {
		result = self.failureColor;
	} else if ([style isEqualToString:ApptentiveColorSeparator]) {
		result = self.separatorColor;
	} else if ([style isEqualToString:ApptentiveColorCollectionBackground]) {
		result = self.collectionBackgroundColor;
	} else if ([@[ApptentiveColorHeaderBackground, ApptentiveColorBackground, ApptentiveColorTextInputBackground, ApptentiveColorMessageBackground] containsObject:style]) {
		result = self.backgroundColor;
	} else if ([style isEqualToString:ApptentiveColorFooterBackground]) {
		result = [self.backgroundColor colorWithAlphaComponent:0.5];
	} else if ([style isEqualToString:ApptentiveColorReplyBackground] || [style isEqualToString:ApptentiveColorContextBackground]) {
		result = [self interpolateAtPoint:0.968 between:self.backgroundColor and:self.primaryColor];
	} else if ([style isEqualToString:ApptentiveColorTextInputPlaceholder]) {
		result = self.placeholderColor;
	} else if ([@[ApptentiveTextStyleHeaderMessage, ApptentiveTextStyleMessageDate, ApptentiveTextStyleMessageStatus, ApptentiveTextStyleMessageCenterStatus, ApptentiveTextStyleSurveyInstructions] containsObject:style]) {
		result = self.secondaryColor;
	} else {
		result = self.primaryColor;
	}

	ApptentiveAssertNotNil(result, @"Can't resolve color for style: %@", style);
	return result ?: [UIColor magentaColor];
}

@end

NS_ASSUME_NONNULL_END
