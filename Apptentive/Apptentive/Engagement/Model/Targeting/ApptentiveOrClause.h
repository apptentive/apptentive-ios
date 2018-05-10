//
//  ApptentiveOrClause.h
//  Apptentive
//
//  Created by Frank Schmitt on 11/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveClause.h"

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveOrClause : ApptentiveClause

+ (ApptentiveClause *)orClauseWithArray:(NSArray *)array;

@end

NS_ASSUME_NONNULL_END
