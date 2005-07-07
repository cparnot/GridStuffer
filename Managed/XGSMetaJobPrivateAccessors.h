//
//  XGSMetaJobPrivateAccessors.h
//  GridStuffer
//
//  Created by Charles Parnot on 6/13/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//

#import "XGSMetaJob.h"

@class XGSIntegerArray;
@class XGSInputInterface;
@class XGSOutputInterface;

/* the private methods declared here provide typed accessors for CoreData properties of XGSMetaJob */

@interface XGSMetaJob (XGSMetaJobPrivateAccessors)

- (XGSInputInterface *)inputInterface;
- (XGSOutputInterface *)outputInterface;

- (XGSIntegerArray *)failureCounts;
- (XGSIntegerArray *)submissionCounts;
- (XGSIntegerArray *)successCounts;

- (void)setFailureCounts:(XGSIntegerArray *)failureCountsNew;
- (void)setSubmissionCounts:(XGSIntegerArray *)submissionCountsNew;
- (void)setSuccessCounts:(XGSIntegerArray *)successCountsNew;

@end
