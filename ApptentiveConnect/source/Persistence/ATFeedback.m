//
//  ATFeedback.m
//  DemoApp
//
//  Created by Andrew Wooster on 3/16/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATFeedback.h"
#import "ATConnect.h"
#import "ATBackend.h"
#import "ATUtilities.h"
#import "ATWebClient.h"

#if TARGET_OS_IPHONE
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#endif


#define kFeedbackCodingVersion 2

@interface ATFeedback (Private)
- (void)setup;
- (ATFeedbackType)feedbackTypeFromString:(NSString *)feedbackString;
- (NSString *)stringForFeedbackType:(ATFeedbackType)feedbackType;
- (NSString *)stringForSource:(ATFeedbackSource)aSource;
@end

@implementation ATFeedback
@synthesize type, text, name, email, phone, source, screenshot, imageSource;
- (id)init {
	if ((self = [super init])) {
		[self setup];
	}
	return self;
}

- (void)dealloc {
	[extraData release], extraData = nil;
	[text release], text = nil;
	[name release], name = nil;
	[email release], email = nil;
	[phone release], phone = nil;
	[screenshot release], screenshot = nil;
	[super dealloc];
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super initWithCoder:coder])) {
		[self setup];
		int version = [coder decodeIntForKey:@"version"];
		if ([coder containsValueForKey:@"source"]) {
			self.source = [coder decodeIntForKey:@"source"];
		} else {
			self.source = ATFeedbackSourceUnknown;
		}
		if (version == 1) {
			self.type = [self feedbackTypeFromString:[coder decodeObjectForKey:@"type"]];
			self.text = [coder decodeObjectForKey:@"text"];
			self.name = [coder decodeObjectForKey:@"name"];
			self.email = [coder decodeObjectForKey:@"email"];
			self.phone = [coder decodeObjectForKey:@"phone"];
			if ([coder containsValueForKey:@"screenshot"]) {
				NSData *data = [coder decodeObjectForKey:@"screenshot"];
#if TARGET_OS_IPHONE
				self.screenshot = [UIImage imageWithData:data];
#elif TARGET_OS_MAC
				self.screenshot = [[[NSImage alloc] initWithData:data] autorelease];
#endif
			}
		} else if (version == kFeedbackCodingVersion) {
			self.type = [coder decodeIntForKey:@"type"];
			self.text = [coder decodeObjectForKey:@"text"];
			self.name = [coder decodeObjectForKey:@"name"];
			self.email = [coder decodeObjectForKey:@"email"];
			self.phone = [coder decodeObjectForKey:@"phone"];
			if ([coder containsValueForKey:@"screenshot"]) {
				NSData *data = [coder decodeObjectForKey:@"screenshot"];
#if TARGET_OS_IPHONE
				self.screenshot = [UIImage imageWithData:data];
#elif TARGET_OS_MAC
				self.screenshot = [[[NSImage alloc] initWithData:data] autorelease];
#endif
			}
			NSDictionary *oldExtraData = [coder decodeObjectForKey:@"extraData"];
			if (oldExtraData != nil) {
				[extraData addEntriesFromDictionary:oldExtraData];
			}
		} else {
			[self release];
			return nil;
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];
	[coder encodeInt:kFeedbackCodingVersion forKey:@"version"];
	[coder encodeInt:self.type forKey:@"type"];
	[coder encodeObject:self.text forKey:@"text"];
	[coder encodeObject:self.name forKey:@"name"];
	[coder encodeObject:self.email forKey:@"email"];
	[coder encodeObject:self.phone forKey:@"phone"];
	if (self.source != ATFeedbackSourceUnknown) {
		[coder encodeInt:self.source forKey:@"source"];
	}
	[coder encodeObject:extraData forKey:@"extraData"];
	if (self.screenshot) {
#if TARGET_OS_IPHONE
		[coder encodeObject:UIImagePNGRepresentation(self.screenshot) forKey:@"screenshot"];
#elif TARGET_OS_MAC
		NSData *data = [ATUtilities pngRepresentationOfImage:self.screenshot];
		[coder encodeObject:data forKey:@"screenshot"];
#endif
	}
}

- (NSDictionary *)dictionary {
	return [NSDictionary dictionaryWithObjectsAndKeys:self.text, @"text", self.name, @"name", self.email, @"email", self.phone, @"phone", self.screenshot, @"screenshot", nil];
}

- (NSDictionary *)apiDictionary {
	NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:[super apiDictionary]];
	if (self.name) [d setObject:self.name forKey:@"record[user][name]"];
	if (self.email) [d setObject:self.email forKey:@"record[user][email]"];
	if (self.phone) [d setObject:self.phone forKey:@"record[user][phone_number]"];
	if (self.text) [d setObject:self.text forKey:@"record[feedback][feedback]"];
	[d setObject:[self stringForFeedbackType:self.type] forKey:@"record[feedback][type]"];
	NSString *sourceString = [self stringForSource:self.source];
	if (sourceString != nil) {
		[d setObject:sourceString forKey:@"record[feedback][source]"];
	}
	if (extraData && [extraData count] > 0) {
		for (NSString *key in extraData) {
			NSString *fullKey = [NSString stringWithFormat:@"record[data][%@]", key];
			[d setObject:[extraData objectForKey:key] forKey:fullKey];
		}
	}
	return d;
}


- (void)addExtraDataFromDictionary:(NSDictionary *)dictionary {
	[extraData addEntriesFromDictionary:dictionary];
}

- (ATAPIRequest *)requestForSendingRecord {
	return [[ATWebClient sharedClient] requestForPostingFeedback:self];
}
@end


@implementation ATFeedback (Private)
- (void)setup {
	extraData = [[NSMutableDictionary alloc] init];
	self.type = ATFeedbackTypeFeedback;
}

- (ATFeedbackType)feedbackTypeFromString:(NSString *)feedbackString {
	if ([feedbackString isEqualToString:@"feedback"] || [feedbackString isEqualToString:@"suggestion"]) {
		return ATFeedbackTypeFeedback;
	} else if ([feedbackString isEqualToString:@"question"]) {
		return ATFeedbackTypeQuestion;
	} else if ([feedbackString isEqualToString:@"praise"]) {
		return ATFeedbackTypePraise;
	} else if ([feedbackString isEqualToString:@"bug"]) {
		return ATFeedbackTypeBug;
	}
	return ATFeedbackTypeFeedback;
}

- (NSString *)stringForFeedbackType:(ATFeedbackType)feedbackType {
	NSString *result = nil;
	switch (feedbackType) {
		case ATFeedbackTypeBug:
			result = @"bug";
			break;
		case ATFeedbackTypePraise:
			result = @"praise";
			break;
		case ATFeedbackTypeQuestion:
			result = @"question";
			break;
		case ATFeedbackTypeFeedback:
		default:
			result = @"feedback";
			break;
	}
	return result;
}

- (NSString *)stringForSource:(ATFeedbackSource)aSource {
	NSString *result = nil;
	switch (aSource) {
		case ATFeedbackSourceEnjoymentDialog:
			result = @"enjoyment_dialog";
			break;
		default:
			break;
	}
	return result;
}
@end
