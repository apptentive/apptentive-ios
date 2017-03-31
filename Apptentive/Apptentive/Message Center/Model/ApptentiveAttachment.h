//
//  ApptentiveAttachment.h
//  Apptentive
//
//  Created by Frank Schmitt on 3/22/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ApptentiveAttachment : NSObject

@property (readonly, nonatomic) NSString *fileName;
@property (readonly, nonatomic) NSString *contentType;
@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) NSInteger size;
@property (readonly, nonatomic) NSURL *remoteURL;

@property (readonly, nonatomic) NSString *fullLocalPath;

- (instancetype)initWithJSON:(NSDictionary *)JSON;
- (instancetype)initWithPath:(NSString *)path contentType:(NSString *)contentType name:(NSString *)name;
- (instancetype)initWithData:(NSData *)data contentType:(NSString *)contentType name:(NSString *)name;

@property (readonly, nonatomic) NSString *extension;
@property (readonly, nonatomic) BOOL canCreateThumbnail;

- (UIImage *)thumbnailOfSize:(CGSize)size;

/** Can be called from background thread. */
- (NSURL *)permanentLocation;

/** Must be called from main thread. */
- (void)completeMoveToStorageFor:(NSURL *)storageLocation;

@end

/*
 
 @property (copy, nonatomic) NSString *localPath;
 @property (copy, nonatomic) NSString *mimeType; // starts w/ lowercase b/c Core Data is stupid
 @property (copy, nonatomic) NSString *name;
 @property (strong, nonatomic) NSURL *remoteURL;
 @property (strong, nonatomic) NSURL *remoteThumbnailURL;
 @property (strong, nonatomic) ApptentiveLegacyMessage *message;

 @property (readonly, nonatomic) NSString *fullLocalPath;
 @property (readonly, nonatomic) NSData *fileData;

 + (instancetype)newInstanceWithFileData:(NSData *)fileData MIMEType:(NSString *)MIMEType name:(NSString *)name;
 + (instancetype)newInstanceWithJSON:(NSDictionary *)JSON inContext:(NSManagedObjectContext *)context;
 + (void)addMissingExtensions;
 - (void)updateWithJSON:(NSDictionary *)JSON;

 - (void)setFileData:(NSData *)data MIMEType:(NSString *)MIMEType name:(NSString *)name;

  Can be called from background thread.
- (NSURL *)permanentLocation;

 Must be called from main thread. 
- (void)completeMoveToStorageFor:(NSURL *)storageLocation;

- (UIImage *)thumbnailOfSize:(CGSize)size;

*/
