//
//  ApptentiveState.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ApptentiveState : NSObject <NSSecureCoding>

@end

@interface ApptentiveState (JSON)

+ (NSDictionary *)JSONKeyPathMapping;
- (NSDictionary *)dictionaryForJSONKeyPropertyMapping:(NSDictionary *)JSONKeyPropertyMapping;
- (NSDictionary *)JSONDictionary;

@end

@interface ApptentiveState (Migration)

- (instancetype)initAndMigrate;

+ (void) deleteMigratedData;

@end

NS_ASSUME_NONNULL_END
