//
//  ApptentiveCustomData.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveState.h"

@interface ApptentiveCustomData : ApptentiveState

@property (readonly, strong, nonatomic) NSDictionary <NSString *, NSObject<NSCoding> *> *customData;
@property (strong, nonatomic) NSString *identifier;

- (instancetype)initWithCustomData:(NSDictionary *)customData identifier:(NSString *)identifier;

@end
