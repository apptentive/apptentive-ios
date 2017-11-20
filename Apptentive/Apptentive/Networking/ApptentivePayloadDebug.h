//
//  ApptentivePayloadDebug.h
//  Apptentive
//
//  Created by Alex Lementuev on 7/27/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN


@interface ApptentivePayloadDebug : NSObject

+ (void)printPayloadSendingQueueWithContext:(NSManagedObjectContext *)context title:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
