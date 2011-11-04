//
//  ATWebClient.h
//  AmidstApp
//
//  Created by Andrew Wooster on 7/28/09.
//  Copyright 2009 Apptentive, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ATFeedback;
@class ATAPIRequest;

/*! Singleton for generating API requests. */
@interface ATWebClient : NSObject {
}
+ (ATWebClient *)sharedClient;
- (NSString *)baseURLString;
- (NSString *)commonChannelName;
- (ATAPIRequest *)requestForGettingContactInfo;
- (ATAPIRequest *)requestForPostingFeedback:(ATFeedback *)feedback;
@end
