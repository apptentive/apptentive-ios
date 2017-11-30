//
//  ApptentiveAppInstall.m
//  Apptentive
//
//  Created by Frank Schmitt on 7/13/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveAppInstall.h"
#import "ApptentiveAppRelease.h"
#import "ApptentiveDevice.h"
#import "ApptentivePerson.h"
#import "ApptentiveSDK.h"

NS_ASSUME_NONNULL_BEGIN


@implementation ApptentiveAppInstall

@synthesize token = _token;
@synthesize identifier = _identifier;

@synthesize person = _person;
@synthesize device = _device;
@synthesize SDK = _SDK;
@synthesize appRelease = _appRelease;

- (instancetype)initWithToken:(nullable NSString *)token identifier:(nullable NSString *)identifier {
	self = [super init];
	if (self) {
		_token = token;
		_identifier = identifier;

		_person = [[ApptentivePerson alloc] init];
		_device = [[ApptentiveDevice alloc] initWithCurrentDevice];
		_SDK = [[ApptentiveSDK alloc] initWithCurrentSDK];
		_appRelease = [[ApptentiveAppRelease alloc] initWithCurrentAppRelease];
	}
	return self;
}

@end

NS_ASSUME_NONNULL_END
