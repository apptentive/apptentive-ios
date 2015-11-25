//
//  ATAttachmentController.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 10/9/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import "ATAttachmentController.h"
#import "ATAttachmentCell.h"
#import "ATAttachButton.h"
#import "ATMessageCenterViewController.h"
#import "ATMessageCenterInteraction.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "ATConnect_Private.h"

#define MAX_NUMBER_OF_ATTACHMENTS 4
#define ATTACHMENT_MARGIN CGSizeMake(16.0, 15.0)
#define ATTACHMENT_INSET UIEdgeInsetsMake(8, 8, 8, 8)

NSString *const ATMessageCenterAttachmentsArchiveFilename = @"DraftAttachments";

NSString *const ATInteractionMessageCenterEventLabelAttachmentListOpen = @"attachment_list_open";
NSString *const ATInteractionMessageCenterEventLabelAttachmentAdd = @"attachment_add";
NSString *const ATInteractionMessageCenterEventLabelAttachmentCancel = @"attachment_cancel";
NSString *const ATInteractionMessageCenterEventLabelAttachmentDelete = @"attachment_delete";

@interface ATAttachmentController ()

@property (nonatomic, strong) UIPopoverController *imagePickerPopoverController;
@property (strong, nonatomic) NSMutableArray *mutableAttachments;
@property (assign, nonatomic) CGSize collectionViewFooterSize;

@end

@implementation ATAttachmentController

@synthesize active = _active;
@synthesize attachments = _attachments;

- (void)viewDidLoad {
	self.collectionView.layer.shadowOpacity = 0.5;
	self.collectionView.layer.shadowRadius = 2.0;
	self.collectionView.layer.masksToBounds = NO;
	self.collectionView.layer.shadowColor = [UIColor grayColor].CGColor;

	CGSize marginWithInsets = CGSizeMake(ATTACHMENT_MARGIN.width - (ATTACHMENT_INSET.left), ATTACHMENT_MARGIN.height - (ATTACHMENT_INSET.top));
	CGFloat height = [ATAttachmentCell heightForScreen:[UIScreen mainScreen] withMargin:marginWithInsets];
	CGFloat bottomY = CGRectGetMaxY(self.collectionView.frame);
	self.collectionView.frame = CGRectMake(self.collectionView.frame.origin.x, bottomY - height, self.collectionView.frame.size.width, height);

	UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
	layout.sectionInset = UIEdgeInsetsMake(ATTACHMENT_MARGIN.height - ATTACHMENT_INSET.top, ATTACHMENT_MARGIN.width - ATTACHMENT_INSET.left, ATTACHMENT_MARGIN.height - ATTACHMENT_INSET.bottom, ATTACHMENT_MARGIN.width - ATTACHMENT_INSET.right);
	layout.minimumInteritemSpacing = ATTACHMENT_MARGIN.width;
	layout.itemSize = [ATAttachmentCell sizeForScreen:[UIScreen mainScreen] withMargin:marginWithInsets];

	[self willChangeValueForKey:@"attachments"];
	self.mutableAttachments = [NSKeyedUnarchiver unarchiveObjectWithFile:self.archivePath];

	if (![self.mutableAttachments isKindOfClass:[NSMutableArray class]]) {
		self.mutableAttachments = [NSMutableArray array];
	}
	[self didChangeValueForKey:@"attachments"];

	self.collectionViewFooterSize = ((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).footerReferenceSize;

	[self updateBadge];
}

- (void)saveDraft {
	[NSKeyedArchiver archiveRootObject:self.mutableAttachments toFile:self.archivePath];
}

- (UIResponder *)nextResponder {
	return self.viewController;
}

- (NSArray<ATFileAttachment *> *)attachments {
	if (_attachments == nil) {
		NSMutableArray *attachments = [NSMutableArray array];
		NSInteger index = 1;

		for (UIImage *image in self.mutableAttachments) {
			NSString *name = [NSString stringWithFormat:ATLocalizedString(@"Attachment %ld", @"Placeholder name for attachment"), (long)index];
			ATFileAttachment *attachment = [ATFileAttachment newInstanceWithFileData:UIImageJPEGRepresentation(image, 0.6) MIMEType:@"image/jpeg"name:name];

			index ++;
			[attachments addObject:attachment];
		}
		_attachments = attachments;
	}

	return _attachments;
}

- (BOOL)canBecomeFirstResponder {
	return YES;
}

- (UIView *)inputView {
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
		[self.viewController.interaction engage:ATInteractionMessageCenterEventLabelAttachmentListOpen fromViewController:self.viewController];
		[self becomeFirstResponder];
		[self updateBadge];
	}

	self.active = YES;
}

