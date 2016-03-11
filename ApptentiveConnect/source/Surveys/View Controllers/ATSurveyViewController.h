//
//  ATSurveyViewController.h
//  CVSurvey
//
//  Created by Frank Schmitt on 2/22/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ATCollectionView.h"
#import "ATSurveyViewModel.h"


@interface ATSurveyViewController : UICollectionViewController <UICollectionViewDelegateFlowLayout, UITextViewDelegate, UITextFieldDelegate, ATCollectionViewDataSource, ATSurveyViewModelDelegate>

@property (strong, nonatomic) ATSurveyViewModel *viewModel;

@end
