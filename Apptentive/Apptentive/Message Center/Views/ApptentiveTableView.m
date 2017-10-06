//
//  ApptentiveTableView.m
//  Apptentive
//
//  Created by Frank Schmitt on 2/9/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveTableView.h"

NS_ASSUME_NONNULL_BEGIN


@implementation ApptentiveTableView

- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection {
	[super traitCollectionDidChange:previousTraitCollection];

	[self.tableHeaderView sizeToFit];
	self.tableHeaderView = self.tableHeaderView;
}

@end

NS_ASSUME_NONNULL_END
