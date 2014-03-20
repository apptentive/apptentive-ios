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
	BOOL shouldCancel;
}
@synthesize delegate;

- (instancetype)initWithImageAssetURL:(NSURL *)url delegate:(NSObject<ATLargeImageResizerDelegate> *)aDelegate {
	if ((self = [super init])) {
		imageURL = [url copy];
		delegate = aDelegate;
	}
	return self;
}

- (void)dealloc {
	[imageURL release], imageURL = nil;
	[super dealloc];
}

- (void)cancel {
	delegate = nil;
	shouldCancel = YES;
}

- (void)resizeWithMaximumSize:(CGSize)maxSize {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		@autoreleasepool {
			ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
			[assetLibrary assetForURL:imageURL resultBlock:^(ALAsset *asset) {
				ALAssetRepresentation *rep = [asset defaultRepresentation];
				CGImageRef fullscreenImageRef = [rep fullScreenImage];
				if (!fullscreenImageRef) {
					ATLogError(@"Unable to get full screen image representation.");
					[delegate imageResizerFailed:self];
					return;
				}
				UIImage *sourceImage = [UIImage imageWithCGImage:fullscreenImageRef];
				CGSize sourceResolution;
				sourceResolution.width = CGImageGetWidth(sourceImage.CGImage);
				sourceResolution.height = CGImageGetHeight(sourceImage.CGImage);
				if (maxSize.height <= sourceResolution.height && maxSize.width <= sourceResolution.width) {
					[delegate imageResizerDoneResizing:self result:sourceImage];
					return;
				}
				
				CGSize destinationResolution = ATThumbnailSizeOfMaxSize(sourceResolution, maxSize);
				UIImage *image = [ATUtilities imageByScalingImage:sourceImage toSize:destinationResolution scale:1 fromITouchCamera:YES];
				if (image) {
					[delegate imageResizerDoneResizing:self result:image];
				} else {
					[delegate imageResizerFailed:self];
				}
			} failureBlock:^(NSError *error) {
				ATLogError(@"Unable to get asset: %@", error);
				[delegate imageResizerFailed:self];
			}];
		}
	});
}
@end
