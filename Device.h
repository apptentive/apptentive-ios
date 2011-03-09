//
//  Device.h
//  WowieConnect
//
//  Created by Michael Saffitz on 1/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Base.h"

@interface Device : Base {
    NSString *deviceId;
    NSString *udid;
	NSString *emailAddress;
	NSString *firstName;
    NSString *lastName;
}

@property (nonatomic, retain) NSString *deviceId;
@property (nonatomic, retain) NSString *udid;
@property (nonatomic, retain) NSString *emailAddress;
@property (nonatomic, retain) NSString *firstName;
@property (nonatomic, retain) NSString *lastName;

//+(NSString*)archivePath;
+ (Device *)createOrRetrieveDevice:(NSString*)archivePath;

-(void)archive:(NSString*)archivePath;
-(BOOL)buildDevice;

- (void) encodeWithCoder: (NSCoder *)coder;
- initWithCoder: (NSCoder *)coder;

@end
