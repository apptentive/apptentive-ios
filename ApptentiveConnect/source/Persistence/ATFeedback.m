//
//  ATFeedback.m
//  DemoApp
//
//  Created by Andrew Wooster on 3/16/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATFeedback.h"
#import "ATBackend.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

#define kFeedbackCodingVersion 2

@interface ATFeedback (Private)
- (ATFeedbackType)feedbackTypeFromString:(NSString *)feedbackString;
- (NSString *)stringForFeedbackType:(ATFeedbackType)feedbackType;
- (NSString *)formattedDate:(NSDate *)aDate;
@end

@implementation ATFeedback
@synthesize type, text, name, email, phone, screenshot, uuid, model, os_version, carrier, date, screenshotSwitchEnabled;
- (id)init {
    if ((self = [super init])) {
        self.type = ATFeedbackTypeFeedback;
        self.uuid = [[ATBackend sharedBackend] deviceUUID];
        self.model = [[UIDevice currentDevice] model];
        self.os_version = [NSString stringWithFormat:@"%@ %@", [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion]];
        self.date = [NSDate date];
        
        if ([CTTelephonyNetworkInfo class]) {
            CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
            CTCarrier *c = [netInfo subscriberCellularProvider];
            if (c.carrierName) {
                self.carrier = c.carrierName;
            }
            [netInfo release];
        }
    }
    return self;
}

- (void)dealloc {
    self.text = nil;
    self.name = nil;
    self.email = nil;
    self.phone = nil;
    self.screenshot = nil;
    self.uuid = nil;
    self.model = nil;
    self.os_version = nil;
    self.carrier = nil;
    self.date = nil;
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)coder {
    if ((self = [self init])) {
        int version = [coder decodeIntForKey:@"version"];
        if (version == 1) {
            self.type = [self feedbackTypeFromString:[coder decodeObjectForKey:@"type"]];
            self.text = [coder decodeObjectForKey:@"text"];
            self.name = [coder decodeObjectForKey:@"name"];
            self.email = [coder decodeObjectForKey:@"email"];
            self.phone = [coder decodeObjectForKey:@"phone"];
            if ([coder containsValueForKey:@"screenshot"]) {
                NSData *data = [coder decodeObjectForKey:@"screenshot"];
                self.screenshot = [UIImage imageWithData:data];
            }
            self.uuid = [coder decodeObjectForKey:@"uuid"];
            self.model = [coder decodeObjectForKey:@"model"];
            self.os_version = [coder decodeObjectForKey:@"os_version"];
            self.carrier = [coder decodeObjectForKey:@"carrier"];
        } else if (version == kFeedbackCodingVersion) {
            self.type = [coder decodeIntForKey:@"type"];
            self.text = [coder decodeObjectForKey:@"text"];
            self.name = [coder decodeObjectForKey:@"name"];
            self.email = [coder decodeObjectForKey:@"email"];
            self.phone = [coder decodeObjectForKey:@"phone"];
            if ([coder containsValueForKey:@"screenshot"]) {
                NSData *data = [coder decodeObjectForKey:@"screenshot"];
                self.screenshot = [UIImage imageWithData:data];
            }
            self.uuid = [coder decodeObjectForKey:@"uuid"];
            self.model = [coder decodeObjectForKey:@"model"];
            self.os_version = [coder decodeObjectForKey:@"os_version"];
            self.carrier = [coder decodeObjectForKey:@"carrier"];
            if ([coder containsValueForKey:@"date"]) {
                self.date = [coder decodeObjectForKey:@"date"];
            }
        } else {
            [self release];
            return nil;
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt:kFeedbackCodingVersion forKey:@"version"];
	[coder encodeInt:self.type forKey:@"type"];
    [coder encodeObject:self.text forKey:@"text"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.email forKey:@"email"];
    [coder encodeObject:self.phone forKey:@"phone"];
    if (self.screenshot) {
        [coder encodeObject:UIImagePNGRepresentation(self.screenshot) forKey:@"screenshot"];
    }
    [coder encodeObject:self.uuid forKey:@"uuid"];
    [coder encodeObject:self.model forKey:@"model"];
    [coder encodeObject:self.os_version forKey:@"os_version"];
    [coder encodeObject:self.carrier forKey:@"carrier"];
    [coder encodeObject:self.date forKey:@"date"];
}

- (NSDictionary *)dictionary {
    return [NSDictionary dictionaryWithObjectsAndKeys:self.text, @"text", self.name, @"name", self.email, @"email", self.phone, @"phone", self.screenshot, @"screenshot", nil];
}

- (NSDictionary *)apiDictionary {
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    if (self.uuid) [d setObject:self.uuid forKey:@"feedback[uuid]"];
    if (self.name) [d setObject:self.name forKey:@"feedback[name]"];
    if (self.email) [d setObject:self.email forKey:@"feedback[email_address]"];
    if (self.phone) [d setObject:self.phone forKey:@"feedback[phone_number]"];
    if (self.model) [d setObject:self.model forKey:@"feedback[model]"];
    if (self.os_version) [d setObject:self.os_version forKey:@"feedback[os_version]"];
    if (self.carrier) [d setObject:self.carrier forKey:@"feedback[carrier]"];
    if (self.text) [d setObject:self.text forKey:@"feedback[feedback]"];
    [d setObject:[self stringForFeedbackType:self.type] forKey:@"feedback[feedback_type]"];
    
    [d setObject:[self formattedDate:self.date] forKey:@"feedback[feedback_date]"];
    
    return d;
}
@end


@implementation ATFeedback (Private)
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

- (NSString *)formattedDate:(NSDate *)aDate {
    time_t time = [aDate timeIntervalSince1970];
    struct tm timeStruct;
    localtime_r(&time, &timeStruct);
    char buffer[200];
    strftime(buffer, 200, "%m/%d/%Y %I:%M%p%z", &timeStruct);
    NSString *result = [NSString stringWithCString:buffer encoding:NSASCIIStringEncoding];
    return result;
}
@end
