//
//  ApptentiveNetworkImageView.m
//  Apptentive
//
//  Created by Andrew Wooster on 4/17/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveNetworkImageView.h"
#import "ApptentiveBackend.h"
#import "Apptentive_Private.h"

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveNetworkImageView ()

@property (nullable, strong, nonatomic) NSURLSessionDataTask *task;

@end


@implementation ApptentiveNetworkImageView

- (void)dealloc {
	[_task cancel];
}

- (void)restartDownload {
	if (self.task) {
		[self.task cancel];
		self.task = nil;
	}

	if (self.imageURL) {
		self.task = [[NSURLSession sharedSession] dataTaskWithURL:self.imageURL
												completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
												  if (data == nil) {
													  ApptentiveLogError(@"Unable to download image at %@: %@", self.imageURL, error);
													  self.task = nil;

													  if ([self.delegate respondsToSelector:@selector(networkImageView:didFailWithError:)]) {
														  dispatch_async(dispatch_get_main_queue(), ^{
															[self.delegate networkImageView:self didFailWithError:error];
														  });
													  }
												  } else {
													  UIImage *newImage = [UIImage imageWithData:data];
													  if (newImage) {
														  dispatch_async(dispatch_get_main_queue(), ^{
															self.image = newImage;
														  });
													  }
												  }
												}];

		[self.task resume];
	}
}

- (void)setImageURL:(NSURL *)anImageURL {
	if (_imageURL != anImageURL || self.image == nil) {
		_imageURL = [anImageURL copy];
		[self restartDownload];
	}
}

@end

NS_ASSUME_NONNULL_END
