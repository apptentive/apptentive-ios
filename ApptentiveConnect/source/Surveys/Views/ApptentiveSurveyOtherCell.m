//
//  ApptentiveSurveyOtherCell.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 5/4/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyOtherCell.h"

@implementation ApptentiveSurveyOtherCell

- (UIView *)snapshotViewAfterScreenUpdates:(BOOL)afterUpdates {
	if (self.bounds.size.height > self.textField.frame.origin.y) {
		return [super resizableSnapshotViewFromRect:self.bounds afterScreenUpdates:afterUpdates withCapInsets:UIEdgeInsetsMake(self.bounds.size.height / 2, 0, 0, 0)];
	} else {
		return [super resizableSnapshotViewFromRect:self.bounds afterScreenUpdates:afterUpdates withCapInsets:UIEdgeInsetsMake(self.bounds.size.height - 1, 0, 0, 0)];
	}
}

@end
