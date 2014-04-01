//
//  ATLargeImageResizer.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/19/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ATLargeImageResizerDelegate;

/*! A helper class for resizing images from the Asset Library. */
@interface ATLargeImageResizer : NSObject
@property (nonatomic, assign) NSObject<ATLargeImageResizerDelegate> *delegate;
- (instancetype)initWithImageAssetURL:(NSURL *)url originalImage:(UIImage *)originalImage delegate:(NSObject<ATLargeImageResizerDelegate> *)delegate;
- (void)cancel;
- (void)resizeWithMaximumSize:(CGSize)size;
@end


@protocol ATLargeImageResizerDelegate <NSObject>
- (void)imageResizerDoneResizing:(ATLargeImageResizer *)resizer result:(UIImage *)image;
- (void)imageResizerFailed:(ATLargeImageResizer *)resizer;
@end
