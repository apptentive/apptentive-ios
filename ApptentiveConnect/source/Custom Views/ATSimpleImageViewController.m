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
#import "ATFeedbackController.h"

NSString * const ATImageViewChoseImage = @"ATImageViewChoseImage";

@interface ATSimpleImageViewController (Private)
- (void)chooseImage;
- (void)takePhoto;
@end

@implementation ATSimpleImageViewController
@synthesize containerView;
@synthesize cameraButtonItem;

- (id)initWithFeedback:(ATFeedback *)someFeedback feedbackController:(ATFeedbackController *)aController {
	self = [super initWithNibName:@"ATSimpleImageViewController" bundle:[ATConnect resourceBundle]];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		self.modalPresentationStyle = UIModalPresentationFormSheet;
	}
	if (self != nil) {
		feedback = [someFeedback retain];
		controller = [aController retain];
	}
	return self;
}

- (void)dealloc {
	[imagePickerPopover release], imagePickerPopover = nil;
	[controller release], controller = nil;
	[feedback release];
	feedback = nil;
	[scrollView removeFromSuperview];
	[scrollView release];
	scrollView = nil;
	[containerView removeFromSuperview];
	[containerView release], containerView = nil;
	[cameraButtonItem release], cameraButtonItem = nil;
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
		for (UIView *subview in self.containerView.subviews) {
			[subview removeFromSuperview];
		}
		scrollView = [[ATCenteringImageScrollView alloc] initWithImage:feedback.screenshot];
		scrollView.backgroundColor = [UIColor blackColor];
		CGSize boundsSize = self.containerView.bounds.size;
		CGSize imageSize = [scrollView imageView].image.size;
		
		CGFloat xScale = boundsSize.width / imageSize.width;
		CGFloat yScale = boundsSize.height / imageSize.height;
		CGFloat minScale = MIN(xScale, yScale);
		CGFloat maxScale = 2.0;
		
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
		scrollView.frame = self.containerView.bounds;
		[self.containerView addSubview:scrollView];
	} else {
		UIView *container = [[UIView alloc] initWithFrame:self.containerView.bounds];
		container.backgroundColor = [UIColor blackColor];
		UITextView *label = [[UITextView alloc] initWithFrame:CGRectZero];
		label.backgroundColor = [UIColor clearColor];
		label.font = [UIFont boldSystemFontOfSize:16.0];
		label.textColor = [UIColor whiteColor];
		label.userInteractionEnabled = NO;
		label.textAlignment = UITextAlignmentCenter;
		label.text = ATLocalizedString(@"You can include a screenshot by choosing a photo from your photo library above.\n\nTo take a screenshot, hold down the power and home buttons at the same time.", @"Description of what to do when there is no screenshot.");
		[self.containerView addSubview:container];
		[container sizeToFit];
		[container addSubview:label];
		label.frame = CGRectInset(container.bounds, 20.0, 100.0);
		label.center = container.center;
		[label release];
		[container release];
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self setupScrollView];
}

- (void)viewDidAppear:(BOOL)animated {
	//NSLog(@"size is: %@", NSStringFromCGRect(self.view.bounds));
}

- (void)viewWillDisappear:(BOOL)animated {
	if (controller != nil && shouldResign == YES) {
		[controller unhide:animated];
		[controller release], controller = nil;
	}
}

- (void)viewDidUnload {
	[containerView removeFromSuperview];
	[containerView release], containerView = nil;
	[self setCameraButtonItem:nil];
	[super viewDidUnload];
}

- (IBAction)donePressed:(id)sender {
	shouldResign = YES;
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)takePhoto:(id)sender {
	if (controller.attachmentOptions & ATFeedbackAllowTakePhotoAttachment) {
		UIActionSheet *actionSheet = nil;
		if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
			actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:ATLocalizedString(@"Cancel", @"Cancel Button Title") destructiveButtonTitle:nil otherButtonTitles:ATLocalizedString(@"Choose From Library", @"Choose Photo Button Title"), ATLocalizedString(@"Take Photo", @"Take Photo Button Title"), nil];
		} else {
			actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:ATLocalizedString(@"Cancel", @"Cancel Button Title") destructiveButtonTitle:nil otherButtonTitles:ATLocalizedString(@"Choose From Library", @"Choose Photo Button Title"), nil];
		}
		
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
			[actionSheet showFromBarButtonItem:self.cameraButtonItem animated:YES];
		} else {
			[actionSheet showInView:self.view];
		}
		[actionSheet autorelease];
	} else {
		[self chooseImage];
	}
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
		[self chooseImage];
	} else if (buttonIndex == 1 && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		[self takePhoto];
	}
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
		feedback.imageSource = isFromCamera ? ATFeedbackImageSourceCamera : ATFeedbackImageSourcePhotoLibrary;
		feedback.screenshot = image;
		[[NSNotificationCenter defaultCenter] postNotificationName:ATImageViewChoseImage object:self];
	}
	[self setupScrollView];
	
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		if (imagePickerPopover) {
			[imagePickerPopover dismissPopoverAnimated:YES];
		}
	}
	if (self.modalViewController) {
		[self dismissModalViewControllerAnimated:YES];
	}
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

#pragma mark UIPopoverControllerDelegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	if (popoverController == imagePickerPopover) {
		[imagePickerPopover release], imagePickerPopover = nil;
	}
}
@end

@implementation ATSimpleImageViewController (Private)
- (void)chooseImage {
	isFromCamera = NO;
	shouldResign = NO;
	UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
	imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	imagePicker.delegate = self;
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		if (imagePickerPopover) {
			[imagePickerPopover dismissPopoverAnimated:NO];
			[imagePickerPopover release], imagePickerPopover = nil;
		}
		imagePickerPopover = [[UIPopoverController alloc] initWithContentViewController:imagePicker];
		imagePickerPopover.delegate = self;
		[imagePickerPopover presentPopoverFromBarButtonItem:self.cameraButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	} else {
		[self presentModalViewController:imagePicker animated:YES];
	}
	[imagePicker release];
}

- (void)takePhoto {
	isFromCamera = YES;
	shouldResign = NO;
	UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
	imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
	imagePicker.delegate = self;
	[self presentModalViewController:imagePicker animated:YES];
	[imagePicker release];
}
@end
