//
//  ApptentiveLogTag.h
//  Apptentive
//
//  Created by Alex Lementuev on 3/29/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ApptentiveLogTag : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, assign) BOOL enabled;

+ (instancetype)logTagWithName:(NSString *)name enabled:(BOOL)enabled;
- (instancetype)initWithName:(NSString *)name enabled:(BOOL)enabled;

+ (ApptentiveLogTag *)conversationTag;

@end
