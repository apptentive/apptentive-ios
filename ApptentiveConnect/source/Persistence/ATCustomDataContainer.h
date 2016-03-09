//
//  ATCustomDataContainer.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/5/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ATUpdater.h"

extern NSString * const ATDataNeedsSaveNotification;

@interface ATCustomDataContainer : NSObject <NSCoding, ATUpdatable>

@property (nonatomic, readonly) NSMutableDictionary *customData;

- (instancetype)initWithJSONDictionary:(NSDictionary *)JSON;
@property (nonatomic, readonly) NSDictionary *dictionaryRepresentation;

- (void)setCustomDataString:(NSString *)string forKey:(NSString *)key;
- (void)setCustomDataBool:(BOOL)boolean forKey:(NSString *)key;
- (void)setCustomDataNumber:(NSNumber *)number forKey:(NSString *)key;
- (void)setCustomData:(NSObject<NSCoding> *)data forKey:(NSString *)key;
- (void)removeCustomDataForKey:(NSString *)key;

- (void)saveAndFlagForUpdate;

@end
