//
//  ATInfoViewController.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 5/23/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import "ATInfoViewController.h"
#import "ATConnect.h"

@interface ATInfoViewController (Private)
- (void)setup;
- (void)teardown;
- (void)done:(id)sender;
@end

@implementation ATInfoViewController
@synthesize tableView;

- (id)init {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self = [super initWithNibName:@"ATInfoViewController" bundle:[ATConnect resourceBundle]];
    } else {
        self = [super initWithNibName:@"ATInfoViewController_iPad" bundle:[ATConnect resourceBundle]];
    }
    return self;
}

- (void)dealloc {
    [self teardown];
    [super dealloc];
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.tableView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end


@implementation ATInfoViewController (Private)
- (void)setup {
    self.title = ATLocalizedString(@"Apptentive", @"Title of apptentive information screen.");
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:ATLocalizedString(@"Okay", @"Label of button for dismissing Apptentive screen.") style:UIBarButtonItemStyleDone target:self action:@selector(done:)] autorelease];
}

- (void)teardown {
    self.tableView = nil;
}

- (void)done:(id)sender {
    [self.navigationController dismissModalViewControllerAnimated:YES];
}
@end
