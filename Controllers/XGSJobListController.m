//
//  XGSJobListController.m
//  GridStuffer
//
//  Created by Charles Parnot on 7/5/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

/*
 This file is part of GridStuffer.
 GridStuffer is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
 GridStuffer is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with GridStuffer; if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#import "XGSJobListController.h"

@implementation XGSJobListController

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	self = [super initWithWindowNibName:@"JobList"];
	if (self!=nil) {
		[self setWindowFrameAutosaveName:@"XGSJobListWindow"];
		managedObjectContext = [context retain];
	}
	return self;
}
- (NSManagedObjectContext *)managedObjectContext
{
	return managedObjectContext;
}

- (void)dealloc
{
	[managedObjectContext release];
	[super dealloc];
}

@end
