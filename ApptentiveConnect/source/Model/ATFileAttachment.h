//
//  ATFileAttachment.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/20/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@class ATMessage;

@interface ATFileAttachment : NSManagedObject
@property (nonatomic, strong) NSString *localPath;
@property (nonatomic, strong) NSString *mimeType; // starts w/ lowercase b/c Core Data is stupid
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSURL *remoteURL;
@property (nonatomic, strong) NSURL *remoteThumbnailURL;
@property (nonatomic, strong) ATMessage *message;

@property (nonatomic, readonly) NSString *fullLocalPath;

+ (instancetype)newInstanceWithFileData:(NSData *)fileData MIMEType:(NSString *)MIMEType;
+ (instancetype)newInstanceWithJSON:(NSDictionary *)JSON;
- (void)updateWithJSON:(NSDictionary *)JSON;

- (NSData *)fileData;
- (void)setFileData:(NSData *)data;

/** Can be called from background thread. */
- (NSURL *)beginMoveToStorageFrom:(NSURL *)temporaryLocation;

/** Must be called from main thread. */
- (void)completeMoveToStorageFor:(NSURL *)storageLocation;

- (UIImage *)thumbnailOfSize:(CGSize)size;
- (void)createThumbnailOfSize:(CGSize)size completion:(void (^)(void))completion;

@end
