//
//  ATInfoViewController.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 5/23/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import "ATInfoViewController.h"
#import "ATBackend.h"
#import "ATConnect.h"

@interface ATInfoViewController (Private)
- (void)setup;
- (void)teardown;
@end

@implementation ATInfoViewController
@synthesize tableView;

- (id)init {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self = [super initWithNibName:@"ATInfoViewController" bundle:[ATConnect resourceBundle]];
    } else {
        self = [super initWithNibName:@"ATInfoViewController_iPad" bundle:[ATConnect resourceBundle]];
        self.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    return self;
}

- (void)dealloc {
    [self teardown];
    [super dealloc];
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [headerView release], headerView = nil;
    self.tableView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)done:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark UITableViewDelegate


#pragma mark UITableViewDataSource
@end


@implementation ATInfoViewController (Private)
- (void)setup {
    if (headerView) {
        [headerView release], headerView = nil;
    }
    UIImage *logoImage = [ATBackend imageNamed:@"at_logo_info"];
    UINib *nib = [UINib nibWithNibName:@"AboutApptentiveView" bundle:[ATConnect resourceBundle]];
    [nib instantiateWithOwner:self options:nil];
    UIImageView *logoView = (UIImageView *)[headerView viewWithTag:2];
    logoView.image = logoImage;
    //tableView.delegate = self;
    //tableView.dataSource = self;
    tableView.tableHeaderView = headerView;
}

- (void)teardown {
    [headerView release], headerView = nil;
    self.tableView = nil;
}
@end
