//
//  ATEngagementBackend.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 8/21/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ATInteraction;

@interface ATEngagementBackend : NSObject {
@private
	NSMutableDictionary *codePointInteractions;
}

+ (ATEngagementBackend *)sharedBackend;
- (void)checkForEngagementManifest;
- (void)didReceiveNewCodePointInteractions:(NSDictionary *)codePointInteractions maxAge:(NSTimeInterval)expiresMaxAge;
+ (NSString *)cachedEngagementStoragePath;

- (NSArray *)interactionsForCodePoint:(NSString *)codePoint;
- (ATInteraction *)interactionForCodePoint:(NSString *)codePoint;

- (NSDictionary *)usageDataForInteraction:(ATInteraction *)interation atCodePoint:(NSString *)codePoint;

@end
