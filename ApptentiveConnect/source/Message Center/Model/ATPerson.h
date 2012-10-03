//
//  ATPerson.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ATPerson : NSObject <NSCoding> {
@private
	NSString *apptentiveID;
	NSString *firstName;
	NSString *lastName;
	NSString *facebookID;
}
@property (nonatomic, retain) NSString *apptentiveID;
@property (nonatomic, retain) NSString *firstName;
@property (nonatomic, retain) NSString *lastName;
@property (nonatomic, retain) NSString *facebookID;
@end
