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
#import "ATConnect_Private.h"
#import "ATFeedback.h"
#import "ATLargeImageResizer.h"
#import "ATUtilities.h"

#define kATContainerViewTag (5)
#define kATLabelViewTag (6)

@interface ATSimpleImageViewController ()
- (void)chooseImage;
- (void)takePhoto;
- (void)cleanupImageActionSheet;
- (void)dismissImagePickerPopover;
@end

@implementation ATSimpleImageViewController {
	ATLargeImageResizer *imageResizer;
}
@synthesize containerView;

- (id)initWithDelegate:(NSObject<ATSimpleImageViewControllerDelegate> *)aDelegate {
	self = [super initWithNibName:@"ATSimpleImageViewController" bundle:[ATConnect resourceBundle]];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		self.modalPresentationStyle = UIModalPresentationFormSheet;
	}
	if (self != nil) {
		delegate = [aDelegate retain];
	}
	return self;
}

- (void)dealloc {
	if (imageResizer) {
		[imageResizer cancel];
		[imageResizer release], imageResizer = nil;
	}
	[self cleanupImageActionSheet];
	imagePickerPopover.delegate = nil;
	[imagePickerPopover release], imagePickerPopover = nil;
	[delegate release], delegate = nil;
	scrollView.delegate = nil;
	[scrollView removeFromSuperview];
	[scrollView release], scrollView = nil;
	[containerView removeFromSuperview];
	[containerView release], containerView = nil;
	[_activityIndicator release];
	[super dealloc];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle
- (void)viewDidLoad {
	[super viewDidLoad];
	self.activityIndicator.hidden = YES;
	self.navigationItem.title = ATLocalizedString(@"Screenshot", @"Screenshot view title");
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(takePhoto:)] autorelease];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed:)] autorelease];

	if ([ATUtilities osVersionGreaterThanOrEqualTo:@"7.0"] && [[ATConnect sharedConnection] tintColor] && [self.navigationController.navigationBar respondsToSelector:@selector(setTintColor:)]) {
		self.navigationController.navigationBar.tintColor = [[ATConnect sharedConnection] tintColor];
	}
}

- (void)setupScrollView {
	if (scrollView) {
		scrollView.delegate = nil;
		[scrollView removeFromSuperview];
		[scrollView release];
		scrollView = nil;
	}
	
	UIImage *defaultScreenshot = nil;
	if (delegate && [delegate respondsToSelector:@selector(defaultImageForImageViewController:)]) {
		defaultScreenshot = [delegate defaultImageForImageViewController:self];
	}
	if (defaultScreenshot) {
		for (UIView *subview in self.containerView.subviews) {
			if ([subview isEqual:self.activityIndicator]) {
				continue;
			}
			[subview removeFromSuperview];
		}
		
		scrollView = [[ATCenteringImageScrollView alloc] initWithImage:defaultScreenshot];
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
	} else if (!self.activityIndicator.hidden) {
		// We are resizing an image.
		for (UIView *subview in self.containerView.subviews) {
			if ([subview isEqual:self.activityIndicator]) {
				continue;
			}
			[subview removeFromSuperview];
		}
	} else {
		// No image, not resizing.
		UIView *container = nil;
		UILabel *label = nil;
		if ([self.containerView viewWithTag:kATContainerViewTag]) {
			container = [[self.containerView viewWithTag:kATContainerViewTag] retain];
			label = [(UILabel *)[self.containerView viewWithTag:kATLabelViewTag] retain];
		} else {
			container = [[UIView alloc] initWithFrame:self.containerView.bounds];
			container.tag = kATContainerViewTag;
			container.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
			container.backgroundColor = [UIColor blackColor];
			label = [[UILabel alloc] initWithFrame:CGRectZero];
			label.tag = kATLabelViewTag;
			label.backgroundColor = [UIColor clearColor];
			label.font = [UIFont boldSystemFontOfSize:16.0];
			label.textColor = [UIColor whiteColor];
			label.userInteractionEnabled = NO;
			label.textAlignment = NSTextAlignmentCenter;
			label.numberOfLines = 0;
			label.text = ATLocalizedString(@"You can include a screenshot by choosing a photo from your photo library above.\n\nTo take a screenshot, hold down the power and home buttons at the same time.", @"Description of what to do when there is no screenshot.");
		}
		[self.containerView addSubview:container];
		[container sizeToFit];
		[container addSubview:label];
		
		CGFloat labelWidth = container.bounds.size.width - 40.0;
		CGSize labelSize = [label sizeThatFits:CGSizeMake(labelWidth, CGFLOAT_MAX)];
		CGFloat topOffset = floor(labelSize.height/2.0);
		CGRect labelRect = CGRectMake(20, topOffset, labelWidth, labelSize.height);
		label.frame = labelRect;
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
	[super viewDidAppear:animated];
	//NSLog(@"size is: %@", NSStringFromCGRect(self.view.bounds));
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	if (shouldResign) {
		[delegate imageViewControllerWillDismiss:self animated:animated];
		[delegate release], delegate = nil;
	}
}

- (void)viewDidUnload {
	[containerView removeFromSuperview];
	[containerView release], containerView = nil;
	[self setActivityIndicator:nil];
	[super viewDidUnload];
}

- (IBAction)donePressed:(id)sender {
	shouldResign = YES;
	[self cleanupImageActionSheet];
	if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
		id blockSelf = [self retain];
		NSObject<ATSimpleImageViewControllerDelegate> *blockDelegate = [delegate retain];
		[self.navigationController dismissViewControllerAnimated:YES completion:^{
			[blockDelegate imageViewControllerDidDismiss:self];
			[blockSelf release];
			[blockDelegate release];
		}];
	} else {
		[self dismissViewControllerAnimated:YES completion:NULL];
	}
}

