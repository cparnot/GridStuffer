//
//  XGSMetaJobPrivateAccessors.h
//  GridStuffer
//
//  Created by Charles Parnot on 6/13/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//

/*
 This file is part of GridStuffer.
 GridStuffer is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
 GridStuffer is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with GridStuffer; if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#import "XGSMetaJob.h"

@class XGSIntegerArray;
@class XGSInputInterface;
@class XGSOutputInterface;

/* the private methods declared here provide typed accessors for CoreData properties of XGSMetaJob */

@interface XGSMetaJob (XGSMetaJobPrivateAccessors)

- (XGSOutputInterface *)outputInterface;

- (XGSIntegerArray *)failureCounts;
- (XGSIntegerArray *)submissionCounts;
- (XGSIntegerArray *)successCounts;

- (void)setFailureCounts:(XGSIntegerArray *)failureCountsNew;
- (void)setSubmissionCounts:(XGSIntegerArray *)submissionCountsNew;
- (void)setSuccessCounts:(XGSIntegerArray *)successCountsNew;

@end
