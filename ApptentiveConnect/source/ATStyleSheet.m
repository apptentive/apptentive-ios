//
//  ATStyleSheet.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 3/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATStyleSheet.h"

NSString * const ApptentiveStyleSheetDidUpdateNotification = @"com.apptentive.stylesheetDidUpdate";

NSString * const ApptentiveColorKey = @"com.apptentive.textColor";

NSString *const ApptentiveTextStyleMessageDate = @"com.apptentive.messageDate";

@interface ATStyleSheet ()

@property (strong, nonatomic) NSMutableDictionary *fontTable;

@end

@implementation ATStyleSheet

+ (instancetype)styleSheet {
	static ATStyleSheet *_styleSheet;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_styleSheet = [[ATStyleSheet alloc] init];
	});
	return _styleSheet;
}

+ (NSString *)defaultFontFamilyName {
	return [UIFont systemFontOfSize:[UIFont systemFontSize]].familyName;
}

+ (NSDictionary <NSString *, UIFont *> *)defaultFonts {
	return @{
			 UIFontTextStyleBody: [UIFont systemFontOfSize:17.0],
			 UIFontTextStyleCallout: [UIFont systemFontOfSize:16.0],
			 UIFontTextStyleCaption1: [UIFont systemFontOfSize:12.0],
			 UIFontTextStyleCaption2: [UIFont systemFontOfSize:11.0],
			 UIFontTextStyleFootnote: [UIFont systemFontOfSize:13.0],
			 UIFontTextStyleHeadline: [UIFont boldSystemFontOfSize:17.0], // TODO: semibold where available
			 UIFontTextStyleSubheadline: [UIFont systemFontOfSize:15.0],
			 UIFontTextStyleTitle1: [UIFont systemFontOfSize:28.0], // TODO: light where available
			 UIFontTextStyleTitle2: [UIFont systemFontOfSize:22.0],
			 UIFontTextStyleTitle3: [UIFont systemFontOfSize:16.0]
			 };
}

- (instancetype)init {
	self = [super init];
	if (self) {
		_fontFamily = [[self class] defaultFontFamilyName];
		_useDynamicType = YES;
		_sizeAdjustment = 1.0;

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recomputeStyles) name:UIContentSizeCategoryDidChangeNotification object:nil];

		[self recomputeStyles];
	}
	return self;
}

- (void)setFontFamily:(NSString *)fontFamily {
	_fontFamily = fontFamily;

	[self recomputeStyles];
}

- (void)setUseDynamicType:(BOOL)useDynamicType {
	_useDynamicType = useDynamicType;

	if (useDynamicType) {
		_fontTable = [[NSMutableDictionary alloc] init];
	} else {
		_fontTable = [[[self class] defaultFonts] mutableCopy];
	}

	[self recomputeStyles];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)recomputeStyles {
	[[NSNotificationCenter defaultCenter] postNotificationName:ApptentiveStyleSheetDidUpdateNotification object:self];
}

- (UIFontDescriptor *)preferredFontDescriptorWithTextStyle:(NSString *)textStyle {
	UIFontDescriptor *result;

	if (self.useDynamicType) {
		if ([self.fontFamily isEqualToString:[[self class] defaultFontFamilyName]]) {
			result = [UIFontDescriptor preferredFontDescriptorWithTextStyle:textStyle];
		} else {
			UIFont *font = [UIFont preferredFontForTextStyle:textStyle];
			result = [UIFontDescriptor fontDescriptorWithName:self.fontFamily size:font.pointSize * self.sizeAdjustment];
		}
	} else {
		UIFont *defaultFont = [[[self class] defaultFonts] objectForKey:textStyle];
		if ([self.fontFamily isEqualToString:[[self class] defaultFontFamilyName]]) {
			result = [UIFontDescriptor fontDescriptorWithName:defaultFont.fontName size:defaultFont.pointSize * self.sizeAdjustment];
		} else {
			result = [UIFontDescriptor fontDescriptorWithName:self.fontFamily size:defaultFont.pointSize * self.sizeAdjustment];
			result = [result fontDescriptorByAddingAttributes: @{ UIFontDescriptorFaceAttribute: [defaultFont.fontDescriptor objectForKey:UIFontDescriptorFaceAttribute] }];
		}
	}

	NSDictionary *attributes = @{
								 ApptentiveColorKey: [UIColor blackColor],
								  };

	result = [result fontDescriptorByAddingAttributes:attributes];

	return result;
}

@end

