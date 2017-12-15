//
//  ApptentiveAttachmentController.m
//  Apptentive
//
//  Created by Frank Schmitt on 10/9/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveAttachmentController.h"
#import "ApptentiveAttachButton.h"
#import "ApptentiveAttachment.h"
#import "ApptentiveAttachmentCell.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveMessageCenterViewController.h"
#import "Apptentive_Private.h"
#import "ApptentiveBackend+Engagement.h"

NS_ASSUME_NONNULL_BEGIN

#define MAX_NUMBER_OF_ATTACHMENTS 4
#define ATTACHMENT_MARGIN CGSizeMake(16.0, 15.0)
#define ATTACHMENT_INSET UIEdgeInsetsMake(8, 8, 8, 8)

NSString *const ATMessageCenterAttachmentsArchiveFilename = @"DraftAttachments";

NSString *const ATInteractionMessageCenterEventLabelAttachmentListOpen = @"attachment_list_open";
NSString *const ATInteractionMessageCenterEventLabelAttachmentAdd = @"attachment_add";
NSString *const ATInteractionMessageCenterEventLabelAttachmentCancel = @"attachment_cancel";
NSString *const ATInteractionMessageCenterEventLabelAttachmentDelete = @"attachment_delete";


@interface ApptentiveAttachmentController ()

@property (nullable, weak, nonatomic) UIPopoverPresentationController *imagePickerPopoverController;
@property (strong, nonatomic) NSMutableArray *mutableAttachments;
@property (assign, nonatomic) CGSize collectionViewFooterSize;
@property (strong, nonatomic) NSNumberFormatter *numberFormatter;

@end


@implementation ApptentiveAttachmentController

@synthesize active = _active;
@synthesize attachments = _attachments;

- (void)viewDidLoad {
	self.collectionView.layer.shadowOpacity = 1.0;
	self.collectionView.layer.shadowRadius = 1.0 / [UIScreen mainScreen].scale;
	self.collectionView.layer.shadowOffset = CGSizeMake(0.0, -1.0 / [UIScreen mainScreen].scale);
	self.collectionView.layer.masksToBounds = NO;
	self.collectionView.layer.shadowColor = [[Apptentive sharedConnection].style colorForStyle:ApptentiveColorSeparator].CGColor;

	// Hide the attach button if tapping it will cause a crash (due to unsupported portrait orientation).
	BOOL isPhone = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone;
	BOOL supportsPortraitOrientation = ([[UIApplication sharedApplication] supportedInterfaceOrientationsForWindow:self.attachButton.window] & UIInterfaceOrientationMaskPortrait) != 0;
	BOOL requiresPhotoLibraryUsageDescription = [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10, 0, 0}];
	BOOL hasPhotoLibraryUsageDescription = [[NSBundle mainBundle].infoDictionary objectForKey:@"NSPhotoLibraryUsageDescription"] != nil;

	self.attachButton.hidden = (isPhone && !supportsPortraitOrientation) || (requiresPhotoLibraryUsageDescription && !hasPhotoLibraryUsageDescription);

	CGSize marginWithInsets = CGSizeMake(ATTACHMENT_MARGIN.width - (ATTACHMENT_INSET.left), ATTACHMENT_MARGIN.height - (ATTACHMENT_INSET.top));
	CGFloat height = [ApptentiveAttachmentCell heightForScreen:[UIScreen mainScreen] withMargin:marginWithInsets];
	CGFloat bottomY = CGRectGetMaxY(self.collectionView.frame);
	self.collectionView.frame = CGRectMake(self.collectionView.frame.origin.x, bottomY - height, self.collectionView.frame.size.width, height);

	UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
	layout.sectionInset = UIEdgeInsetsMake(ATTACHMENT_MARGIN.height - ATTACHMENT_INSET.top, ATTACHMENT_MARGIN.width - ATTACHMENT_INSET.left, ATTACHMENT_MARGIN.height - ATTACHMENT_INSET.bottom, ATTACHMENT_MARGIN.width - ATTACHMENT_INSET.right);
	layout.minimumInteritemSpacing = ATTACHMENT_MARGIN.width;
	layout.itemSize = [ApptentiveAttachmentCell sizeForScreen:[UIScreen mainScreen] withMargin:marginWithInsets];

	[self willChangeValueForKey:@"attachments"];
	self.mutableAttachments = [NSKeyedUnarchiver unarchiveObjectWithFile:self.archivePath];

	if (![self.mutableAttachments isKindOfClass:[NSMutableArray class]]) {
		self.mutableAttachments = [NSMutableArray array];
	}
	[self didChangeValueForKey:@"attachments"];

	self.collectionViewFooterSize = ((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).footerReferenceSize;
	self.collectionView.backgroundColor = [[Apptentive sharedConnection].style colorForStyle:ApptentiveColorBackground];

	self.numberFormatter = [[NSNumberFormatter alloc] init];

	[self updateBadge];
}

