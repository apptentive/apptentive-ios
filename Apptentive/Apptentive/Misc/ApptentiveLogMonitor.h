//
//  ApptentiveLogMonitor.h
//  Apptentive
//
//  Created by Alex Lementuev on 10/10/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveDispatchQueue;

@interface ApptentiveLogMonitor : NSObject

+ (void)startSessionWithBaseURL:(NSURL *)baseURL appKey:(NSString *)appKey signature:(NSString *)appSignature queue:(ApptentiveDispatchQueue *)queue;
+ (BOOL)resumeSession;

@end

NS_ASSUME_NONNULL_END
