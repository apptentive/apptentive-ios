//
//  ApptentiveLegacyMessageSender.h
//  Apptentive
//
//  Created by Andrew Wooster on 10/30/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveLegacyMessage;


@interface ApptentiveLegacyMessageSender : NSManagedObject

@property (copy, nonatomic) NSString *apptentiveID;
@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *emailAddress;
@property (copy, nonatomic) NSString *profilePhotoURL;
@property (strong, nonatomic) NSSet *sentMessages;
@property (strong, nonatomic) NSSet *receivedMessages;

@end

NS_ASSUME_NONNULL_END
