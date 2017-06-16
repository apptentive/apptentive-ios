//
//  ApptentiveDefines.h
//  Apptentive
//
//  Created by Alex Lementuev on 5/30/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#ifndef ApptentiveDefines_h
#define ApptentiveDefines_h

#import "ApptentiveLog.h"

#define APPTENTIVE_CHECK_INIT_NOT_NIL_ARG(ARG)                                                    \
	if ((ARG) == nil) {                                                                           \
		ApptentiveLogError(@"Can't init %@: '" #ARG "' is nil", NSStringFromClass([self class])); \
		return nil;                                                                               \
	}

#define APPTENTIVE_CHECK_INIT_NOT_EMPTY_ARG(ARG)                                                           \
	if ((ARG).length == 0) {                                                                               \
		ApptentiveLogError(@"Can't init %@: '" #ARG "' is nil or empty", NSStringFromClass([self class])); \
		return nil;                                                                                        \
	}

#endif /* ApptentiveDefines_h */