- (void)saveDraft {
	[NSKeyedArchiver archiveRootObject:self.mutableAttachments toFile:self.archivePath];
}

- (nullable UIResponder *)nextResponder {
	return self.viewController;
}

- (nullable NSArray<ApptentiveAttachment *> *)attachments {
	if (_attachments == nil) {
		NSMutableArray *attachments = [NSMutableArray array];
		NSInteger index = 1;

		for (UIImage *image in self.mutableAttachments) {
			NSString *numberString = [self.numberFormatter stringFromNumber:@(index)];

			// TODO: Localize this once server can accept non-ASCII filenames
			NSString *name = [NSString stringWithFormat:@"Attachment %@", numberString];
			ApptentiveAttachment *attachment = [[ApptentiveAttachment alloc] initWithData:UIImageJPEGRepresentation(image, 0.6) contentType:@"image/jpeg" name:name attachmentDirectoryPath:self.viewController.viewModel.messageManager.attachmentDirectoryPath];

			index++;
			ApptentiveAssertNotNil(attachment, @"Attachment is nil");
			if (attachment != nil) {
				[attachments addObject:attachment];
			}
		}
		_attachments = attachments;
	}

	return _attachments;
}

- (BOOL)canBecomeFirstResponder {
	return YES;
}

- (nullable UIView *)inputView {
	return self.collectionView;
}

- (void)clear {
	[self willChangeValueForKey:@"attachments"];
	[self.mutableAttachments removeAllObjects];
	_attachments = nil;
	[self didChangeValueForKey:@"attachments"];

	[self updateBadge];
	[self saveDraft];
}

#pragma mark - Actions

- (IBAction)showAttachments:(UIButton *)sender {
	if ((self.active || self.mutableAttachments.count == 0) && self.mutableAttachments.count < MAX_NUMBER_OF_ATTACHMENTS) {
		[self chooseImage:sender];
	} else {
		[Apptentive.shared.backend engage:ATInteractionMessageCenterEventLabelAttachmentListOpen
						  fromInteraction:self.viewController.viewModel.interaction
					   fromViewController:self.viewController];
		[self becomeFirstResponder];
		[self updateBadge];

		self.active = YES;
	}
}

- (IBAction)chooseImage:(UIButton *)sender {
	[self displayImagePickerControllerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary sender:sender];
}

