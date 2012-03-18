//
//  ATAppConfigurationUpdater.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/18/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ATAPIRequest.h"

NSString * const ATAppConfigurationUpdaterFinished;

@interface ATAppConfigurationUpdater : NSObject <ATAPIRequestDelegate> {
@private
	ATAPIRequest *request;
}
+ (BOOL)shouldCheckForUpdate;
- (void)update;
- (void)cancel;
@end
