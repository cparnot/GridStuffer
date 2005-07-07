//
//  XGSServerList.m
//  GridStuffer
//
//  Created by Charles Parnot on 5/18/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//

#import "XGSServerList.h"
#import "XGSServer.h"

static NSString *XgridServiceType = @"_xgrid._tcp.";
static NSString *XgridServiceDomain = @"local.";

@implementation XGSServerList

#pragma mark *** initializations ***

+ (void)initialize
{
	//make sure that any change in the list of connected servers notifies for the change of xgridController key
	NSArray *keys;
	if ( self == [XGSServerList class] ) {
		keys = [NSArray arrayWithObjects:@"servers",nil];
		[self setKeys:keys triggerChangeNotificationsForDependentKey:@"xgridController"];
		[self setKeys:keys triggerChangeNotificationsForDependentKey:@"connectedServers"];
		[self setKeys:keys triggerChangeNotificationsForDependentKey:@"validServers"];
	}
}


#pragma mark *** KVO stuff to keep server lists up to date ***

- (void)updateFetchedProperties
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	NSArray *servers;
	servers = [self valueForKey:@"servers"];
	servers = [self valueForKey:@"validServers"];
	[self willChangeValueForKey:@"servers"];
	[self  didChangeValueForKey:@"servers"];
	//[[self managedObjectContext] refreshObject:self mergeChanges:YES];
}

/*
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s\nObject = <%@:%p>\nKey Path = %@",[self class],self,_cmd,[object class], object, keyPath);
	if ( [object class] == [XGSServer class] )
		[self updateFetchedProperties];
}
*/

#pragma mark *** adding and retrieving servers ***

//create the sharedListServer object in the managed object context if it does not exist yet
+ (XGSServerList *)sharedServerListForContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request;
	NSArray *results;
	NSError *error;
	XGSServerList *sharedServerList;
	
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	//fetch ServerList entitites
	request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[NSEntityDescription entityForName:@"ServerList" inManagedObjectContext:context]];
	[request setPredicate:[NSPredicate predicateWithFormat:@"name == %@",@"sharedServerList"]];
	results=[context executeFetchRequest:request error:&error];
	
	//if already there, return it
	//otherwise, create it
	if ([results count]>0)
		sharedServerList = [results objectAtIndex:0];
	else
		sharedServerList = [NSEntityDescription insertNewObjectForEntityForName:@"ServerList" inManagedObjectContext:context];
	
	/*
	//add the server list as an observer of all servers
	request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[NSEntityDescription entityForName:@"Server" inManagedObjectContext:context]];
	results=[context executeFetchRequest:request error:&error];
	servers = [sharedServerList valueForKey:@"servers"];
	e = [servers objectEnumerator];
	while ( aServer = [e nextObject] )
		[sharedServerList startObservingServer:aServer];
	e = [results objectEnumerator];
	while ( aServer = [e nextObject] )
		[sharedServerList startObservingServer:aServer];
	*/
	 
	//return the server list
	return sharedServerList;
}


//check if a server with the same name is already registered in the managed object context
//otherwise, create it
- (XGSServer *)bonjourServerWithNetService:(NSNetService *)netService
{
	NSManagedObjectContext *context;
	NSFetchRequest *request;
	NSArray *results;
	NSError *error;
	NSString *name;
	XGSServer *newServer;

	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);

	//fetch request to see if there is already a server by that name in the context
	context = [self managedObjectContext];
	request = [[[NSFetchRequest alloc] init] autorelease];
	name = [netService name];
	[request setEntity:[NSEntityDescription entityForName:@"Server" inManagedObjectContext:context]];
	[request setPredicate:[NSPredicate predicateWithFormat:@"(name == %@) AND (isNetService == YES)",name]];
	results=[context executeFetchRequest:request error:&error];

	//if already there, return it
	if ([results count]>0)
		return [results objectAtIndex:0];

	//otherwise, create it
	newServer = [NSEntityDescription insertNewObjectForEntityForName:@"Server" inManagedObjectContext:context];
	[newServer setValue:[NSNumber numberWithBool:YES] forKey:@"isNetService"];
	[newServer setValue:name forKey:@"name"];
	
	//keep the server list updated
	[self updateFetchedProperties];
	
	return newServer;
}

//check if a server with the same name is already registered in the managed object context
//otherwise, create it
- (XGSServer *)internetServerWithHostname:(NSString *)name;
{
	NSManagedObjectContext *context;
	NSFetchRequest *request;
	NSArray *results;
	NSError *error;
	XGSServer *newServer;

	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);

	//fetch request to see if there is already a server by that name in the context
	context = [self managedObjectContext];
	request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[NSEntityDescription entityForName:@"Server" inManagedObjectContext:context]];
	[request setPredicate:[NSPredicate predicateWithFormat:@"(name == %@) AND (isNetService == NO)",name]];
	results=[context executeFetchRequest:request error:&error];
	
	//if already there, return it
	if ([results count]>0)
		return [results objectAtIndex:0];
	
	//otherwise, create it
	newServer = [NSEntityDescription insertNewObjectForEntityForName:@"Server"
											  inManagedObjectContext:context];
	[newServer setValue:[NSNumber numberWithBool:NO] forKey:@"isNetService"];
	[newServer setValue:name forKey:@"name"];

	//keep the server list updated
	[self updateFetchedProperties];
	
	return newServer;
}

