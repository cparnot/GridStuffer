//
//  XGSManagedObject.m
//  GridStuffer
//
//  Created by Charles Parnot on 6/23/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//

/*
 This file is part of GridStuffer.
 GridStuffer is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
 GridStuffer is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with Foobar; if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

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
