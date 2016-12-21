//
//  ApptentiveCustomData.h
//  Store
//
//  Created by Frank Schmitt on 7/22/16.
//  Copyright © 2016 Apptentive. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ApptentiveDevice, ApptentiveCustomData;

@interface ApptentiveMutableDevice : NSObject

- (instancetype)initWithDevice:(ApptentiveDevice *)device;
- (instancetype)initWithCustomData:(ApptentiveCustomData *)customData;

- (void)addCustomString:(NSString *)string withKey:(NSString *)key NS_SWIFT_NAME(add(_:withKey:));
- (void)addCustomNumber:(NSNumber *)number withKey:(NSString *)key NS_SWIFT_NAME(add(_:withKey:));
- (void)addCustomBool:(BOOL)boolValue withKey:(NSString *)key NS_SWIFT_NAME(add(_:withKey:));
- (void)removeCustomValueWithKey:(NSString *)key NS_SWIFT_NAME(remove(withKey:));

@property (readonly, copy, nonatomic) NSDictionary *customData;
@property (readonly, strong, nonatomic) NSString *identifier;

@end
