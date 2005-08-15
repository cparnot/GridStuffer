//
//  XGSServer.m
//  GridStuffer
//
//  Created by Charles Parnot on 5/18/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//

/*
 This file is part of GridStuffer.
 GridStuffer is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
 GridStuffer is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with GridStuffer; if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#import "XGSServer.h"
#import "XGSServerConnection.h"
#import "XGSGrid.h"
#import "XGSGridPrivate.h"
#import "XGSServerBrowser.h"
#import "XGSFrameworkSettings.h"

//global constants used for notifications
NSString *XGSServerDidConnectNotification = @"XGSServerDidConnectNotification";
NSString *XGSServerDidLoadNotification = @"XGSServerDidLoadNotification";
NSString *XGSServerDidNotConnectNotification = @"XGSServerDidNotConnectNotification";
NSString *XGSServerDidDisconnectNotification = @"XGSServerDidDisconnectNotification";


//static NSString *XgridServiceType = @"_xgrid._tcp.";
//static NSString *XgridServiceDomain = @"local.";


@interface XGSServer (XGSServerPrivate)
- (XGSGrid *)gridWithID:(NSString *)gridID;
- (void)setServerConnection:(XGSServerConnection *)newServerConnection;
@end

@implementation XGSServer

#pragma mark *** Class methods ***

+ (void)initialize
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	NSArray *keys;
	if ( self == [XGSServer class] ) {
		keys=[NSArray arrayWithObjects:@"isAvailable", @"isConnecting", @"isConnected", @"isNetService", @"wasAvailableInCurrentSession", @"wasAvailableInPreviousSession", @"wasConnectedInCurrentSession", @"wasConnectedInPreviousSession", nil];
		[self setKeys:keys triggerChangeNotificationsForDependentKey:@"statusString"];
	}
}

+ (void)startBrowsing
{
	[[XGSServerBrowser sharedServerBrowser] startBrowsing];
}

+ (void)stopBrowsing
{
	[[XGSServerBrowser sharedServerBrowser] stopBrowsing];
}


#pragma mark *** Create/Retrieve servers ***

+ (NSArray *)allServers
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	//I am not sure what is the best way to retrieve ALL records for a given entity so I use a fetch request with a dummy predicate : 'name != ""', which should get them all but is probably not very efficient
	NSFetchRequest *request;
	NSArray *results;
	NSError *error;
	NSManagedObjectContext *context = [XGSFrameworkSettings sharedManagedObjectContext];
	request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[NSEntityDescription entityForName:@"Server" inManagedObjectContext:context]];
	[request setPredicate:[NSPredicate predicateWithFormat:@"(name != "")"]];
	results=[context executeFetchRequest:request error:&error];
	
	return results;
}

+ (XGSServer *)serverWithAddress:(NSString *)address
{
	return [XGSServer serverWithAddress:address inManagedObjectContext:[XGSFrameworkSettings sharedManagedObjectContext]];
}

+ (XGSServer *)serverWithAddress:(NSString *)address inManagedObjectContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request;
	NSArray *results;
	NSError *error;
	
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	//fetch request to see if there is already a server by that name in the context
	request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[NSEntityDescription entityForName:@"Server" inManagedObjectContext:context]];
	[request setPredicate:[NSPredicate predicateWithFormat:@"(name == %@)",address]];
	results=[context executeFetchRequest:request error:&error];
	
	//if already there, return it
	if ([results count]>0)
		return [results objectAtIndex:0];
	
	//if not, create the new server object
	XGSServer *newServer;
	newServer = [NSEntityDescription insertNewObjectForEntityForName:@"Server" inManagedObjectContext:context];
	[newServer setValue:address forKey:@"name"];
	[newServer setServerConnection:[XGSServerConnection serverConnectionWithAddress:address password:@""]];
	return newServer;
}


- (XGSServer *)serverInManagedObjectContext:(NSManagedObjectContext *)context
{
	NSString *address = [self valueForKey:@"name"];
	return [[self class] serverWithAddress:address inManagedObjectContext:context];
}

#pragma mark *** Initializations ***

- (void)awakeFromFetch
{
	[super awakeFromFetch];
	
	[self setPrimitiveValue:[NSNumber numberWithBool:NO] forKey:@"isConnected"];
	
	/*
	 NSEnumerator *e;
	 XGSGrid *aGrid;
	 availableGrids = [[NSMutableSet alloc] init];
	e = [[self valueForKey:@"grids"] objectEnumerator];
	while ( aGrid = [e nextObject] )
		if ( [aGrid isConnected] )
			[availableGrids addObject:aGrid];
	 */
}

