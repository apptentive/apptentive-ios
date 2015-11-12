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
#import <AssetsLibrary/AssetsLibrary.h>

#define MAX_NUMBER_OF_ATTACHMENTS 4
#define ATTACHMENT_MARGIN CGSizeMake(16.0, 15.0)
#define ATTACHMENT_INSET UIEdgeInsetsMake(8, 8, 8, 8)

NSString *const ATMessageCenterAttachmentsArchiveFilename = @"DraftAttachments";

@interface ATAttachmentController ()

@property (nonatomic, strong) UIPopoverController *imagePickerPopoverController;
@property (strong, nonatomic) NSMutableArray *mutableAttachments;
@property (assign, nonatomic) CGSize collectionViewFooterSize;

@end

@implementation ATAttachmentController

@synthesize active = _active;

- (void)viewDidLoad {
	self.collectionView.layer.shadowOpacity = 0.5;
	self.collectionView.layer.shadowRadius = 2.0;
	self.collectionView.layer.masksToBounds = NO;
	self.collectionView.layer.shadowColor = [UIColor grayColor].CGColor;

	self.mutableAttachments = [NSKeyedUnarchiver unarchiveObjectWithFile:self.archivePath];

	CGSize marginWithInsets = CGSizeMake(ATTACHMENT_MARGIN.width - (ATTACHMENT_INSET.left), ATTACHMENT_MARGIN.height - (ATTACHMENT_INSET.top));
	CGFloat height = [ATAttachmentCell heightForScreen:[UIScreen mainScreen] withMargin:marginWithInsets];
	CGFloat bottomY = CGRectGetMaxY(self.collectionView.frame);
	self.collectionView.frame = CGRectMake(self.collectionView.frame.origin.x, bottomY - height, self.collectionView.frame.size.width, height);

	UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
	layout.sectionInset = UIEdgeInsetsMake(ATTACHMENT_MARGIN.height - ATTACHMENT_INSET.top, ATTACHMENT_MARGIN.width - ATTACHMENT_INSET.left, ATTACHMENT_MARGIN.height - ATTACHMENT_INSET.bottom, ATTACHMENT_MARGIN.width - ATTACHMENT_INSET.right);
	layout.minimumInteritemSpacing = ATTACHMENT_MARGIN.width;
	layout.itemSize = [ATAttachmentCell sizeForScreen:[UIScreen mainScreen] withMargin:marginWithInsets];

	if (![self.mutableAttachments isKindOfClass:[NSMutableArray class]]) {
		self.mutableAttachments = [NSMutableArray array];
	}

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
	NSMutableArray *attachments = [NSMutableArray array];

	for (UIImage *image in self.mutableAttachments) {
		ATFileAttachment *attachment = [ATFileAttachment newInstanceWithFileData:UIImageJPEGRepresentation(image, 0.6) MIMEType:@"image/jpeg"];

		[attachments addObject:attachment];
	}

	return attachments;
}

- (BOOL)canBecomeFirstResponder {
	return YES;
}

- (UIView *)inputView {
	return self.collectionView;
}

- (void)clear {
	[self.mutableAttachments removeAllObjects];
	[self updateBadge];
	[self saveDraft];
}

#pragma mark - Actions

- (IBAction)showAttachments:(UIButton *)sender {
	if ((self.active || self.mutableAttachments.count == 0) && self.mutableAttachments.count < MAX_NUMBER_OF_ATTACHMENTS) {
		[self chooseImage:sender];
	} else {
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

	[self.mutableAttachments removeObjectAtIndex:indexPath.item];
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

#pragma mark - Image picker controller delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	NSURL *referenceURL = [info objectForKey:UIImagePickerControllerReferenceURL];

	if (referenceURL) { // Copy existing photo from asset library
		ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];

		[assetLibrary assetForURL:referenceURL resultBlock:^(ALAsset *asset) {
			ALAssetRepresentation *representation = asset.defaultRepresentation;
			UIImage *image = [UIImage imageWithCGImage:representation.fullScreenImage];

			[self insertImage:image];
		} failureBlock:^(NSError *error) {
			NSLog(@"Unable to copy asset");
		}];
	} else { // Save newly-taken photo
		UIImage *photo = info[UIImagePickerControllerOriginalImage];
		[self insertImage:photo];
	}

	[self dismissImagePicker:picker];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[self dismissImagePicker:picker];
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
	[self.mutableAttachments addObject:image];

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
