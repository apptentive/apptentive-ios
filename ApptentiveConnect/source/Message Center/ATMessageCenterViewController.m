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

@interface ATMessageCenterViewController ()

@property (weak, nonatomic) IBOutlet ATMessageCenterGreetingView *greetingView;

@end

@implementation ATMessageCenterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self updateHeaderHeightForOrientation:self.interfaceOrientation];
	
	// DEBUG
	self.greetingView.imageView.image = [UIImage imageNamed:@"ApptentiveResources.bundle/Sumo.jpg"];
	self.greetingView.titleLabel.text = @"That sucks!";
	self.greetingView.messageLabel.text = @"Please let us know how we can do better.";
	// /DEBUG
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[UIView animateWithDuration:duration animations:^{
		[self updateHeaderHeightForOrientation:toInterfaceOrientation];
	}];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // TODO: Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // TODO: Return the number of rows in the section.
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *reuseIdentifier = indexPath.section % 2 ? @"Reply" : @"Message";
 
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    // TODO: Configure the cell...
    
    return cell;
}

#pragma mark Actions

- (IBAction)dismiss:(id)sender {
	[self.dismissalDelegate messageCenterWillDismiss:self];
	
	[self dismissViewControllerAnimated:YES completion:^{
		if ([self.dismissalDelegate respondsToSelector:@selector(messageCenterDidDismiss:)]) {
			[self.dismissalDelegate messageCenterDidDismiss:self];
		}
	}];
}

#pragma mark - Private

- (void)updateHeaderHeightForOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	CGFloat headerHeight = UIInterfaceOrientationIsLandscape(toInterfaceOrientation) ? 128.0 : 280.0;

	self.greetingView.bounds = CGRectMake(0, 0, self.tableView.bounds.size.height, headerHeight);
	[self.greetingView updateConstraints];
	self.tableView.tableHeaderView = self.greetingView;
}

@end
