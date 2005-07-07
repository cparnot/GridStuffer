//
//  XGSMetaJobAccessors.m
//  GridStuffer
//
//  Created by Charles Parnot on 6/13/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//

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
