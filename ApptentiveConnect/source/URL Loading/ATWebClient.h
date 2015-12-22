//
//  ATWebClient.h
//  apptentive-ios
//
//  Created by Andrew Wooster on 7/28/09.
//  Copyright 2009 Apptentive, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ATFeedback;
@class ATAPIRequest;

extern NSString *const ATWebClientDefaultChannelName;

/*! Singleton for generating API requests. */
@interface ATWebClient : NSObject

+ (ATWebClient *)sharedClient;

@property (readonly, nonatomic) NSURL *baseURL;

- (instancetype)initWithBaseURL:(NSURL *)baseURL;

- (NSString *)commonChannelName;
- (ATAPIRequest *)requestForGettingAppConfiguration;
@end
