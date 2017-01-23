//
//  ApptentiveCustomDataState.h
//  Store
//
//  Created by Frank Schmitt on 7/22/16.
//  Copyright © 2016 Apptentive. All rights reserved.
//

#import "ApptentiveState.h"


@interface ApptentiveCustomDataState : ApptentiveState

@property (readonly, strong, nonatomic) NSDictionary<NSString *, NSObject<NSCoding> *> *customData;

- (instancetype)initWithCustomData:(NSDictionary *)customData;

@end


@interface ApptentiveCustomDataState (JSON)

+ (NSDictionary *)JSONKeyPathMapping;
- (NSDictionary *)dictionaryForJSONKeyPropertyMapping:(NSDictionary *)JSONKeyPropertyMapping;
@property (readonly, nonatomic) NSDictionary *JSONDictionary;

@end
