//
//  ApptentiveCustomData.h
//  Store
//
//  Created by Frank Schmitt on 7/22/16.
//  Copyright © 2016 Apptentive. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ApptentiveCustomDataState;


@interface ApptentiveMutableDeviceState : NSObject

- (instancetype)initWithCustomDataState:(ApptentiveCustomDataState *)state;

- (void)addCustomData:(NSObject<NSCoding> *)customData withKey:(NSString *)key;
- (void)removeCustomDataWithKey:(NSString *)key;

@property (readonly, strong, nonatomic) NSDictionary *customData;

@end