- (IBAction)deleteImage:(UIButton *)sender {
	UICollectionViewCell *cell = (UICollectionViewCell *)sender.superview.superview;
	NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
	ApptentiveAssertNotNil(indexPath, @"Index path is nil for cell: %@", cell);
	if (indexPath == nil) {
		return;
	}

	[self willChangeValueForKey:@"attachments"];
	[self.mutableAttachments removeObjectAtIndex:indexPath.item];
	_attachments = nil;
	[self didChangeValueForKey:@"attachments"];

	[Apptentive.shared.backend engage:ATInteractionMessageCenterEventLabelAttachmentDelete
					  fromInteraction:self.viewController.viewModel.interaction
				   fromViewController:self.viewController];

	[self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
	[self updateBadge];
}

#pragma mark - Collection view data source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return self.mutableAttachments.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	ApptentiveAttachmentCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Attachment" forIndexPath:indexPath];

	cell.imageView.image = [self.mutableAttachments objectAtIndex:indexPath.item];
	cell.usePlaceholder = NO;

	return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	if (kind == UICollectionElementKindSectionFooter) {
		return [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Add" forIndexPath:indexPath];
	} else {
		// Should never get here (prevents analyzer warning).
		return [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"" forIndexPath:indexPath];
	}
}

#pragma mark Collection view delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	QLPreviewController *previewController = [[QLPreviewController alloc] init];
	previewController.dataSource = self;
	previewController.currentPreviewItemIndex = indexPath.item;

	[self.viewController.navigationController pushViewController:previewController animated:YES];
}

#pragma mark - Image picker controller delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	UIImage *photo = info[UIImagePickerControllerOriginalImage];
	if (photo) {
		[self insertImage:photo];
	} else {
		ApptentiveLogError(@"Unable to get photo");
	}

	[self dismissImagePicker:picker];

	if (!self.active) {
		[self becomeFirstResponder];
		self.active = YES;
		[Apptentive.shared.backend engage:ATInteractionMessageCenterEventLabelAttachmentListOpen
						  fromInteraction:self.viewController.viewModel.interaction
					   fromViewController:self.viewController];
	}

	[Apptentive.shared.backend engage:ATInteractionMessageCenterEventLabelAttachmentAdd
					  fromInteraction:self.viewController.viewModel.interaction
				   fromViewController:self.viewController];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[self dismissImagePicker:picker];
	[Apptentive.shared.backend engage:ATInteractionMessageCenterEventLabelAttachmentCancel
					  fromInteraction:self.viewController.viewModel.interaction
				   fromViewController:self.viewController];
}

#pragma mark - Private

- (void)updateBadge {
	self.attachButton.badgeValue = self.mutableAttachments.count;

	((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).footerReferenceSize = self.mutableAttachments.count < MAX_NUMBER_OF_ATTACHMENTS ? self.collectionViewFooterSize : CGSizeZero;
}

- (NSString *)archivePath {
	return [[Apptentive sharedConnection].backend.supportDirectoryPath stringByAppendingPathComponent:ATMessageCenterAttachmentsArchiveFilename];
}

- (void)insertImage:(UIImage *)image {
	[self willChangeValueForKey:@"attachments"];
	ApptentiveArrayAddObject(self.mutableAttachments, image);
	_attachments = nil;
	[self didChangeValueForKey:@"attachments"];

	[self.collectionView reloadData];

	[self updateBadge];
}

- (void)dismissImagePicker:(UIImagePickerController *)imagePicker {
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		[self.imagePickerPopoverController.presentedViewController dismissViewControllerAnimated:YES completion:nil];
		self.imagePickerPopoverController = nil;
	} else {
		[self.viewController.navigationController dismissViewControllerAnimated:YES completion:nil];
	}
}

- (void)displayImagePickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType sender:(UIButton *)sender {
	UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];

	imagePicker.delegate = self;
	imagePicker.sourceType = sourceType;
	imagePicker.allowsEditing = NO;

	if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		imagePicker.modalPresentationStyle = UIModalPresentationPopover;

		self.imagePickerPopoverController = imagePicker.popoverPresentationController;
		self.imagePickerPopoverController.sourceRect = (sender == self.attachButton) ? self.attachButton.frame : sender.superview.frame;
		self.imagePickerPopoverController.sourceView = (sender == self.attachButton) ? self.attachButton.superview : self.collectionView;
	}

	[self.viewController.navigationController presentViewController:imagePicker animated:YES completion:nil];
}

@end


@implementation ApptentiveAttachmentController (QuickLook)

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
	return self.attachments.count;
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
	return [self.attachments objectAtIndex:index];
}

@end

NS_ASSUME_NONNULL_END
