//
//  WowieConnectViewController.m
//  WowieConnect
//
//  Created by Michael Saffitz on 12/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "WowieConnectViewController.h"
#import "WowieConnect.h"

@implementation WowieConnectViewController

- (IBAction) feedbackButtonPress:(id) sender {
	[[WowieConnect sharedInstance] presentWowieConnectModalViewControllerForParent:self];
}

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // [UserVoice presentUserVoiceModalViewControllerForParent:self
    // andSite:@"YOUR_USERVOICE_URL"
    // andKey:@"YOUR_KEY"
    // andSecret:@"YOUR_SECRET"];

	[[WowieConnect sharedInstance] displayButtonOnView:self atLocation:TopCenter];
    
//    FeedbackButtonViewController *fbViewController = [[FeedbackButtonViewController alloc] initWithNibName:@"FeedbackButtonViewController" bundle:nil];
//    [fbViewController displayAtTopCenter:self.view.frame];
//		[self.view addSubview:fbViewController.view];
}
    
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

@end
