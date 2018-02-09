//
//  ApptentiveSurveyCollectionViewLayout.m
//  CVSurvey
//
//  Created by Frank Schmitt on 2/23/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyCollectionViewLayout.h"
#import "ApptentiveSurveyCollectionView.h"
#import "ApptentiveSurveyLayoutAttributes.h"

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveSurveyCollectionViewLayout ()

@property (assign, nonatomic) CGFloat headerHeight;

@end


@implementation ApptentiveSurveyCollectionViewLayout

- (CGSize)collectionViewContentSize {
	CGSize superSize = [super collectionViewContentSize];

	if ([self.collectionView isKindOfClass:[ApptentiveSurveyCollectionView class]]) {
		ApptentiveSurveyCollectionView *myCollectionView = (ApptentiveSurveyCollectionView *)self.collectionView;
		// Add space for the global header, global footer, and spacing between them and their adjacent sections
		superSize.height += CGRectGetHeight(myCollectionView.collectionHeaderView.bounds) + CGRectGetHeight(myCollectionView.collectionFooterView.bounds) + self.sectionInset.top + self.sectionInset.bottom;

		UIEdgeInsets contentInset = self.collectionView.contentInset;
		UIEdgeInsets adjustedContentInset = self.collectionView.contentInset;
#ifdef __IPHONE_11_0
		if (@available(iOS 11.0, *)) {
			contentInset = self.collectionView.safeAreaInsets;
			adjustedContentInset = self.collectionView.adjustedContentInset;
		}
#endif
		if (self.shouldExpand) {
			superSize.height = fmax(superSize.height, CGRectGetHeight(self.collectionView.bounds) - contentInset.top - contentInset.bottom);
		} else if (adjustedContentInset.bottom > contentInset.bottom || adjustedContentInset.top > contentInset.top) {
			superSize.height = fmax(superSize.height, CGRectGetHeight(self.collectionView.bounds) - adjustedContentInset.top - adjustedContentInset.bottom);
		}
	}

	return superSize;
}

- (nullable UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)decorationViewKind atIndexPath:(NSIndexPath *)indexPath {
	NSInteger section = indexPath.section;
	NSInteger numberOfItems = [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:section];

	UIEdgeInsets sectionInset = self.sectionInset;
#ifdef __IPHONE_11_0
	if (@available(iOS 11.0, *)) {
		sectionInset.left += self.collectionView.safeAreaInsets.left;
		sectionInset.right += self.collectionView.safeAreaInsets.right;
	}
#endif

	UICollectionViewLayoutAttributes *attributesForFirstItem = nil;
	UICollectionViewLayoutAttributes *attributesForLastItem = nil;
	if (numberOfItems) {
		attributesForFirstItem = [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
		attributesForLastItem = [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:numberOfItems - 1 inSection:section]];
	}

	UICollectionViewLayoutAttributes *headerLayoutAttributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath];
	UICollectionViewLayoutAttributes *footerLayoutAttributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter atIndexPath:indexPath];

	UICollectionViewLayoutAttributes *topLayoutAttributes = CGRectGetHeight(headerLayoutAttributes.frame) > 0 ? headerLayoutAttributes : attributesForFirstItem;
	UICollectionViewLayoutAttributes *bottomLayoutAttributes = CGRectGetHeight(footerLayoutAttributes.frame) > 0 ? footerLayoutAttributes : attributesForLastItem;

	CGPoint origin = topLayoutAttributes.frame.origin;
	CGSize size = CGSizeMake(CGRectGetMaxX(bottomLayoutAttributes.frame) - origin.x, CGRectGetMaxY(bottomLayoutAttributes.frame) - origin.y);
	ApptentiveSurveyLayoutAttributes *layoutAttributes = [ApptentiveSurveyLayoutAttributes layoutAttributesForDecorationViewOfKind:decorationViewKind withIndexPath:indexPath];

	if ([self.collectionView.dataSource conformsToProtocol:@protocol(ApptentiveCollectionViewDataSource)]) {
		layoutAttributes.valid = [(id<ApptentiveCollectionViewDataSource>)self.collectionView.dataSource sectionAtIndexIsValid:indexPath.section];
		layoutAttributes.validColor = [(id<ApptentiveCollectionViewDataSource>)self.collectionView.dataSource validColor];
		layoutAttributes.invalidColor = [(id<ApptentiveCollectionViewDataSource>)self.collectionView.dataSource invalidColor];
		layoutAttributes.backgroundColor = [(id<ApptentiveCollectionViewDataSource>)self.collectionView.dataSource backgroundColor];
	}

	layoutAttributes.frame = UIEdgeInsetsInsetRect(CGRectMake(origin.x, origin.y, size.width, size.height), sectionInset);
	layoutAttributes.zIndex = -1;

	return layoutAttributes;
}

- (nullable UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewLayoutAttributes *result = [[super layoutAttributesForItemAtIndexPath:indexPath] copy];

	result.frame = CGRectOffset(result.frame, 0, [self headerHeight]);

	return result;
}

- (nullable NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
	// Because the header view pushes the other views down, we have to adjust the rectangle in question
	// to encompass a larger area of the collection view. Experimentally, simply offseting the rect
	// results in missing cells (particular with "Other" question types). So instead we use inset with
	// a negative value to expand the rectangle vertically.
	rect = CGRectInset(rect, 0, -self.headerHeight);

	NSArray *superAttributes = [super layoutAttributesForElementsInRect:rect];
	NSMutableArray *newAttributes = [superAttributes mutableCopy];
	NSMutableArray *decorationViewAttributes = [NSMutableArray array];

	NSInteger i = 0;
	for (UICollectionViewLayoutAttributes *attributes in superAttributes) {
		if (attributes.representedElementCategory == UICollectionElementCategorySupplementaryView) {
			[newAttributes replaceObjectAtIndex:i withObject:[self layoutAttributesForSupplementaryViewOfKind:attributes.representedElementKind atIndexPath:attributes.indexPath]];
			ApptentiveArrayAddObject(decorationViewAttributes, [self layoutAttributesForDecorationViewOfKind:@"QuestionBackground" atIndexPath:attributes.indexPath]);
		}

		i++;
	}

	NSArray *result = [newAttributes arrayByAddingObjectsFromArray:decorationViewAttributes];

	[newAttributes removeAllObjects];
	for (UICollectionViewLayoutAttributes *attributes in result) {
		UICollectionViewLayoutAttributes *movedAttributes = [attributes copy];
		movedAttributes.frame = CGRectOffset(attributes.frame, 0, self.headerHeight);
		ApptentiveArrayAddObject(newAttributes, movedAttributes);
	}

	return newAttributes;
}

- (void)invalidateLayout {
	[super invalidateLayout];

	[self updateHeaderHeight];
}

- (void)setShouldExpand:(BOOL)shouldExpand {
	if (_shouldExpand != shouldExpand) {
		_shouldExpand = shouldExpand;

		[self.collectionView setNeedsLayout];
	}
}

#pragma mark - Private

- (void)updateHeaderHeight {
	if ([self.collectionView isKindOfClass:[ApptentiveSurveyCollectionView class]]) {
		UIView *collectionHeaderView = ((ApptentiveSurveyCollectionView *)self.collectionView).collectionHeaderView;
		CGSize headerSize = [collectionHeaderView systemLayoutSizeFittingSize:CGSizeMake(self.collectionView.bounds.size.width, CGFLOAT_MAX)];
		self.headerHeight = headerSize.height + self.sectionInset.bottom;
	} else {
		self.headerHeight = 0;
	}
}

@end

NS_ASSUME_NONNULL_END
