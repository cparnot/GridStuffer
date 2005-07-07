//
//  XGSGrid.m
//  GridStuffer
//
//  Created by Charles Parnot on 5/26/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//

#import "XGSGrid.h"
#import "XGSGridPrivate.h"
#import "XGSServer.h"
#import "XGSJob.h"
#import "XGSJobPrivate.h"

NSString *XGSGridDidBecomeAvailableNotification = @"XGSGridDidBecomeAvailableNotification";
NSString *XGSGridDidBecomeUnavailableNotification = @"XGSGridDidBecomeUnavailableNotification";

//undocumented private method for XGGrid
@interface XGGrid (XGGridUndocumented)
- (NSString *)name;
@end

@implementation XGSGrid

//private method called by self or XGSServer
//it may be called several times because of the way the Xgrid framework and GridStuffer behave,
//but the initializations done here will be run only once = the first time the xgridGrid object is available
- (void)awakeFromServerConnection
{
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] (grid '%@')",[self class],self,_cmd,[self name]);
	
	//initialize the xgridGrid object
	if ( xgridGrid == nil )
		[self initializeXgridGridObject];
}


- (void)awakeFromFetch
{
	[super awakeFromFetch];
	//if the XGGrid is available, this will trigger the needed initializations
	[self awakeFromServerConnection];
}

- (void)dealloc
{
	[xgridGrid removeObserver:self forKeyPath:@"state"];
	[xgridGrid removeObserver:self forKeyPath:@"jobs"];
	[xgridGrid removeObserver:self forKeyPath:@"name"];
	[xgridGrid release];
	[availableJobs release];
	[super dealloc];
}


#pragma mark *** public accessors ***

- (BOOL)isConnected
{
	return [[self server] isConnected];
}

- (XGSServer *)server
{
	XGSServer *server;
	[self willAccessValueForKey:@"server"];
	server = [self primitiveValueForKey:@"server"];
	[self didAccessValueForKey:@"server"];
	return server;
}

- (NSString *)gridID
{
	NSString *gridID;
	[self willAccessValueForKey:@"gridID"];
	gridID = [self primitiveValueForKey:@"gridID"];
	[self didAccessValueForKey:@"gridID"];
	return gridID;
}

- (NSString *)name
{
	NSString *nameLocal;
	[self willAccessValueForKey:@"name"];
	nameLocal = [self primitiveValueForKey:@"name"];
	[self didAccessValueForKey:@"name"];
	return nameLocal;
}

- (XGGrid *)xgridGrid
{
	if ( xgridGrid == nil )
		[self initializeXgridGridObject];
	return xgridGrid;
}

#pragma mark *** private accessors ***

- (void)setServer:(XGSServer *)newServer
{
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] (grid '%@')",[self class],self,_cmd,[self name]);
	[self willChangeValueForKey:@"server"];
	[self setPrimitiveValue:newServer forKey:@"server"];
	[self didChangeValueForKey:@"server"];
}

- (void)setGridID:(NSString *)gridID
{
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] (grid '%@')",[self class],self,_cmd,[self name]);
	[self willChangeValueForKey:@"gridID"];
	[self setPrimitiveValue:gridID forKey:@"gridID"];
	[self didChangeValueForKey:@"gridID"];
}

- (void)setName:(NSString *)nameNew
{
	[self willChangeValueForKey:@"name"];
	[self setPrimitiveValue:nameNew forKey:@"name"];
	[self didChangeValueForKey:@"name"];
}


#pragma mark *** watching the XGGrid wrapped object ***

//the XGGrid object is set only once during the lifetime of self
//this is also where the KVO is set
- (void)initializeXgridGridObject
{
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] (grid '%@')",[self class],self,_cmd,[self name]);

	if ( xgridGrid == nil ) {
		xgridGrid = [[[self server] xgridController] gridForIdentifier:[self gridID]];
		if ( xgridGrid != nil ) {
			availableJobs = [[NSMutableSet alloc] init];
			[self xgridGridStateDidChange];
			[self xgridGridNameDidChange];
			[self xgridGridJobsDidChange];
			[[self xgridGrid] addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
			[[self xgridGrid] addObserver:self forKeyPath:@"jobs" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
			[[self xgridGrid] addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
		}
	}
}


- (void)xgridGridStateDidChange
{
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] (grid '%@')",[self class],self,_cmd,[self name]);

	if ( [xgridGrid state] == XGResourceStateUnavailable || [xgridGrid state] == XGResourceStateOffline )
		[[NSNotificationCenter defaultCenter] postNotificationName:XGSGridDidBecomeUnavailableNotification object:self];
	else if ( [xgridGrid state] == XGResourceStateAvailable )
		[[NSNotificationCenter defaultCenter] postNotificationName:XGSGridDidBecomeAvailableNotification object:self];
}

- (void)xgridGridNameDidChange
{
	NSString *newName;

	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] (grid '%@')",[self class],self,_cmd,[self name]);

	newName = [xgridGrid name];
	if ( ( newName != nil ) && ( [newName isEqualToString:@""] == NO ) )
		 [self setName:newName];
}

//convenience method to retrieve an XGSJob that has its grid = self
- (XGSJob *)jobWithID:(NSString *)jobID
{
	NSManagedObjectContext *context;
	NSFetchRequest *request;
	NSArray *results;
	NSError *error;
	XGSJob *jobObject;
	NSEnumerator *e;
	
	DLog(NSStringFromClass([self class]),12,@"<%@:%p> %s",[self class],self,_cmd);
	
	//fetch request to see if there are already grids with the right ID in store
	context = [self managedObjectContext];
	request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[NSEntityDescription entityForName:@"Job" inManagedObjectContext:context]];
	[request setPredicate:[NSPredicate predicateWithFormat:@"(jobID == %@)",jobID]];
	results=[context executeFetchRequest:request error:&error];
	
	//is there already an appropriate XGSJob in store?
	jobObject = nil;
	e = [results objectEnumerator];
	while ( jobObject = [e nextObject] ) {
		if ( [jobObject grid] == self )
			break;
	}
	return jobObject;
}

- (void)xgridGridJobsDidChange
{
	NSArray *xgridJobs;
	NSEnumerator *e;
	XGJob *aJob;
	
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] (grid '%@')",[self class],self,_cmd,[self name]);

	xgridJobs = [xgridGrid jobs];
	e = [xgridJobs objectEnumerator];
	while ( aJob = [e nextObject] )
		[[self jobWithID:[aJob identifier]] awakeFromServerConnection];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s\nObject = <%@:%p>\nKey Path = %@\nChange = %@",[self class],self,_cmd,[object class], object, keyPath, [change description]);

	if ( object == xgridGrid ) {
		if ( [keyPath isEqualToString:@"state"] )
			[self xgridGridStateDidChange];
		else if ( [keyPath isEqualToString:@"name"] )
			[self xgridGridNameDidChange];
		else if ( [keyPath isEqualToString:@"jobs"] )
			[self xgridGridJobsDidChange];
	}
}

@end
