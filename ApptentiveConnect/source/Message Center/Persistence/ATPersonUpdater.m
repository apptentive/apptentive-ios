//
//  ATPersonUpdater.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATPersonUpdater.h"
#import "ATWebClient+MessageCenter.h"

NSString *const ATCurrentPersonPreferenceKey = @"ATCurrentPersonPreferenceKey";


@interface ATPersonUpdater (Private)
- (void)processResult:(NSDictionary *)jsonPerson;
@end

@implementation ATPersonUpdater
@synthesize delegate;

+ (BOOL)personExists {
	ATPerson *currentPerson = [ATPersonUpdater currentPerson];
	if (currentPerson == nil) {
		return NO;
	} else {
		return YES;
	}
}

+ (ATPerson *)currentPerson {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *personData = [defaults dataForKey:ATCurrentPersonPreferenceKey];
	if (!personData) {
		return nil;
	}
	ATPerson *person = [NSKeyedUnarchiver unarchiveObjectWithData:personData];
	return person;
}

- (id)initWithDelegate:(NSObject<ATPersonUpdaterDelegate> *)aDelegate {
	if ((self = [super init])) {
		delegate = aDelegate;
	}
	return self;
}

- (void)dealloc {
	delegate = nil;
	[self cancel];
	[super dealloc];
}

- (void)createPerson {
	[self cancel];
	request = [[[ATWebClient sharedClient] requestForCreatingPerson:nil] retain];
	request.delegate = self;
	[request start];
}

- (void)cancel {
	if (request) {
		request.delegate = nil;
		[request cancel];
		[request release], request = nil;
	}
}

- (float)percentageComplete {
	if (request) {
		return [request percentageComplete];
	} else {
		return 0.0f;
	}
}

#pragma mark ATATIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)sender result:(NSObject *)result {
	@synchronized (self) {
		if ([result isKindOfClass:[NSDictionary class]]) {
			[self processResult:(NSDictionary *)result];
		} else {
			NSLog(@"Person result is not NSDictionary!");
			[delegate personUpdater:self didFinish:NO];
		}
	}
}

- (void)at_APIRequestDidProgress:(ATAPIRequest *)sender {
	// pass
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)sender {
	@synchronized(self) {
		NSLog(@"Request failed: %@, %@", sender.errorTitle, sender.errorMessage);
		
		[delegate personUpdater:self didFinish:NO];
	}
}
@end

@implementation ATPersonUpdater (Private)
- (void)processResult:(NSDictionary *)jsonPerson {
	ATPerson *person = [ATPerson newPersonFromJSON:jsonPerson];
	
	if (person) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSData *personData = [NSKeyedArchiver archivedDataWithRootObject:person];
		[defaults setObject:personData forKey:ATCurrentPersonPreferenceKey];
		[defaults synchronize];
		[delegate personUpdater:self didFinish:YES];
	} else {
		[delegate personUpdater:self didFinish:NO];
	}
	[person release], person = nil;
}
@end