- (void)dealloc
{
	//[availableGrids release];
	[self setServerConnection:nil];
	[super dealloc];
}

#pragma mark *** Private accessors ***

- (BOOL)isBusy
{
	return [self isConnecting] || [self isConnected];
}

- (XGConnection *)xgridConnection
{
	return [serverConnection xgridConnection];
}

- (XGSServerConnection *)serverConnection
{
	return serverConnection;
}

//When the serverConnection is set, we need to observe notifications sent by it
- (void)setServerConnection:(XGSServerConnection *)newServerConnection
{
	if ( serverConnection != newServerConnection ) {
		
		//stop notifications from the old ivar
		[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:serverConnection];
		
		//change the serverConnection ivar to the new value
		[newServerConnection retain];
		[serverConnection release];
		serverConnection = newServerConnection;
		
		if ( newServerConnection !=nil ) {
			
			//We need to be notified of all the activity of the XGSServerConnection object
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverConnectionDidConnect:) name:XGSServerConnectionDidConnectNotification object:serverConnection];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverConnectionDidLoad:) name:XGSServerConnectionDidLoadNotification object:serverConnection];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverConnectionDidNotConnect:) name:XGSServerConnectionDidNotConnectNotification object:serverConnection];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverConnectionDidDisconnect:) name:XGSServerConnectionDidDisconnectNotification object:serverConnection];
			
			//we need to update the status of the server, based on the status of the serverConnection
			if ( [serverConnection isConnected] || [serverConnection isLoaded] ) {
				[self setValue:[NSNumber numberWithBool:YES] forKey:@"isAvailable"];
				[self setValue:[NSNumber numberWithBool:YES] forKey:@"isConnected"];
				[self setValue:[NSNumber numberWithBool:NO]  forKey:@"isConnecting"];
				[self setValue:[NSNumber numberWithBool:YES] forKey:@"wasConnectedInCurrentSession"];
				[self setValue:[NSNumber numberWithBool:YES] forKey:@"wasConnectedInPreviousSession"];
				[self setValue:[NSNumber numberWithBool:YES] forKey:@"wasAvailableInCurrentSession"];
				[self setValue:[NSNumber numberWithBool:YES] forKey:@"wasAvailableInPreviousSession"];
				[self setValue:[NSDate date] forKey:@"lastConnection"];
			} else if ( [serverConnection isConnecting] ) {
				[self setValue:[NSNumber numberWithBool:NO] forKey:@"isConnected"];
				[self setValue:[NSNumber numberWithBool:YES]  forKey:@"isConnecting"];
			}
		}
		
	}
}

#pragma mark *** Public accessors ***

- (id)delegate
{
	return delegate;
}

- (void)setDelegate:(id)newDelegate
{
	delegate = newDelegate;
}

//this is an 'abstract' ivar, which should be KVO compliant thanks to the +initialize method
- (NSString *)statusString
{
	if ([self isConnected])
		return @"Connected";
	if ([self isConnecting])
		return @"Connecting";
	if ([self isAvailable])
		return @"Available";
	if ([[self valueForKey:@"wasConnectedInCurrentSession"] boolValue])
		return @"Disconnected";
	return @"Offline";
}

- (BOOL)isAvailable
{
    [self willAccessValueForKey:@"isAvailable"];
    BOOL flag = [[self primitiveValueForKey:@"isAvailable"] boolValue];
    [self didAccessValueForKey:@"isAvailable"];
    return flag;
}
- (BOOL)isConnected
{
    [self willAccessValueForKey:@"isConnected"];
    BOOL flag = [[self primitiveValueForKey:@"isConnected"] boolValue];
    [self didAccessValueForKey:@"isConnected"];
    return flag;
}

