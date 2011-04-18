//
//  ATSimpleImageViewController.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/27/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATSimpleImageViewController.h"
#import "ATCenteringImageScrollView.h"
#import "ATConnect.h"
#import "ATFeedback.h"

NSString * const ATImageViewChoseImage = @"ATImageViewChoseImage";

@implementation ATSimpleImageViewController

- (id)initWithFeedback:(ATFeedback *)someFeedback {
    if ((self = [super init])) {
		feedback = [someFeedback retain];
		self.view = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
    }
    return self;
}

- (void)dealloc {
	[feedback release];
	feedback = nil;
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
	if (scrollView) {
		[scrollView removeFromSuperview];
		[scrollView release];
		scrollView = nil;
	}
	if (feedback.screenshot) {
		for (UIView *subview in self.view.subviews) {
			[subview removeFromSuperview];
		}
		scrollView = [[ATCenteringImageScrollView alloc] initWithImage:feedback.screenshot];
		scrollView.backgroundColor = [UIColor blackColor];
		CGSize boundsSize = self.view.bounds.size;
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
		scrollView.frame = self.view.bounds;
		[self.view addSubview:scrollView];
	} else {
		UIView *container = [[UIView alloc] initWithFrame:self.view.bounds];
		container.backgroundColor = [UIColor blackColor];
		UITextView *label = [[UITextView alloc] initWithFrame:CGRectZero];
		label.backgroundColor = [UIColor clearColor];
		label.font = [UIFont boldSystemFontOfSize:16.0];
		label.textColor = [UIColor whiteColor];
		label.userInteractionEnabled = NO;
		label.textAlignment = UITextAlignmentCenter;
		label.text = ATLocalizedString(@"You can include a screenshot by choosing a photo from your photo library above.\n\nTo take a screenshot, hold down the power and home buttons at the same time.", @"Description of what to do when there is no screenshot.");
		[self.view addSubview:container];
		[container sizeToFit];
		[container addSubview:label];
		label.frame = CGRectInset(container.bounds, 20.0, 100.0);
		label.center = container.center;
		[label release];
		[container release];
	}
}

- (void)loadView {
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupScrollView];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(takePhoto:)] autorelease];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)takePhoto:(id)sender {
	UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
	imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	imagePicker.delegate = self;
	[self.navigationController presentModalViewController:imagePicker animated:YES];
	[imagePicker release];
}

#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	UIImage *image = nil;
	if ([info objectForKey:UIImagePickerControllerEditedImage]) {
		image = [info objectForKey:UIImagePickerControllerEditedImage];
	} else if ([info objectForKey:UIImagePickerControllerOriginalImage]) {
		image = [info objectForKey:UIImagePickerControllerOriginalImage];
	}
	if (image) {
		feedback.screenshot = image;
		[[NSNotificationCenter defaultCenter] postNotificationName:ATImageViewChoseImage object:self];
	}
    [self setupScrollView];
	[picker dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[picker dismissModalViewControllerAnimated:YES];
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
