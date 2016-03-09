//
//  ATUpdater.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/25/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ATAPIRequest.h"

@protocol ATUpdatable, ATUpdaterDelegate;

@interface ATUpdater : NSObject <ATAPIRequestDelegate>

@property (weak, nonatomic) id<ATUpdaterDelegate> delegate;
@property (readonly, nonatomic) NSString *storagePath;
@property (readonly, nonatomic) id<ATUpdatable> currentVersion;
@property (readonly, nonatomic, getter=isUpdating) BOOL updating;

- (instancetype)initWithStoragePath:(NSString *)storagePath;
- (BOOL)needsUpdate;
- (void)update;

- (void)cancel;

#pragma mark - For subclass use only

+ (Class <ATUpdatable>)updatableClass;

@property (strong, nonatomic) ATAPIRequest *request;

- (id<ATUpdatable>)currentVersionFromUserDefaults:(NSUserDefaults *)userDefaults;
- (void)removeCurrentVersionFromUserDefaults:(NSUserDefaults *)userDefaults;

- (id<ATUpdatable>)emptyCurrentVersion;
- (ATAPIRequest *)requestForUpdating;
- (void)didUpdateWithRequest:(ATAPIRequest *)request;
- (void)archiveCurrentVersion;

@end

@protocol ATUpdatable <NSObject>

+ (instancetype)newInstanceFromDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)dictionaryRepresentation;

@end

@protocol ATUpdaterDelegate <NSObject>

- (void)updater:(ATUpdater *)updater didFinish:(BOOL)success;

@end
