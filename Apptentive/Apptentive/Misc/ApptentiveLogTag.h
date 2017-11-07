//
//  ApptentiveLogTag.h
//  Apptentive
//
//  Created by Alex Lementuev on 3/29/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveLogTag : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, assign) BOOL enabled;

+ (instancetype)logTagWithName:(NSString *)name enabled:(BOOL)enabled;
- (instancetype)initWithName:(NSString *)name enabled:(BOOL)enabled;

+ (ApptentiveLogTag *)conversationTag;
+ (ApptentiveLogTag *)networkTag;
+ (ApptentiveLogTag *)payloadTag;
+ (ApptentiveLogTag *)utilityTag;
+ (ApptentiveLogTag *)storageTag;
+ (ApptentiveLogTag *)logMonitorTag;

@end

NS_ASSUME_NONNULL_END