- (BOOL)isConnecting
{
    [self willAccessValueForKey:@"isConnecting"];
    BOOL flag = [[self primitiveValueForKey:@"isConnecting"] boolValue];
    [self didAccessValueForKey:@"isConnecting"];
    return flag;
}

- (XGController *)xgridController
{
	return [serverConnection xgridController];
}

- (XGSGrid *)defaultGrid
{
	NSSet *currentGrids, *currentIDs;
	NSString *gridID;
	XGSGrid *aGrid;
	XGGrid *grid;
	NSEnumerator *e;
	
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);

	//get the default grid from the controller, if connected
	grid = [[self xgridController] defaultGrid];
	if ( grid == nil )
		return nil;

	//get the corresponding XGSGrid, creating it if necessary
	currentIDs = [self valueForKeyPath:@"grids.gridID"];
	gridID = [grid identifier];
	if ( [currentIDs member:gridID]==nil ) {
		aGrid = [NSEntityDescription insertNewObjectForEntityForName:@"Grid" inManagedObjectContext:[self managedObjectContext]];
		[aGrid setValue:gridID forKey:@"gridID"];
		[aGrid setValue:self forKey:@"server"];
		return aGrid;
	} else {
		currentGrids = [self valueForKey:@"grids"];
		e = [currentGrids objectEnumerator];
		while ( (aGrid = [e nextObject]) && [[aGrid valueForKey:@"gridID"] isEqualToString:gridID]==NO )
			;
	}
	
	return aGrid;
}

#pragma mark *** Connection public methods ***

- (void)connectWithoutAuthentication
{
	[serverConnection connectWithoutAuthentication];
}

- (void)connectWithPassword:(NSString *)password
{
	[serverConnection setPassword:password];
	[serverConnection connectWithPassword];
}

- (void)connectWithSingleSignOnCredentials;
{
	[serverConnection connectWithSingleSignOnCredentials];
}

- (void)disconnect
{
	[serverConnection disconnect];
}


#pragma mark *** XGSServerConnection notifications ***

- (void)serverConnectionDidConnect:(NSNotification *)aNotification
{
	[[NSNotificationCenter defaultCenter] postNotificationName:XGSServerDidConnectNotification object:self];
}

- (void)serverConnectionDidNotConnect:(NSNotification *)aNotification
{
	[[NSNotificationCenter defaultCenter] postNotificationName:XGSServerDidNotConnectNotification object:self];
}

- (void)serverConnectionDidDisconnect:(NSNotification *)aNotification
{
	[[NSNotificationCenter defaultCenter] postNotificationName:XGSServerDidDisconnectNotification object:self];
}

- (void)serverConnectionDidLoad:(NSNotification *)aNotification
{
	[[NSNotificationCenter defaultCenter] postNotificationName:XGSServerDidLoadNotification object:self];
}


