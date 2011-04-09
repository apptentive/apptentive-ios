//
//  PSWebClient.m
//  AmidstApp
//
//  Created by Andrew Wooster on 7/28/09.
//  Copyright 2009 Planetary Scale LLC. All rights reserved.
//

#import "ATWebClient.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import "ATBackend.h"
#import "ATConnect.h"
#import "ATConnectionManager.h"
#import "ATFeedback.h"
#import "ATURLConnection.h"
#import "ATUtilities.h"

#ifdef SUPPORT_JSON
#import "JSON.h"
#endif

#import "NSData+ATBase64.h"

#define kCommonChannelName (@"ATWebClient")
#define kUserAgentFormat (@"ApptentiveConnect/%@ (%@)")

@interface ATWebClient (Private)
- (NSString *)userAgentString;
@end

@implementation ATWebClient
@synthesize returnType;
@synthesize failed;
@synthesize errorTitle;
@synthesize errorMessage;
@synthesize channelName;
@synthesize timeoutInterval;

- (id)initWithTarget:(id)aDelegate action:(SEL)anAction {
	if ((self = [super init])) {
		returnType = ATWebClientReturnTypeString;
		delegate = aDelegate;
		action = anAction;
		channelName = kCommonChannelName;
		timeoutInterval = 30.0;
	}
	return self;
}

- (void)showAlert {
	if (self.failed) {
#if TARGET_OS_IPHONE
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.errorTitle message:self.errorMessage delegate:self cancelButtonTitle:ATLocalizedString(@"Close", nil) otherButtonTitles:nil];
		[alert show];
		[alert release];
#endif
	}
}

- (void)cancel {
	@synchronized(self) {
		cancelled = YES;
	}
}

- (void)getContactInfo {
    NSString *uuid = [[ATBackend sharedBackend] deviceUUID];
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:uuid forKey:@"uuid"];
    NSString *urlString = [NSString stringWithFormat:@"http://www.apptentive.com/feedback/fetch_contact?%@", [self stringForParameters:parameters]];
    [self get:[NSURL URLWithString:urlString]];
}

- (void)postFeedback:(ATFeedback *)feedback {
    NSDictionary *postData = [feedback apiDictionary];
    NSData *fileData = UIImagePNGRepresentation(feedback.screenshot);
    NSString *url = @"http://www.apptentive.com/feedback";
    [self post:[NSURL URLWithString:url] withFileData:fileData ofMimeType:@"image/png" fileDataKey:@"feedback[screenshot]" parameters:postData];
}

- (NSString *)stringForParameters:(NSDictionary *)parameters {
	NSMutableString *result = [[NSMutableString alloc] init];
	do { // once
		if (!parameters || [parameters count] == 0) {
			[result appendString:@""];
			break;
		}
		
		BOOL appendAmpersand = NO;
		for (NSString *key in [parameters keyEnumerator]) {
			NSString *val = [self stringForParameter:[parameters objectForKey:key]];
			if (!val) continue;
			
			if (appendAmpersand) {
				[result appendString:@"&"];
			}
            [result appendString:[ATUtilities stringByEscapingForURLArguments:key]];
			[result appendString:@"="];
            [result appendString:[ATUtilities stringByEscapingForURLArguments:val]];
			appendAmpersand = YES;
		}
	} while (NO);
	return [result autorelease];
}

- (NSString *)stringForParameter:(id)value {
	NSString *result = nil;
	if ([value isKindOfClass:[NSString class]]) {
		result = (NSString *)value;
	} else if ([value isKindOfClass:[NSNumber class]]) {
		result = [(NSNumber *)value stringValue];
	}
	return result;
}

