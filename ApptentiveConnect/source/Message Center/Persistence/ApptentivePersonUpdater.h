//
//  ApptentivePersonUpdater.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ApptentivePersonInfo.h"

extern NSString *const ATPersonLastUpdateValuePreferenceKey;


@interface ApptentivePersonUpdater : NSObject

+ (BOOL)shouldUpdate;
+ (NSDictionary *)lastSavedVersion;
+ (void)resetPersonInfo;
- (void)update;

@end