/*
#pragma mark *** XGConnection delegate methods ***

- (void)connectionDidOpen:(XGConnection *)connection;
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	//update status
	[self setValue:[NSNumber numberWithBool:YES] forKey:@"isAvailable"];
	[self setValue:[NSNumber numberWithBool:YES] forKey:@"isConnected"];
	[self setValue:[NSNumber numberWithBool:NO]  forKey:@"isConnecting"];
	[self setValue:[NSNumber numberWithBool:YES] forKey:@"wasConnectedInCurrentSession"];
	[self setValue:[NSNumber numberWithBool:YES] forKey:@"wasConnectedInPreviousSession"];
	[self setValue:[NSNumber numberWithBool:YES] forKey:@"wasAvailableInCurrentSession"];
	[self setValue:[NSNumber numberWithBool:YES] forKey:@"wasAvailableInPreviousSession"];
	[self setValue:[NSDate date] forKey:@"lastConnection"];
	
	//make sure we have initialized the XGController
	XGController *bogusVariable;
	bogusVariable = [self xgridController];

	//notifications
	if ( [delegate respondsToSelector:@selector(serverDidConnect:)] )
		[delegate serverDidConnect:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:XGSServerDidConnectNotification object:self];

}

- (void)connectionDidNotOpen:(XGConnection *)connection withError:(NSError *)error
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	//update status
	[self setValue:[NSNumber numberWithBool:NO] forKey:@"isConnected"];
	[self setValue:[NSNumber numberWithBool:NO]  forKey:@"isConnecting"];

	//notifications
	if ( [delegate respondsToSelector:@selector(serverDidNotConnect:)] )
		[delegate serverDidNotConnect:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:XGSServerDidNotConnectNotification object:self];
	
}

- (void)connectionDidClose:(XGConnection *)connection;
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	//update status
	[self setValue:[NSNumber numberWithBool:NO] forKey:@"isAvailable"];
	[self setValue:[NSNumber numberWithBool:NO] forKey:@"isConnected"];
	[self setValue:[NSNumber numberWithBool:NO]  forKey:@"isConnecting"];
	
	//notifications
	if ( [delegate respondsToSelector:@selector(serverDidNotConnect:)] )
		[delegate serverDidNotConnect:self];
	if ( [delegate respondsToSelector:@selector(serverDidDisconnect:)] )
		[delegate serverDidDisconnect:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:XGSServerDidNotConnectNotification object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:XGSServerDidDisconnectNotification object:self];
}

*/


/*
#pragma mark *** KVO protocol ***

//convenience method to add a grid to the list of available grids
- (XGSGrid *)gridWithID:(NSString *)gridID
{
	NSManagedObjectContext *context;
	NSFetchRequest *request;
	NSArray *results;
	NSError *error;
	XGSGrid *gridObject;
	NSEnumerator *e;
	
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	//fetch request to see if there are already grids with the right ID in store
	context = [self managedObjectContext];
	request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[NSEntityDescription entityForName:@"Grid" inManagedObjectContext:context]];
	[request setPredicate:[NSPredicate predicateWithFormat:@"(gridID == %@)",gridID]];
	results=[context executeFetchRequest:request error:&error];
	
	//is there already an appropriate XGSGrid in store?
	gridObject = nil;
	e = [results objectEnumerator];
	while ( gridObject = [e nextObject] ) {
		if ( [gridObject server] == self )
			break;
	}
	if ( gridObject == nil ) {
		gridObject = [NSEntityDescription insertNewObjectForEntityForName:@"Grid" inManagedObjectContext:[self managedObjectContext]];
		[gridObject setGridID:gridID];
		[gridObject setServer:self];
		[[self mutableSetValueForKey:@"grids"] addObject:gridObject];
	}
	
	//return the grid object
	return gridObject;
}

//used to keep track of grids in the controller
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	NSMutableSet *oldGrids;
	NSString *gridID;
	NSArray *grids;
	XGSGrid *aGrid;
	XGGrid *grid;
	NSEnumerator *e;
	//BOOL notifyDelegate;

	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s\nObject = <%@:%p>\nKey Path = %@\nChange = %@",[self class],self,_cmd,[object class], object, keyPath, [change description]);
	
	if ( object == xgridController &&  [self isConnected] && [keyPath isEqualToString:@"grids"] ) {
		
		//remove from availableGrids the grids that have disappeared
		oldGrids = [NSMutableSet setWithCapacity:[availableGrids count]];
		e = [availableGrids objectEnumerator];
		while ( aGrid=[e nextObject] ) {
			if ( [[ self xgridController] gridForIdentifier:[aGrid valueForKey:@"gridID"]] == nil )
				[oldGrids addObject:aGrid];
		}
		e = [oldGrids objectEnumerator];
		while ( aGrid = [e nextObject] )
			[availableGrids removeObject:aGrid];
		
		//add the new grids to the availableGrids and awake them from connection
		grids = [[self xgridController] grids];
		e = [grids objectEnumerator];
		while ( grid = [e nextObject] ) {
			gridID = [grid identifier];
			aGrid = [self gridWithID:gridID];
			if ( [availableGrids member:aGrid] == nil ) {
				[availableGrids addObject:aGrid];
				[aGrid awakeFromServerConnection];
			}
		}
	}
}
*/

@end
