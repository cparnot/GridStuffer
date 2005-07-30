//
//  XGSMetaJobAccessors.m
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

@interface XGSMetaJob (XGSMetaJobPrivate)
- (void)resetAvailableTasks;
@end

@implementation XGSMetaJob (XGSMetaJobAccessors)

- (int)successCountsThreshold
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);

	int result;
	[self willAccessValueForKey:@"successCountsThreshold"];
	result = [[self primitiveValueForKey:@"successCountsThreshold"] intValue];
	[self didAccessValueForKey:@"successCountsThreshold"];
	return result;
}

- (int)failureCountsThreshold
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);

	int result;
	[self willAccessValueForKey:@"failureCountsThreshold"];
	result = [[self primitiveValueForKey:@"failureCountsThreshold"] intValue];
	[self didAccessValueForKey:@"failureCountsThreshold"];
	return result;
}

- (int)maxSubmissionsPerTask
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);

	int result;
	[self willAccessValueForKey:@"maxSubmissionsPerTask"];
	result = [[self primitiveValueForKey:@"maxSubmissionsPerTask"] intValue];
	[self didAccessValueForKey:@"maxSubmissionsPerTask"];
	return result;
}


- (void)setFailureCountsThreshold:(int)failureCountsThresholdNew
{
	[self willChangeValueForKey:@"failureCountsThreshold"];
	[self setPrimitiveValue:[NSNumber numberWithInt:failureCountsThresholdNew] forKey:@"failureCountsThreshold"];
	[self didChangeValueForKey:@"failureCountsThreshold"];
	[self resetAvailableTasks];
}

- (void)setMaxSubmissionsPerTask:(int)maxSubmissionsPerTaskNew
{
	[self willChangeValueForKey:@"maxSubmissionsPerTask"];
	[self setPrimitiveValue:[NSNumber numberWithInt:maxSubmissionsPerTaskNew] forKey:@"maxSubmissionsPerTask"];
	[self didChangeValueForKey:@"maxSubmissionsPerTask"];
	[self resetAvailableTasks];
}

- (void)setSuccessCountsThreshold:(int)successCountsThresholdNew
{
	[self willChangeValueForKey:@"successCountsThreshold"];
	[self setPrimitiveValue:[NSNumber numberWithInt:successCountsThresholdNew] forKey:@"successCountsThreshold"];
	[self didChangeValueForKey:@"successCountsThreshold"];
	[self resetAvailableTasks];
}


@end