- (IBAction)chooseImage:(UIButton *)sender {
	[self displayImagePickerControllerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary sender:sender];
}

- (IBAction)deleteImage:(UIButton *)sender {
	UICollectionViewCell *cell = (UICollectionViewCell *)sender.superview.superview;
	NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];

	[self willChangeValueForKey:@"attachments"];
	[self.mutableAttachments removeObjectAtIndex:indexPath.item];
	_attachments = nil;
	[self didChangeValueForKey:@"attachments"];

	[self.viewController.interaction engage:ATInteractionMessageCenterEventLabelAttachmentDelete fromViewController:self.viewController];

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
	ATAttachmentCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Attachment" forIndexPath:indexPath];

	cell.imageView.image = [self.mutableAttachments objectAtIndex:indexPath.item];
	cell.usePlaceholder = NO;

	return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	if (kind == UICollectionElementKindSectionFooter) {
		return [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Add" forIndexPath:indexPath];
	}

	return nil;
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
	NSURL *referenceURL = [info objectForKey:UIImagePickerControllerReferenceURL];

	if (referenceURL) { // Copy existing photo from asset library
		ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];

		[assetLibrary assetForURL:referenceURL resultBlock:^(ALAsset *asset) {
			ALAssetRepresentation *representation = asset.defaultRepresentation;
			CGImageRef CGImage = representation.fullScreenImage ?: representation.fullResolutionImage;
			UIImage *image = [UIImage imageWithCGImage:CGImage];

			if (image) {
				[self insertImage:image];
			} else {
				ATLogError(@"Unable to get suitable image from asset representation: %@", representation);
			}
		} failureBlock:^(NSError *error) {
			ATLogError(@"Unable to copy asset");
		}];
	} else { // Save newly-taken photo
		UIImage *photo = info[UIImagePickerControllerOriginalImage];
		[self insertImage:photo];
	}

	[self dismissImagePicker:picker];
	[self.viewController.interaction engage:ATInteractionMessageCenterEventLabelAttachmentAdd fromViewController:self.viewController];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[self dismissImagePicker:picker];
	[self.viewController.interaction engage:ATInteractionMessageCenterEventLabelAttachmentCancel fromViewController:self.viewController];
}

#pragma mark - Private

- (void)updateBadge {
	self.attachButton.badgeValue = self.mutableAttachments.count;

	((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).footerReferenceSize = self.mutableAttachments.count < MAX_NUMBER_OF_ATTACHMENTS ? self.collectionViewFooterSize : CGSizeZero;
}

- (NSString *)archivePath {
	return [[ATBackend sharedBackend].supportDirectoryPath stringByAppendingPathComponent:ATMessageCenterAttachmentsArchiveFilename];
}

- (void)insertImage:(UIImage *)image {
	[self willChangeValueForKey:@"attachments"];
	[self.mutableAttachments addObject:image];
	_attachments = nil;
	[self didChangeValueForKey:@"attachments"];

	[self.collectionView reloadData];

	[self updateBadge];
}

- (void)dismissImagePicker:(UIImagePickerController *)imagePicker {
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		[self.imagePickerPopoverController dismissPopoverAnimated:YES];
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

	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		self.imagePickerPopoverController = [[UIPopoverController alloc] initWithContentViewController:imagePicker];
		self.imagePickerPopoverController.delegate = self;

		[self.imagePickerPopoverController presentPopoverFromRect:sender.superview.frame inView:self.collectionView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	} else {
		imagePicker.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

		[self.viewController.navigationController presentViewController:imagePicker animated:YES completion:nil];
	}
}

@end

@implementation ATAttachmentController (QuickLook)

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
	return self.attachments.count;
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
	return [self.attachments objectAtIndex:index];
}

@end
