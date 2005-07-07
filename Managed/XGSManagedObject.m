//
//  XGSManagedObject.m
//  GridStuffer
//
//  Created by Charles Parnot on 6/23/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//

#ifdef DEBUG

#import "XGSManagedObject.h"
#import "DebugLog.h"

@implementation XGSManagedObject

- (NSString *)shortDescription
{
	return @"";
}

//do not use shortDescription on uninitialized objects, just in case...
- (id)initWithEntity:(NSEntityDescription*)entity insertIntoManagedObjectContext:(NSManagedObjectContext*)context
{
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s]",[self class],self,_cmd);
	return [super initWithEntity:entity insertIntoManagedObjectContext:context];
}

- (void)willSave
{
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	[super willSave];
}

//do not use shortDescription on uninitialized objects, just in case...
- (void)awakeFromInsert
{
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s]",[self class],self,_cmd);
	[super awakeFromInsert];
}

- (void)awakeFromFetch
{
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	[super awakeFromFetch];
}

- (void)dealloc
{
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	[super dealloc];
}

@end

#endif
