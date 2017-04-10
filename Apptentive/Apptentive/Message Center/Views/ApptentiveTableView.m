//
//  ApptentiveTableView.m
//  Apptentive
//
//  Created by Frank Schmitt on 2/9/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveTableView.h"


@implementation ApptentiveTableView

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
	[super traitCollectionDidChange:previousTraitCollection];

	[self.tableHeaderView sizeToFit];
	self.tableHeaderView = self.tableHeaderView;
}

@end
