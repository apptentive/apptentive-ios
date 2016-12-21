//
//  ApptentiveCount.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/16/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveState.h"

@interface ApptentiveCount : ApptentiveState

@property (readonly, nonatomic) NSInteger totalCount;
@property (readonly, nonatomic) NSInteger versionCount;
@property (readonly, nonatomic) NSInteger buildCount;
@property (readonly, strong, nonatomic) NSDate *lastInvoked;

- (instancetype)initWithTotalCount:(NSInteger)totalCount versionCount:(NSInteger)versionCount buildCount:(NSInteger)buildCount lastInvoked:(NSDate *)date;
- (void)resetAll;
- (void)resetVersion;
- (void)resetBuild;
- (void)invoke;

@end
