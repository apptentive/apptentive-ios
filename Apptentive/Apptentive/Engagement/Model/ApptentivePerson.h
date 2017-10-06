//
//  ApptentivePerson.h
//  Apptentive
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveCustomData.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const ATPersonLastUpdateValuePreferenceKey;

/**
 An `ApptentivePerson` object represents a person using the Apptentive SDK.
 */
@interface ApptentivePerson : ApptentiveCustomData

/**
 The name associated with the person.
 */
@property (copy, nullable, nonatomic) NSString *name;

/**
 The email address associated with the person.
 */
@property (copy, nullable, nonatomic) NSString *emailAddress;

@end


@interface ApptentiveLegacyPerson : NSObject

@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *emailAddress;

@end

NS_ASSUME_NONNULL_END