//public method to create/retrieve servers of any kind
- (XGSServer *)serverWithName:(NSString *)name
{
	NSManagedObjectContext *context;
	NSFetchRequest *request;
	NSArray *results;
	NSError *error;

	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);

	//fetch request to see if there is already a server by that name in the context
	context = [self managedObjectContext];
	request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[NSEntityDescription entityForName:@"Server" inManagedObjectContext:context]];
	[request setPredicate:[NSPredicate predicateWithFormat:@"(name == %@)",name]];
	results=[context executeFetchRequest:request error:&error];

	//if already there, return it
	if ([results count]>0)
		return [results objectAtIndex:0];
	
	//if not, create it assuming it is an internet address (if a valid netService, it should be already in the managed context, because NSNetService servers only get created through the NSNetServiceBrowser)
	return [self internetServerWithHostname:name];
}

- (void)removeServer:(XGSServer *)aServer
{
	if ( [aServer isConnected] || [aServer isConnecting] || [aServer isAvailable] )
		return;
	if ( [[aServer valueForKeyPath:@"grids.jobs"] count] > 0 )
		return;
	[[self managedObjectContext] deleteObject:aServer];
}

- (XGSServer *)firstConnectedServer
{
	NSManagedObjectContext *context;
	NSFetchRequest *request;
	NSArray *results;
	NSError *error;
	
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	//fetch request to see if there is a connected server in the context
	context = [self managedObjectContext];
	request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[NSEntityDescription entityForName:@"Server" inManagedObjectContext:context]];
	[request setPredicate:[NSPredicate predicateWithFormat:@"(isConnected == 1)"]];
	results=[context executeFetchRequest:request error:&error];
	
	//if already there, return it
	if ([results count]>0)
		return [results objectAtIndex:0];
	else
		return nil;
}

- (XGSServer *)firstAvailableServer
{
	NSManagedObjectContext *context;
	NSFetchRequest *request;
	NSArray *results;
	NSError *error;
	
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	//fetch request to see if there is a connected server in the context
	context = [self managedObjectContext];
	request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[NSEntityDescription entityForName:@"Server" inManagedObjectContext:context]];
	[request setPredicate:[NSPredicate predicateWithFormat:@"(isAvailable == 1)"]];
	results=[context executeFetchRequest:request error:&error];
	
	//if already there, return it
	if ([results count]>0)
		return [results objectAtIndex:0];
	else
		return nil;
}

//returns the first object in the connectedServers
//future implementations might choose the controller with the most resources
- (XGController *)xgridController
{
	NSArray *connectedServers;

	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);

	connectedServers = [self valueForKey:@"connectedServers"];
	if ([connectedServers count]>0) {
		return [[connectedServers objectAtIndex:0] valueForKey:@"xgridController"];
	} else
		return nil;
}

#pragma mark *** browsing services ***

- (NSNetServiceBrowser *)netServiceBrowser
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	if (netServiceBrowser==nil) {
		netServiceBrowser = [[NSNetServiceBrowser alloc] init];
		[netServiceBrowser setDelegate:self];
	}
	return netServiceBrowser;
}

- (void)dealloc;
{
    [netServiceBrowser release];
    [super dealloc];
}

- (void)startBrowsing
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	[[self netServiceBrowser] searchForServicesOfType:XgridServiceType inDomain:XgridServiceDomain];
}

- (void)stopBrowsing
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	[self updateFetchedProperties];
	[netServiceBrowser stop];
}

#pragma mark *** NSNetServiceBrowser delegate methods ***


- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser
             didNotSearch:(NSDictionary *)errorDict;
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser
           didFindService:(NSNetService *)netService
               moreComing:(BOOL)moreComing;
{
	XGSServer *aServer;
	
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);

    aServer=[self bonjourServerWithNetService:netService];
	[aServer setValue:[NSNumber numberWithBool:YES] forKey:@"isAvailable"];
	[aServer setValue:[NSNumber numberWithBool:YES] forKey:@"wasAvailableInCurrentSession"];
	[aServer setValue:[NSNumber numberWithBool:YES] forKey:@"wasAvailableInPreviousSession"];

	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s (server = <%@:%p> = %@",[self class],self,_cmd,[aServer class],aServer,[aServer valueForKey:@"name"]);
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser
         didRemoveService:(NSNetService *)netService
               moreComing:(BOOL)moreComing;
{
	XGSServer *aServer;
    
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);

	aServer=[self bonjourServerWithNetService:netService];
	[aServer setValue:[NSNumber numberWithBool:NO] forKey:@"isAvailable"];

	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s (server = <%@:%p> = %@",[self class],self,_cmd,[aServer class],aServer,[aServer valueForKey:@"name"]);
}

@end
