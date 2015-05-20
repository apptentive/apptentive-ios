//
//  ATMessageCenterViewController.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 5/20/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATMessageCenterViewController.h"
#import "ATMessageCenterGreetingView.h"
#import "ATBackend.h"
#import "ATConnect.h"

@interface ATMessageCenterViewController ()

@property (weak, nonatomic) ATMessageCenterGreetingView *greeting;

@end

@implementation ATMessageCenterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Actions

- (IBAction)dismiss:(UIBarButtonItem *)sender {
	[self.dismissalDelegate messageCenterWillDismiss:self];
	
	[self dismissViewControllerAnimated:YES completion:^{
		if ([self.dismissalDelegate respondsToSelector:@selector(messageCenterDidDismiss:)]) {
			[self.dismissalDelegate messageCenterDidDismiss:self];
		}
	}];
}

#pragma mark Rotation

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	CGFloat headerHeight = UIInterfaceOrientationIsLandscape(toInterfaceOrientation) ? 128 : 256;
	UICollectionViewFlowLayout *flowLayout = (id)self.collectionViewLayout;
	
	flowLayout.headerReferenceSize = CGSizeMake(self.view.bounds.size.width, headerHeight);
	[flowLayout invalidateLayout];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	// TODO: pull from number of messages/replies
    return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	NSString *reuseIdentifier = indexPath.row % 2 == 0 ? @"Message" : @"Reply";
	
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
	
	// TODO: configure the cell
	
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
		ATMessageCenterGreetingView *greeting = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Greeting" forIndexPath:indexPath];
		
		greeting.titleLabel.text = @"I’m sorry to hear that!";
		greeting.messageLabel.text = @"Please leave us some feedback so we can make the app better for you.";
		greeting.imageView.image = [ATBackend imageNamed:@"at_apptentive_icon_small"];
		
		self.greeting = greeting;
		
		return greeting;
	} else {
		UICollectionReusableView *thanks = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Thanks" forIndexPath:indexPath];
		
		return thanks;
	}
}

#pragma mark <UICollectionViewDelegate>

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

/*
 
// TODO: allow users to copy? 
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

@end
