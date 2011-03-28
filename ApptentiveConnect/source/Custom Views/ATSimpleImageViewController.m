//
//  ATSimpleImageViewController.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/27/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import "ATSimpleImageViewController.h"
#import "ATCenteringImageScrollView.h"

@implementation ATSimpleImageViewController

- (id)initWithImage:(UIImage *)image {
    if ((self = [super init])) {
        scrollView = [[ATCenteringImageScrollView alloc] initWithImage:image];
        scrollView.backgroundColor = [UIColor blackColor];
    }
    return self;
}

- (void)dealloc {
    [scrollView removeFromSuperview];
    [scrollView release];
    scrollView = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle
- (void)setupScrollView {
    CGSize boundsSize = scrollView.bounds.size;
    CGSize imageSize = [scrollView imageView].image.size;
    
    CGFloat xScale = boundsSize.width / imageSize.width;
    CGFloat yScale = boundsSize.height / imageSize.height;
    CGFloat minScale = MIN(xScale, yScale);
    CGFloat maxScale = 1.0 / [[UIScreen mainScreen] scale];
    
    if (minScale > maxScale) {
        minScale = maxScale;
    }
    scrollView.delegate = self;
    scrollView.bounces = YES;
    scrollView.bouncesZoom = YES;
    scrollView.minimumZoomScale = minScale;
    scrollView.maximumZoomScale = maxScale;
    scrollView.alwaysBounceHorizontal = YES;
    scrollView.alwaysBounceVertical = YES;
    
    [scrollView setZoomScale:minScale]; 
}

- (void)loadView {
    self.view = scrollView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupScrollView];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

#pragma mark Rotation
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self setupScrollView];
}

#pragma mark UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)aScrollView {
    return [scrollView imageView];
}
@end
