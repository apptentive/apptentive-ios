//
//  ATAboutViewController.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 7/28/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATAboutViewController.h"
#import "ATMessageCenterInteraction.h"
#import "ATBackend.h"

@interface ATAboutViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *aboutLabel;
@property (weak, nonatomic) IBOutlet UIButton *aboutButton;
@property (weak, nonatomic) IBOutlet UIButton *privacyButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *aboutButtonTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *privacyButtonLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *aboutButtonPrivacyButtonVeritcalConstraint;


@property (strong, nonatomic) NSArray *portraitConstraints;
@property (strong, nonatomic) NSArray *landscapeConstraints;

@end

@implementation ATAboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.imageView.image = [ATBackend imageNamed:@"at_apptentive_logo"];
	self.aboutLabel.text = self.interaction.aboutText;
	[self.aboutButton setTitle:self.interaction.aboutButtonTitle forState:UIControlStateNormal];
	[self.privacyButton setTitle:self.interaction.privacyButtonTitle forState:UIControlStateNormal];
	
	self.portraitConstraints = @[self.aboutButtonTrailingConstraint, self.privacyButtonLeadingConstraint, self.aboutButtonPrivacyButtonVeritcalConstraint];
	
	self.landscapeConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[about]-(16)-[privacy]" options:NSLayoutFormatAlignAllBaseline metrics:nil views:@{ @"about": self.aboutButton, @"privacy": self.privacyButton }];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[self.navigationController setToolbarHidden:YES animated:animated];
	[self resizeForOrientation:self.interfaceOrientation duration:0];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	[self.navigationController setToolbarHidden:NO animated:animated];
}

- (IBAction)learnMore:(id)sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.apptentive.com/"]];
}

- (IBAction)showPrivacy:(id)sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.apptentive.com/privacy"]];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[self resizeForOrientation:toInterfaceOrientation duration:duration];
}

- (void)resizeForOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration {
	BOOL isCompactHeight = CGRectGetHeight(self.view.bounds) < 400.0;
	BOOL isCompactWidth = CGRectGetWidth(self.view.bounds) < 480.0;
	
	self.imageViewHeightConstraint.constant = isCompactHeight ? 44.0 : 100.0;
	self.aboutLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.view.bounds) - 40.0;
	
	if (isCompactHeight && !isCompactWidth) {
		[self.view removeConstraints:self.portraitConstraints];
		[self.view addConstraints:self.landscapeConstraints];
		
		self.privacyButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
	} else {
		[self.view removeConstraints:self.landscapeConstraints];
		[self.view addConstraints:self.portraitConstraints];

		self.privacyButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
	}

	if (duration > 0) {
		[UIView animateWithDuration:duration animations:^{
			[self.view layoutIfNeeded];
		}];
	}
}

@end
