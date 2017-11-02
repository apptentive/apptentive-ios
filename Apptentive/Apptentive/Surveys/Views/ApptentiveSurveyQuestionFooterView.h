//
//  ApptentiveSurveyQuestionFooterView.h
//  Apptentive
//
//  Created by Frank Schmitt on 6/21/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveSurveyQuestionFooterView : UICollectionReusableView

@property (strong, nonatomic) IBOutlet UILabel *minimumLabel;
@property (strong, nonatomic) IBOutlet UILabel *maximumLabel;

@end

NS_ASSUME_NONNULL_END
