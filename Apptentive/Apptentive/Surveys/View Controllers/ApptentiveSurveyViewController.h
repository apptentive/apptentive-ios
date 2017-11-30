//
//  ApptentiveSurveyViewController.h
//  CVSurvey
//
//  Created by Frank Schmitt on 2/22/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyCollectionView.h"
#import "ApptentiveSurveyViewModel.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveInteractionController;


@interface ApptentiveSurveyViewController : UICollectionViewController <UICollectionViewDelegateFlowLayout, UITextViewDelegate, UITextFieldDelegate, ApptentiveCollectionViewDataSource, ATSurveyViewModelDelegate>

@property (strong, nonatomic) ApptentiveSurveyViewModel *viewModel;

// This strong reference makes sure the interaction controller sticks around
// until the view controller is dismissed (required for
// `-dismissAllInteractions:` calls).
@property (strong, nullable, nonatomic) ApptentiveInteractionController *interactionController;

@end

NS_ASSUME_NONNULL_END