- (IBAction)takePhoto:(id)sender {
	ATFeedbackAttachmentOptions options = [delegate attachmentOptionsForImageViewController:self];
	if (options & ATFeedbackAllowTakePhotoAttachment) {
		[self cleanupImageActionSheet];
		[self dismissImagePickerPopover];
		if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
			imageActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:ATLocalizedString(@"Cancel", @"Cancel button title") destructiveButtonTitle:nil otherButtonTitles:ATLocalizedString(@"Choose From Library", @"Choose Photo Button Title"), ATLocalizedString(@"Take Photo", @"Take Photo Button Title"), nil];
		} else {
			imageActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:ATLocalizedString(@"Cancel", @"Cancel button title") destructiveButtonTitle:nil otherButtonTitles:ATLocalizedString(@"Choose From Library", @"Choose Photo Button Title"), nil];
		}
		
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
			[imageActionSheet showFromBarButtonItem:self.navigationItem.leftBarButtonItem animated:YES];
		} else {
			[imageActionSheet showInView:self.view];
		}
	} else {
		[self chooseImage];
	}
}

#pragma mark ATLargeImageResizerDelegate
- (void)imageResizerDoneResizing:(ATLargeImageResizer *)resizer result:(UIImage *)image {
	self.activityIndicator.hidden = YES;
	if (image) {
		[delegate imageViewController:self pickedImage:image fromSource:isFromCamera ? ATFeedbackImageSourceCamera : ATFeedbackImageSourcePhotoLibrary];
	}
	imageResizer.delegate = nil;
	[imageResizer release], imageResizer = nil;
	[self setupScrollView];
}

- (void)imageResizerFailed:(ATLargeImageResizer *)resizer {
	self.activityIndicator.hidden = YES;
	imageResizer.delegate = nil;
	[imageResizer release], imageResizer = nil;
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ATLocalizedString(@"Unable to Use Image", @"Title of unable to use image alert.") message:ATLocalizedString(@"Unable to resize the image you picked.", @"Message of unable to use image alert.") delegate:nil cancelButtonTitle:ATLocalizedString(@"OK", @"OK button title") otherButtonTitles:nil];
	[alert show];
	[alert autorelease];
	[self setupScrollView];
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
		[self chooseImage];
	} else if (buttonIndex == 1 && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		[self takePhoto];
	}
	if (actionSheet && imageActionSheet && [actionSheet isEqual:imageActionSheet]) {
		imageActionSheet.delegate = nil;
		[imageActionSheet release], imageActionSheet = nil;
	}
}

