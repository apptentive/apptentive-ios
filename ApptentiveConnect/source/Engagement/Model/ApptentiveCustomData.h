//
//  ApptentiveCustomData.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveState.h"

@class ApptentiveMutableCustomData;

@interface ApptentiveCustomData : ApptentiveState

@property (readonly, strong, nonatomic) NSDictionary <NSString *, NSObject<NSCoding> *> *customData;
@property (strong, nonatomic) NSString *identifier;

- (instancetype)initWithMutableCustomData:(ApptentiveMutableCustomData *)mutableCustomDataContainer;
- (instancetype)initWithCustomData:(NSDictionary *)customData;

@end
