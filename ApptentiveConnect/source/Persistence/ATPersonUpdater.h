//
//  ATPersonUpdater.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/26/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATDiffingUpdater.h"

@class ATPersonInfo;

@interface ATPersonUpdater : ATDiffingUpdater

@property (readonly, nonatomic) ATPersonInfo *currentPerson;

@end