#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	if (imageResizer) {
		[imageResizer cancel];
		[imageResizer release], imageResizer = nil;
	}
	if (delegate) {
		[delegate imageViewControllerVoidedDefaultImage:self];
	}
	
	NSURL *imageURL = [info objectForKey:UIImagePickerControllerReferenceURL];
	UIImage *image = nil;
	if ([info objectForKey:UIImagePickerControllerEditedImage]) {
		image = [info objectForKey:UIImagePickerControllerEditedImage];
	} else if ([info objectForKey:UIImagePickerControllerOriginalImage]) {
		image = [info objectForKey:UIImagePickerControllerOriginalImage];
	}
	imageResizer = [[ATLargeImageResizer alloc] initWithImageAssetURL:imageURL originalImage:image delegate:self];
	self.activityIndicator.hidden = NO;
	[self setupScrollView];
	[self.containerView bringSubviewToFront:self.activityIndicator];
	
	CGSize maxSize = CGSizeMake(1136, 1136);
	if (imagePickerPopover) {
		[imagePickerPopover dismissPopoverAnimated:YES];
		[imageResizer resizeWithMaximumSize:maxSize];
	} else {
		[self dismissViewControllerAnimated:YES completion:^{
			[imageResizer resizeWithMaximumSize:maxSize];
		}];
	}
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[self dismissImagePickerPopover];
	
#	pragma clang diagnostic push
#	pragma clang diagnostic ignored "-Wdeprecated-declarations"
	if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)] && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		[self dismissViewControllerAnimated:YES completion:^{
			// pass
		}];
	} else if (self.modalViewController) {
		[self.navigationController dismissViewControllerAnimated:YES completion:NULL];
	}
#	pragma clang diagnostic pop
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
		imagePickerPopover.delegate = nil;
		[imagePickerPopover release], imagePickerPopover = nil;
	}
}

#pragma mark Private
- (void)chooseImage {
	isFromCamera = NO;
	shouldResign = NO;
	UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
	imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	imagePicker.delegate = self;
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		if (imagePickerPopover) {
			imagePickerPopover.delegate = nil;
			[imagePickerPopover dismissPopoverAnimated:NO];
			[imagePickerPopover release], imagePickerPopover = nil;
		}
		imagePickerPopover = [[UIPopoverController alloc] initWithContentViewController:imagePicker];
		imagePickerPopover.delegate = self;

		/*! Fix for iPad crash when authenticating Photo access via UIImagePickerController in a UIPopoverControl from a UIBarButtonItem.
		 http://stackoverflow.com/questions/18939537/uiimagepickercontroller-crash-only-on-ios-7-ipad
		 http://openradar.appspot.com/radar?id=6369788687286272
		 TODO: move back to `presentPopoverFromBarButtonItem:` when crash has been fixed in iOS.
		*/
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad && [ATUtilities osVersionGreaterThanOrEqualTo:@"7.0"]) {
			[imagePickerPopover presentPopoverFromRect:self.view.frame inView:self.view permittedArrowDirections:0 animated:YES];
		} else {
			[imagePickerPopover presentPopoverFromBarButtonItem:self.navigationItem.leftBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		}
	} else {
		[self presentViewController:imagePicker animated:YES completion:NULL];
	}
	[imagePicker release];
}

- (void)takePhoto {
	isFromCamera = YES;
	shouldResign = NO;
	
	[self dismissImagePickerPopover];
	UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
	imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
	imagePicker.delegate = self;
	[self presentViewController:imagePicker animated:YES completion:NULL];
	[imagePicker release];
}

- (void)cleanupImageActionSheet {
	if (imageActionSheet) {
		imageActionSheet.delegate = nil;
		[imageActionSheet dismissWithClickedButtonIndex:-1 animated:NO];
		[imageActionSheet release], imageActionSheet = nil;
	}
}

- (void)dismissImagePickerPopover {
	if (imagePickerPopover) {
		[imagePickerPopover dismissPopoverAnimated:YES];
	}
}
@end
