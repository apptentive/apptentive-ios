//
//  ATFileAttachment.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/20/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@class ATFileMessage;

typedef enum {
	ATFileAttachmentSourceUnknown,
	ATFileAttachmentSourceScreenshot,
	ATFileAttachmentSourceCamera,
	ATFileAttachmentSourcePhotoLibrary,
	ATFIleAttachmentSourceProgrammatic,
} ATFIleAttachmentSource;

//TODO: Add CGSize for images?
@interface ATFileAttachment : NSManagedObject
@property (nonatomic, strong) NSString *localPath;
@property (nonatomic, strong) NSString *mimeType;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSNumber *source;
@property (nonatomic, strong) NSNumber *transient;
@property (nonatomic, strong) NSNumber *userVisible;
@property (nonatomic, strong) ATFileMessage *fileMessage;

- (void)setFileData:(NSData *)data;
- (void)setFileFromSourcePath:(NSString *)sourceFilename;

- (NSString *)fullLocalPath;

- (UIImage *)thumbnailOfSize:(CGSize)size;
- (void)createThumbnailOfSize:(CGSize)size completion:(void (^)(void))completion;
@end
