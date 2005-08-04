//
//  XGSServerConnection.m
//  GridStuffer
//
//  Created by Charles Parnot on 8/2/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "XGSServerConnection.h"

typedef enum {
	XGSServerConnectionStateUninitialized = 1,
	XGSServerConnectionStateConnecting,
	XGSServerConnectionStateConnected,
	XGSServerConnectionStateAvailable,
	XGSServerConnectionStateDisconnected,
	XGSServerConnectionStateFailed
} XGSServerConnectionState;




@implementation XGSServerConnection


#pragma mark *** Class Methods ***

//this dictionary keeps track of the instances already created
NSMutableDictionary *serverConnectionInstances=nil;

//create the serverConnectionInstances dictionary early on
//I chose not to do lazy instanciation as there is only one dictionary created and the memory footprint is really small
//it is just simpler this way and less prone to future problems (e.g. multithreading)
+ (void)initialize
{
	if ( serverConnectionInstances == nil )
		serverConnectionInstances = [[NSMutableDictionary alloc] init];
}

+ (XGSServerConnection *)serverConnectionWithAddress:(NSString *)address password:(NSString *)password
{
	return [[[self alloc] initWithAddress:address password:password] autorelease];
}



#pragma mark *** Initializations ***

//should not call that method!
- (id)init
{
	if ( [self class] == [XGSServerConnection class] )
		[NSException raise:@"XGSServerConnectionError" format:@"The 'init' method cannot be called on instances of the XGSServerConnection class"];
	return [super init];
}

//designated initializer
//may return an instance already existing
- (id)initWithAddress:(NSString *)address password:(NSString *)password
{
	//do not create a new instance if the address is registered in the serverConnectionInstances dictionary
	id uniqueInstance;
	if ( uniqueInstance = [serverConnectionInstances objectForKey:address] ) {
		[self release];
		self = uniqueInstance;
	} else {
		self = [super init];
		if ( self !=  nil ) {
			serverName = [address copy];
			serverPassword = [password copy];
			xgridController = nil;
			xgridConnection = nil;
			serverState = XGSServerConnectionStateUninitialized;
			connectionSelectors = nil;
			selectorEnumerator = nil;
		}
		[serverConnectionInstances setObject:self forKey:address];
	}
	return self;
}


- (void)dealloc
{
	[xgridConnection setDelegate:nil];
	//[xgridController removeObserver:self forKeyPath:@"grids"];
	[xgridConnection release];
	[xgridController release];
	[serverName release];
	[serverPassword release];
	[super dealloc];
}

#pragma mark *** Accessors ***

//public
//do not return xgridConnection object that are transient and may be dumped later
- (XGConnection *)xgridConnection
{
	if ( serverState == XGSServerConnectionStateConnecting )
		return nil;
	else
		return xgridConnection;
}

//public
- (XGController *)xgridController;
{
	return xgridController;
}


//public
- (void)setPassword:(NSString *)newPassword
{
	[newPassword retain];
	[serverPassword release];
	serverPassword = newPassword;
}

//PRIVATE
//when the xgridConnection is set, always use self as its delegate
- (void)setXgridConnection:(XGConnection *)newXgridConnection
{
	if ( newXgridConnection != xgridConnection ) {
		[xgridConnection setDelegate:nil];
		[xgridConnection release];
		[newXgridConnection retain];
		[newXgridConnection setDelegate:self];
		xgridConnection = newXgridConnection;
	}
}

//PRIVATE
//when the connectionSelectors is set, also reset the selectorEnumerator
- (void)setConnectionSelectors:(NSArray *)anArray
{
	//set the connectionSelectors array
	[anArray retain];
	[connectionSelectors release];
	connectionSelectors = anArray;
	
	//reset the selectorEnumerator
	[selectorEnumerator release];
	if ( anArray == nil )
		selectorEnumerator = nil;
	else
		selectorEnumerator = [[connectionSelectors objectEnumerator] retain];
}

#pragma mark *** Private connection methods ***

//trying to use a Bonjour connection without password
- (void)connect_B1
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	//create a new XGConnection with a NSNetService
	NSNetService *netService = [[NSNetService alloc] initWithDomain:@"local."
															   type:@"_xgrid._tcp."
															   name:serverName];
	XGConnection *newConnection = [[XGConnection alloc] initWithNetService:netService];
	[netService release];
	
	//set the authenticator
	[newConnection setAuthenticator:nil];
	
	//... and go!!
	[self setXgridConnection:newConnection];
	[newConnection open];
	[newConnection release];
}

//trying to use a Bonjour connection with a password
- (void)connect_B2
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	//create a new XGConnection with a NSNetService
	NSNetService *netService = [[NSNetService alloc] initWithDomain:@"local."
															   type:@"_xgrid._tcp."
															   name:serverName];
	XGConnection *newConnection = [[XGConnection alloc] initWithNetService:netService];
	[netService release];
	
	//set the authenticator
	XGTwoWayRandomAuthenticator *authenticator = [[XGTwoWayRandomAuthenticator alloc] init];
	[authenticator setUsername:@"one-xgrid-client"];
	[authenticator setPassword:serverPassword];
	[newConnection setAuthenticator:authenticator];
	[authenticator release];
	
	//... and go!!
	[self setXgridConnection:newConnection];
	[newConnection open];
	[newConnection release];
}

