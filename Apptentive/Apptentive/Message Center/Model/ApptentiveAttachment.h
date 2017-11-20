//
//  ApptentiveAttachment.h
//  Apptentive
//
//  Created by Frank Schmitt on 3/22/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuickLook/QuickLook.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveAttachment : NSObject <NSSecureCoding>

@property (readonly, nullable, nonatomic) NSString *filename;
@property (readonly, nonatomic) NSString *contentType;
@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) NSInteger size;
@property (readonly, nonatomic) NSURL *remoteURL;

@property (readonly, nonatomic) NSString *fullLocalPath;

- (nullable instancetype)initWithJSON:(NSDictionary *)JSON;
- (nullable instancetype)initWithPath:(NSString *)path contentType:(NSString *)contentType name:(nullable NSString *)name;
- (nullable instancetype)initWithData:(NSData *)data contentType:(NSString *)contentType name:(nullable NSString *)name attachmentDirectoryPath:(NSString *)attachmentDirectoryPath;

@property (strong, nonatomic) NSString *attachmentDirectoryPath;
@property (readonly, nonatomic) NSString *extension;
@property (readonly, nonatomic) BOOL canCreateThumbnail;

- (nullable UIImage *)thumbnailOfSize:(CGSize)size;
- (nullable NSString *)fullLocalPathForFilename:(NSString *)filename;

/** Can be called from background thread. */
- (NSURL *)permanentLocation;

/** Must be called from main thread. */
- (void)completeMoveToStorageFor:(NSURL *)storageLocation;

- (void)deleteLocalContent;

- (ApptentiveAttachment *)mergedWith:(ApptentiveAttachment *)attachmentFromServer;

@end


@interface ApptentiveAttachment (QuickLook) <QLPreviewItem>
@end

NS_ASSUME_NONNULL_END