#pragma mark ATURLConnection Delegates
- (void)connectionFinishedSuccessfully:(ATURLConnection *)sender {
	@synchronized(self) {
		if (cancelled) return;
	}
	int statusCode = sender.statusCode;
	switch (statusCode) {
		case 200:
        case 201:
		case 400: // rate limit reached
		case 403: // whatevs, probably private feed
			break;
		case 401:
			self.failed = YES;
			self.errorTitle = ATLocalizedString(@"Authentication Failed", @"");
			self.errorMessage = ATLocalizedString(@"Wrong username and/or password.", @"");
			break;
		case 304:
			break;
		default:
			self.failed = YES;
			self.errorTitle = ATLocalizedString(@"Server error.", @"");
			self.errorMessage = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
			break;
	}
	
	id result = nil;
	do { // once
		NSData *d = [sender responseData];
		if (!d) break;
		if (self.returnType == ATWebClientReturnTypeData) {
			result = d;
			break;
		}
		
		NSString *s = [[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding] autorelease];
		if (!s) break;
		if (self.returnType == ATWebClientReturnTypeString) {
			result = s;
			break;
		}
        
#ifdef SUPPORT_JSON
		if (self.returnType == ATWebClientReturnTypeJSON) {
			id json = [s JSONValue];
			if (!json) {
				self.failed = YES;
				self.errorTitle = ATLocalizedString(@"Invalid response from server.", @"");
				self.errorMessage = ATLocalizedString(@"Server did not return properly formatted JSON.", @"");
			}
			result = json;
			break;
		}
#endif
	} while (NO);
	
	if (delegate && action) {
		[delegate performSelector:action withObject:self withObject:result];
	}
}

- (void)connectionFailed:(ATURLConnection *)sender {
	@synchronized(self) {
		if (cancelled) return;
	}
	self.failed = YES;
	if (sender.failedAuthentication || sender.statusCode == 401) {
		self.errorTitle = ATLocalizedString(@"Authentication Failed", @"");
		self.errorMessage = ATLocalizedString(@"Wrong username and/or password.", @"");
	} else {
		self.errorTitle = ATLocalizedString(@"Network Connection Error", @"");
		self.errorMessage = [sender.connectionError localizedDescription];
	}
	if (delegate && action) {
		[delegate performSelector:action withObject:self withObject:nil];
	}
}

#pragma mark Private Methods
- (void)get:(NSURL *)theURL {
	ATConnectionManager *cm = [ATConnectionManager sharedSingleton];
	ATURLConnection *conn = [[ATURLConnection alloc] initWithURL:theURL delegate:self];
	conn.timeoutInterval = self.timeoutInterval;
	[self addAPIHeaders:conn];
	[cm addConnection:conn toChannel:self.channelName];
	[conn release];
	[cm start];
}

- (void)post:(NSURL *)theURL {
	ATConnectionManager *cm = [ATConnectionManager sharedSingleton];
	ATURLConnection *conn = [[ATURLConnection alloc] initWithURL:theURL delegate:self];
	conn.timeoutInterval = self.timeoutInterval;
	[self addAPIHeaders:conn];
	[conn setHTTPMethod:@"POST"];
	
	[cm addConnection:conn toChannel:self.channelName];
	[conn release];
	[cm start];
}

