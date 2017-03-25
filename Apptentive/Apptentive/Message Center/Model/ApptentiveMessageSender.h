//
//  ApptentiveMessageSender.h
//  Apptentive
//
//  Created by Frank Schmitt on 3/22/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ApptentiveMessageSender : NSObject

@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) NSString *identifier;
@property (readonly, nonatomic) NSURL *profilePhotoURL;

- (instancetype)initWithJSON:(NSDictionary *)JSON;
- (instancetype)initWithName:(NSString *)name identifier:(NSString *)identifier profilePhotoURL:(NSURL *)profilePhotoURL;

@end
