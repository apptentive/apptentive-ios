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
	NSString *name;
	NSString *facebookID;
}
@property (nonatomic, retain) NSString *apptentiveID;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *facebookID;
@property (nonatomic, retain) NSString *emailAddress;

+ (ATPerson *)newPersonFromJSON:(NSDictionary *)json;
- (NSDictionary *)apiJSON;
@end