- (void)post:(NSURL *)theURL JSON:(NSString *)body {
	ATConnectionManager *cm = [ATConnectionManager sharedSingleton];
	ATURLConnection *conn = [[ATURLConnection alloc] initWithURL:theURL delegate:self];
	conn.timeoutInterval = self.timeoutInterval;
	[self addAPIHeaders:conn];
	[conn setHTTPMethod:@"POST"];
	[conn setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
	int length = [body lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	[conn setValue:[NSString stringWithFormat:@"%d", length] forHTTPHeaderField:@"Content-Length"];
	[conn setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
	
	[cm addConnection:conn toChannel:self.channelName];
	[conn release];
	[cm start];
}

- (void)post:(NSURL *)theURL body:(NSString *)body {
	ATConnectionManager *cm = [ATConnectionManager sharedSingleton];
	ATURLConnection *conn = [[ATURLConnection alloc] initWithURL:theURL delegate:self];
	conn.timeoutInterval = self.timeoutInterval;
	[self addAPIHeaders:conn];
	[conn setHTTPMethod:@"POST"];
	[conn setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	int length = [body lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	[conn setValue:[NSString stringWithFormat:@"%d", length] forHTTPHeaderField:@"Content-Length"];
	[conn setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
	
	[cm addConnection:conn toChannel:self.channelName];
	[conn release];
	[cm start];
}

- (void)post:(NSURL *)theURL withFileData:(NSData *)data ofMimeType:(NSString *)mimeType fileDataKey:(NSString *)fileDataKey parameters:(NSDictionary *)parameters {
    ATConnectionManager *cm = [ATConnectionManager sharedSingleton];
    ATURLConnection *conn = [[ATURLConnection alloc] initWithURL:theURL delegate:self];
    conn.timeoutInterval = self.timeoutInterval * 10.0;
    [self addAPIHeaders:conn];
    [conn setHTTPMethod:@"POST"];
    
    NSDictionary *postParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
    
    // Figure out boundary string.
    NSString *boundary = nil;
    while (YES) {
        boundary = [ATUtilities randomStringOfLength:20];
        NSData *boundaryData = [boundary dataUsingEncoding:NSUTF8StringEncoding];
        BOOL found = NO;
        for (NSString *key in [postParameters allKeys]) {
            id value = [postParameters objectForKey:key];
            if ([value isKindOfClass:[NSString class]]) {
                NSRange range = [(NSString *)value rangeOfString:boundary];
                if (range.location != NSNotFound) {
                    found = YES;
                    break;
                }
            } else if ([value isKindOfClass:[NSData class]]) {
                NSRange range = [(NSData *)value rangeOfData:boundaryData options:0 range:NSMakeRange(0, [(NSData *)value length])];
                if (range.location != NSNotFound) {
                    found = YES;
                    break;
                }
            } else {
                NSString *className = @"id";
                if ([value isKindOfClass:[NSObject class]]) {
                    className = [NSString stringWithCString:object_getClassName((NSObject *)value) encoding:NSUTF8StringEncoding];
                }
                @throw [NSException exceptionWithName:@"ATWebClientException" reason:[NSString stringWithFormat:@"Can't encode form data of class: %@", className] userInfo:nil];
            }
        }
        if (!found) {
            break;
        }
    }
    
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; charset=utf-8; boundary=%@", boundary];
    [conn setValue:contentType forHTTPHeaderField:@"Content-Type"];
    
    
    NSMutableData *multipartEncodedData = [NSMutableData data];
    if (data) {
        [postParameters setValue:data forKey:fileDataKey];
    }
    
    [multipartEncodedData appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    for (NSString *key in [postParameters allKeys]) {
        id value = [postParameters objectForKey:key];
        [multipartEncodedData appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        if ([value isKindOfClass:[NSString class]]) {
            [multipartEncodedData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
            [multipartEncodedData appendData:[(NSString *)value dataUsingEncoding:NSUTF8StringEncoding]];
        } else if ([value isKindOfClass:[NSData class]]) {
            [multipartEncodedData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", key, [ATUtilities randomStringOfLength:10]] dataUsingEncoding:NSUTF8StringEncoding]];
            [multipartEncodedData appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n", mimeType] dataUsingEncoding:NSUTF8StringEncoding]];
            [multipartEncodedData appendData:[@"Content-Transfer-Encoding: binary\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
            [multipartEncodedData appendData:(NSData *)value];
        } // else Should be handled above.
    }
    [multipartEncodedData appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [conn setHTTPBody:multipartEncodedData];
    
    // Debugging helpers:
    /*
    NSLog(@"wtf parameters: %@", parameters);
    NSLog(@"-length: %d", [multipartEncodedData length]);
    NSLog(@"-data: %@", [NSString stringWithUTF8String:[multipartEncodedData bytes]]);
     */
    
	[cm addConnection:conn toChannel:self.channelName];
	[conn release];
	[cm start];
}


- (void)addAPIHeaders:(ATURLConnection *)conn {
	[conn setValue:[self userAgentString] forHTTPHeaderField:@"User-Agent"];
	[conn setValue: @"gzip" forHTTPHeaderField: @"Accept-Encoding"];
	[conn setValue: @"text/xml" forHTTPHeaderField: @"Accept"];
	[conn setValue: @"utf-8" forHTTPHeaderField: @"Accept-Charset"];
    NSString *apiKey = [[ATBackend sharedBackend] apiKey];
    if (apiKey) {
        NSData *apiKeyData = [apiKey dataUsingEncoding:NSUTF8StringEncoding];
        NSString *value = [NSString stringWithFormat:@"Basic %@", [apiKeyData at_base64EncodedString]];
        [conn setValue:value forHTTPHeaderField:@"Authorization"];
    }
}

#pragma mark Memory Management
- (void)dealloc {
    delegate = nil;
    ATConnectionManager *cm = [ATConnectionManager sharedSingleton];
    [cm cancelAllConnectionsInChannel:channelName];
	[errorTitle release];
	[errorMessage release];
	[channelName release];
	[super dealloc];
}
@end


@implementation ATWebClient (Private)
- (NSString *)userAgentString {
    return [NSString stringWithFormat:kUserAgentFormat, kATConnectVersionString, kATConnectPlatformString];
}
@end
