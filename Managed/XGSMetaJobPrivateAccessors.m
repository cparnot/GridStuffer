//
//  XGSMetaJobPrivateAccessors.m
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

#import "XGSMetaJobPrivateAccessors.h"

@implementation XGSMetaJob (XGSMetaJobPrivateAccessors)

- (XGSOutputInterface *)outputInterface
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);

	XGSOutputInterface *result;
	[self willAccessValueForKey:@"outputInterface"];
	result = [self primitiveValueForKey:@"outputInterface"];
	[self didAccessValueForKey:@"outputInterface"];
	return result;
}

- (XGSIntegerArray *)failureCounts
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);

	XGSIntegerArray *failureCountsLocal;
	[self willAccessValueForKey:@"failureCounts"];
	failureCountsLocal = [self primitiveValueForKey:@"failureCounts"];
	[self didAccessValueForKey:@"failureCounts"];
	return failureCountsLocal;
}

- (XGSIntegerArray *)submissionCounts
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);

	XGSIntegerArray *submissionCountsLocal;
	[self willAccessValueForKey:@"submissionCounts"];
	submissionCountsLocal = [self primitiveValueForKey:@"submissionCounts"];
	[self didAccessValueForKey:@"submissionCounts"];
	return submissionCountsLocal;
}

- (XGSIntegerArray *)successCounts
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);

	XGSIntegerArray *successCountsLocal;
	[self willAccessValueForKey:@"successCounts"];
	successCountsLocal = [self primitiveValueForKey:@"successCounts"];
	[self didAccessValueForKey:@"successCounts"];
	return successCountsLocal;
}

- (void)setFailureCounts:(XGSIntegerArray *)failureCountsNew
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);

	[self willChangeValueForKey:@"failureCounts"];
	[self setPrimitiveValue:failureCountsNew forKey:@"failureCounts"];
	[self didChangeValueForKey:@"failureCounts"];
}

- (void)setSubmissionCounts:(XGSIntegerArray *)submissionCountsNew
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);

	[self willChangeValueForKey:@"submissionCounts"];
	[self setPrimitiveValue:submissionCountsNew forKey:@"submissionCounts"];
	[self didChangeValueForKey:@"submissionCounts"];
}

- (void)setSuccessCounts:(XGSIntegerArray *)successCountsNew
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);

	[self willChangeValueForKey:@"successCounts"];
	[self setPrimitiveValue:successCountsNew forKey:@"successCounts"];
	[self didChangeValueForKey:@"successCounts"];
}


@end