//trying to use a Bonjour connection with Kerberos
- (void)connect_B3
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	//create a new XGConnection with a NSNetService
	NSNetService *netService = [[NSNetService alloc] initWithDomain:@"local."
															   type:@"_xgrid._tcp."
															   name:serverName];
	XGConnection *newConnection = [[XGConnection alloc] initWithNetService:netService];
	[netService release];
	
	//set the authenticator
	XGGSSAuthenticator *authenticator = [[XGGSSAuthenticator alloc] init];
	NSString *servicePrincipal = [newConnection servicePrincipal];
	if (servicePrincipal == nil)
		servicePrincipal=[NSString stringWithFormat:@"xgrid/%@", [newConnection name]];		
	[authenticator setServicePrincipal:servicePrincipal];
	[newConnection setAuthenticator:authenticator];
	[authenticator release];
	
	//... and go!!
	[self setXgridConnection:newConnection];
	[newConnection open];
	[newConnection release];
}

//fourth attempt to connect
//trying to use a remote connection without a password
- (void)connect_H1
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	//create a new XGConnection
	XGConnection *newConnection = [[XGConnection alloc] initWithHostname:serverName portnumber:0];
	
	//set the authenticator
	[newConnection setAuthenticator:nil];
	
	//... and go!!
	[self setXgridConnection:newConnection];
	[newConnection open];
	[newConnection release];
}

//trying to use a remote connection with a password
- (void)connect_H2
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	//create a new XGConnection
	XGConnection *newConnection = [[XGConnection alloc] initWithHostname:serverName portnumber:0];
	
	//set the authenticator
	XGTwoWayRandomAuthenticator *authenticator = [[XGTwoWayRandomAuthenticator alloc] init];
	[authenticator setUsername:@"one-xgrid-client"];
	[authenticator setPassword:serverPassword];
	[newConnection setAuthenticator:authenticator];
	[authenticator release];
	
	//... and go!!
	[self setXgridConnection:newConnection];
	[newConnection open];
	[newConnection release];
}

//trying to use a remote connection with Kerberos
- (void)connect_H3
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	//create a new XGConnection
	XGConnection *newConnection = [[XGConnection alloc] initWithHostname:serverName portnumber:0];
	
	//set the authenticator
	XGGSSAuthenticator *authenticator = [[XGGSSAuthenticator alloc] init];
	NSString *servicePrincipal = [newConnection servicePrincipal];
	if (servicePrincipal == nil)
		servicePrincipal=[NSString stringWithFormat:@"xgrid/%@", [newConnection name]];		
	[authenticator setServicePrincipal:servicePrincipal];
	[newConnection setAuthenticator:authenticator];
	[authenticator release];
	
	//... and go!!
	[self setXgridConnection:newConnection];
	[newConnection open];
	[newConnection release];
}

- (void)startNextConnectionAttempt
{
	//depending on the hostname and password values, we have decided on a series of connection type to make,
	//as defined by the array connectionSelectors, enumerated by selectorEnumerator
	NSString *selectorString = [selectorEnumerator nextObject];
	
	//if there is still one selector to try, go ahead
	if ( selectorString != nil ) {
		selectorString = [@"connect_" stringByAppendingString:selectorString];
		SEL selector = NSSelectorFromString (selectorString);
		[self performSelector:selector];
	}
	
	//otherwise, the connection failed
	else {
		[self setXgridConnection:nil];
		[self setConnectionSelectors:nil];
		serverState = XGSServerConnectionStateFailed;
		[[NSNotificationCenter defaultCenter] postNotificationName:XGSServerConnectionDidNotConnectNotification object:self];
	}
}

#pragma mark *** XGConnection delegate methods and XGController observing ***

- (void)connectionDidOpen:(XGConnection *)connection;
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	//create the XGController object
	[xgridController release];
	xgridController = [[XGController alloc] initWithConnection:xgridConnection];
	
	//clean-up
	[self setConnectionSelectors:nil];
	
	//change the current state
	serverState= XGSServerConnectionStateConnected;
	[[NSNotificationCenter defaultCenter] postNotificationName:XGSServerConnectionDidConnectNotification object:self];
	
	//next step is to get the controller 'available' = all the grids and jobs loaded from the server
	[xgridController addObserver:self forKeyPath:@"state" options:0 context:NULL];
}

//when the XGController state = XGResourceStateAvailable, the XGController object has all the info (grids and jobs)
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ( serverState == XGSServerConnectionStateConnected ) {
		if ( [xgridController state] == XGResourceStateAvailable ) {
			[xgridController removeObserver:self forKeyPath:@"state"];
			serverState = XGSServerConnectionStateAvailable;
			[[NSNotificationCenter defaultCenter] postNotificationName:XGSServerConnectionDidBecomeAvailableNotification object:self];
		}
	} else {
		[xgridController removeObserver:self forKeyPath:@"state"];
	}
}

