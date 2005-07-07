//
//  XGSJobListController.m
//  GridStuffer
//
//  Created by Charles Parnot on 7/5/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

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
