//
//  ATPersonUpdater.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ATAPIRequest.h"
#import "ATPersonInfo.h"

extern NSString *const ATPersonLastUpdateValuePreferenceKey;

@protocol ATPersonUpdaterDelegate;


@interface ATPersonUpdater : NSObject <ATAPIRequestDelegate>

@property (readonly, nonatomic) NSString *storagePath;
@property (weak, nonatomic) NSObject<ATPersonUpdaterDelegate> *delegate;

//+ (BOOL)shouldUpdate;

@property (copy, nonatomic) ATPersonInfo *lastSavedPerson;

+ (NSDictionary *)lastSavedVersion;

- (instancetype)initWithStoragePath:(NSString *)storagePath;

- (void)update;
- (void)cancel;

@end

@protocol ATPersonUpdaterDelegate <NSObject>
- (void)personUpdater:(ATPersonUpdater *)personUpdater didFinish:(BOOL)success;
@end
