//
//  ATNetworkImageView.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 4/17/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATNetworkImageView.h"

#import "ATBackend.h"

@implementation ATNetworkImageView {
	NSURLConnection *connection;
	NSMutableData *imageData;
}
@synthesize imageURL;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
		self.useCache = YES;
    }
    return self;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	self.useCache = YES;
}

- (void)dealloc {
    [connection cancel];
    [connection release], connection = nil;
	[imageURL release], imageURL = nil;
    [imageData release], imageData = nil;
	[super dealloc];
}

- (void)restartDownload {
	if (connection) {
		[connection cancel];
		[connection release], connection = nil;
	}
	if (self.imageURL) {
		NSURLRequest *request = [NSURLRequest requestWithURL:self.imageURL];
		
		NSURLCache *cache = [[ATBackend sharedBackend] imageCache];
		BOOL cacheHit = NO;
		if (cache) {
			NSCachedURLResponse *cachedResponse = [cache cachedResponseForRequest:request];
			if (cachedResponse && self.useCache) {
				UIImage *i = [UIImage imageWithData:cachedResponse.data];
				if (i) {
					self.image = i;
					cacheHit = YES;
				}
			}
		}
		
		if (!cacheHit) {
			connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
			[connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
			[connection start];
		}
	}
}

- (void)setImageURL:(NSURL *)anImageURL {
	if (imageURL != anImageURL) {
		[imageURL release], imageURL = nil;
		imageURL = [anImageURL copy];
		[self restartDownload];
	}
}

#pragma mark NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error {
    if (aConnection == connection) {
        ATLogError(@"Unable to download image at %@: %@", self.imageURL, error);
        [connection release], connection = nil;
    }
}

#pragma mark NSURLConnectionDataDelegate
- (void)connection:(NSURLConnection *)aConnection didReceiveResponse:(NSURLResponse *)response {
    if (aConnection == connection) {
        if (imageData) {
            [imageData release], imageData = nil;
        }
        imageData = [[NSMutableData alloc] init];
    }
}

- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)data {
    if (aConnection == connection) {
        [imageData appendData:data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {
    if (connection == aConnection) {
        UIImage *newImage = [UIImage imageWithData:imageData];
        if (newImage) {
            self.image = newImage;
        }
    }
}
@end
