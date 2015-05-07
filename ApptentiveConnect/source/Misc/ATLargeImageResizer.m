//
//  ATLargeImageResizer.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/19/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "ATLargeImageResizer.h"

#import "ATUtilities.h"

@interface ATLargeImageResizer ()

@property (strong, nonatomic) NSURL *imageURL;
@property (strong, nonatomic) UIImage *originalImage;
@property (assign, nonatomic) BOOL shouldCancel;

@end

@implementation ATLargeImageResizer

- (instancetype)initWithImageAssetURL:(NSURL *)url originalImage:(UIImage *)image delegate:(NSObject<ATLargeImageResizerDelegate> *)aDelegate {
	if ((self = [super init])) {
		_imageURL = [url copy];
		_originalImage = image;
		_delegate = aDelegate;
	}
	return self;
}

- (void)cancel {
	self.delegate = nil;
	self.shouldCancel = YES;
}

- (void)resizeWithMaximumSize:(CGSize)maxSize {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		@autoreleasepool {
			if (self.originalImage &&
				self.originalImage.size.width <= maxSize.width &&
				self.originalImage.size.height <= maxSize.height) {
				ATLogInfo(@"Using original image");
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.delegate imageResizerDoneResizing:self result:self.originalImage];
				});
				return;
			}
			
			ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
			[assetLibrary assetForURL:self.imageURL resultBlock:^(ALAsset *asset) {
				ALAssetRepresentation *rep = [asset defaultRepresentation];
				CGImageRef usableImageRef = NULL;
				UIImage *sourceImage = nil;
				usableImageRef = [rep fullScreenImage];
				if (!usableImageRef) {
					usableImageRef = [rep fullResolutionImage];
				}
				if (usableImageRef) {
					sourceImage = [UIImage imageWithCGImage:usableImageRef];
				} else {
					sourceImage = self.originalImage;
				}
				if (!sourceImage) {
					ATLogError(@"Unable to get image to resize.");
					dispatch_async(dispatch_get_main_queue(), ^{
						[self.delegate imageResizerFailed:self];
					});
					return;
				}
				CGSize sourceResolution = sourceImage.size;
				if (sourceResolution.height <= maxSize.height && sourceResolution.width <= maxSize.width) {
					dispatch_async(dispatch_get_main_queue(), ^{
						[self.delegate imageResizerDoneResizing:self result:sourceImage];
					});
					return;
				}
				CGSize destinationResolution = ATThumbnailSizeOfMaxSize(sourceResolution, maxSize);
				UIImage *image = [ATUtilities imageByScalingImage:sourceImage toSize:destinationResolution scale:1 fromITouchCamera:YES];
				
				dispatch_async(dispatch_get_main_queue(), ^{
					if (image) {
						[self.delegate imageResizerDoneResizing:self result:image];
					} else {
						[self.delegate imageResizerFailed:self];
					}
				});
			} failureBlock:^(NSError *error) {
				ATLogError(@"Unable to get asset: %@", error);
				[self.delegate imageResizerFailed:self];
			}];
		}
	});
}
@end
