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

@implementation ATLargeImageResizer {
	NSURL *imageURL;
	UIImage *originalImage;
	BOOL shouldCancel;
}
@synthesize delegate;

- (instancetype)initWithImageAssetURL:(NSURL *)url originalImage:(UIImage *)image delegate:(NSObject<ATLargeImageResizerDelegate> *)aDelegate {
	if ((self = [super init])) {
		imageURL = [url copy];
		originalImage = [image retain];
		delegate = aDelegate;
	}
	return self;
}

- (void)dealloc {
	[imageURL release], imageURL = nil;
	[originalImage release], originalImage = nil;
	[super dealloc];
}

- (void)cancel {
	delegate = nil;
	shouldCancel = YES;
}

- (void)resizeWithMaximumSize:(CGSize)maxSize {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		@autoreleasepool {
			if (originalImage &&
				originalImage.size.width <= maxSize.width &&
				originalImage.size.height <= maxSize.height) {
				ATLogInfo(@"Using original image");
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.delegate imageResizerDoneResizing:self result:originalImage];
				});
				return;
			}
			
			ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
			[assetLibrary assetForURL:imageURL resultBlock:^(ALAsset *asset) {
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
					sourceImage = originalImage;
				}
				if (!sourceImage) {
					ATLogError(@"Unable to get image to resize.");
					dispatch_async(dispatch_get_main_queue(), ^{
						[delegate imageResizerFailed:self];
					});
					return;
				}
				CGSize sourceResolution = sourceImage.size;
				if (sourceResolution.height <= maxSize.height && sourceResolution.width <= maxSize.width) {
					dispatch_async(dispatch_get_main_queue(), ^{
						[delegate imageResizerDoneResizing:self result:sourceImage];
					});
					return;
				}
				CGSize destinationResolution = ATThumbnailSizeOfMaxSize(sourceResolution, maxSize);
				UIImage *image = [ATUtilities imageByScalingImage:sourceImage toSize:destinationResolution scale:1 fromITouchCamera:YES];
				
				dispatch_async(dispatch_get_main_queue(), ^{
					if (image) {
						[delegate imageResizerDoneResizing:self result:image];
					} else {
						[delegate imageResizerFailed:self];
					}
				});
			} failureBlock:^(NSError *error) {
				ATLogError(@"Unable to get asset: %@", error);
				[delegate imageResizerFailed:self];
			}];
		}
	});
}
@end
