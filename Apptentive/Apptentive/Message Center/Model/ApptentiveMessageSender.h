//
//  ApptentiveMessageSender.h
//  Apptentive
//
//  Created by Frank Schmitt on 3/22/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveMessageSender : NSObject <NSSecureCoding>

@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) NSString *identifier;
@property (readonly, nonatomic) NSURL *profilePhotoURL;

- (nullable instancetype)initWithJSON:(NSDictionary *)JSON;
- (nullable instancetype)initWithName:(nullable NSString *)name identifier:(NSString *)identifier profilePhotoURL:(nullable NSURL *)profilePhotoURL;

@end

NS_ASSUME_NONNULL_END
