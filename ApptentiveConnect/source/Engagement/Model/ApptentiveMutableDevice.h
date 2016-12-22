//
//  ApptentiveCustomData.h
//  Store
//
//  Created by Frank Schmitt on 7/22/16.
//  Copyright © 2016 Apptentive. All rights reserved.
//

#import "ApptentiveMutableCustomData.h"

@class ApptentiveDevice, ApptentiveCustomData;

@interface ApptentiveMutableDevice : ApptentiveMutableCustomData

- (instancetype)initWithDevice:(ApptentiveDevice *)device;

@property (copy, nonatomic) NSDictionary *integrationConfiguration;

@end