- (void)connectionDidNotOpen:(XGConnection *)connection withError:(NSError *)error
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	if ( serverState == XGSServerConnectionStateConnecting )
		[self startNextConnectionAttempt];
	else {
		serverState = XGSServerConnectionStateDisconnected;
		[[NSNotificationCenter defaultCenter] postNotificationName:XGSServerConnectionDidDisconnectNotification object:self];
	}
}

- (void)connectionDidClose:(XGConnection *)connection;
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	if ( serverState == XGSServerConnectionStateConnecting )
		[self startNextConnectionAttempt];
	else {
		serverState = XGSServerConnectionStateDisconnected;
		[[NSNotificationCenter defaultCenter] postNotificationName:XGSServerConnectionDidDisconnectNotification object:self];
	}
}


#pragma mark *** Public connection methods ***

- (void)connectWithoutAuthentication
{
	//exit if already connecting or connected
	if ( serverState == XGSServerConnectionStateConnecting || serverState == XGSServerConnectionStateConnected || serverState == XGSServerConnectionStateAvailable )
		return;
	
	//change the state of the serverConnection
	serverState = XGSServerConnectionStateConnecting;
	
	//decide on the successive attempts that will be made to connect
	//the choice depends on the address name (Bonjour or remote?) and on the password
	NSArray *selectors = nil;
	BOOL isRemoteHost = ( [serverName rangeOfString:@"."].location != NSNotFound );
	if ( isRemoteHost )
		selectors = [NSArray arrayWithObjects:@"H1",@"H2",@"B1",@"B2",nil];
	else
		selectors = [NSArray arrayWithObjects:@"B1",@"B2",@"H1",@"H2",nil];
	
	//start the connection process
	[self startNextConnectionAttempt];
}

- (void)connectWithSingleSignOnCredentials
{
	//exit if already connecting or connected
	if ( serverState == XGSServerConnectionStateConnecting || serverState == XGSServerConnectionStateConnected || serverState == XGSServerConnectionStateAvailable )
		return;
	
	//change the state of the serverConnection
	serverState = XGSServerConnectionStateConnecting;
	
	//decide on the successive attempts that will be made to connect
	//the choice depends on the address name (Bonjour or remote?) and on the password
	NSArray *selectors = nil;
	BOOL isRemoteHost = ( [serverName rangeOfString:@"."].location != NSNotFound );
	if ( isRemoteHost )
		selectors = [NSArray arrayWithObjects:@"H2",@"B2",nil];
	else
		selectors = [NSArray arrayWithObjects:@"B2",@"H2",nil];
	
	//start the connection process
	[self startNextConnectionAttempt];
}

- (void)connectWithPassword
{
	//exit if already connecting or connected
	if ( serverState == XGSServerConnectionStateConnecting || serverState == XGSServerConnectionStateConnected || serverState == XGSServerConnectionStateAvailable )
		return;
	
	//change the state of the serverConnection
	serverState = XGSServerConnectionStateConnecting;
	
	//decide on the successive attempts that will be made to connect
	//the choice depends on the address name (Bonjour or remote?) and on the password
	NSArray *selectors = nil;
	BOOL isRemoteHost = ( [serverName rangeOfString:@"."].location != NSNotFound );
	if ( isRemoteHost )
		selectors = [NSArray arrayWithObjects:@"H2",@"B2",@"H3",@"B3",nil];
	else
		selectors = [NSArray arrayWithObjects:@"B2",@"H2",@"B3",@"H3",nil];
	
	//start the connection process
	[self startNextConnectionAttempt];
}

- (void)connect
{
	//exit if already connecting or connected
	if ( serverState == XGSServerConnectionStateConnecting || serverState == XGSServerConnectionStateConnected || serverState == XGSServerConnectionStateAvailable )
		return;
	
	//change the state of the serverConnection
	serverState = XGSServerConnectionStateConnecting;
	
	//decide on the successive attempts that will be made to connect
	//the choice depends on the address name (Bonjour or remote?) and on the password
	NSArray *selectors = nil;
	BOOL isRemoteHost = ( [serverName rangeOfString:@"."].location != NSNotFound );
	BOOL usePassword = ( [serverPassword length] > 0 );
	if ( usePassword && isRemoteHost )
		selectors = [NSArray arrayWithObjects:@"H2",@"B2",@"H1",@"H3",@"B1",@"B3",nil];
	else if ( usePassword && !isRemoteHost )
		selectors = [NSArray arrayWithObjects:@"B2",@"H2",@"B1",@"B3",@"H1",@"H3",nil];
	else if ( !usePassword && isRemoteHost )
		selectors = [NSArray arrayWithObjects:@"H1",@"H3",@"B1",@"B3",nil];
	else if ( !usePassword && !isRemoteHost )
		selectors = [NSArray arrayWithObjects:@"B1",@"B3",@"H1",@"H3",nil];
	[self setConnectionSelectors:selectors];
	
	//start the connection process
	[self startNextConnectionAttempt];
}

- (void)disconnect
{
	[xgridConnection close];
	if ( serverState == XGSServerConnectionStateConnecting ) {
		[selectorEnumerator allObjects];
		[self setConnectionSelectors:nil];
	}
}

@end
