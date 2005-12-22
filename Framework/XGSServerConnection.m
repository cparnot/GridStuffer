//
//  XGSServerConnection.m
//  GridStuffer
//
//  Created by Charles Parnot on 8/2/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "XGSServerConnection.h"

/*

From birth to death, an XGSServerConnection object goes through a series of states.
 
1. Uninitialized. This is the state when the object is first created using 'initWithAddress:password:'. However, if there was already an instance with the same address, the object returned is the intance already existing
 
2. Connecting. This is the state after calling 'connect' or one of the similar public methods. Behind the scenes, the object actually makes several connection attempts before giving up, starting with the most likely to succed protocol until the least likely. These different connection attempts are the methods 'connect_B1', 'connect_B2',... that try connections via Bonjour or internet, and authentications with/without password or Kerberos single sign-on. So, depending on the value of the address and the password, the object will decide on a series of methods to try in a certain order (stored in connectionSelectors). For each of these attempts, the object will go through these calls:
	- 'startNextConnectionAttempt'
	- if there is no connection attempt left, switch to a 'Failed' state and send notification 
	- if there is one connection attempt left
		- call the corresponding method 'connect_XX', which will create a new XGConnection object each time
		- wait for callback (asynchronouly)
		- if callback is 'connectionDidOpen', switch to a 'Connected' state and send notification
		- if callback is 'connectionDidNotOpen' of 'connectionDidClose', start next connection attempt

3. Connected. The server is now connected, but it only means that the object 'XGConnection' is ready. We now have to wait for the object XGController to be ready. This will happen when its state is set to 'available' and the list of its XGGrid objects is loaded from the server. To keep track of that, we can use KVO on the XGController state. When the state changes, it means the XgridFoundation framework has received the information and is changing all the values of the different instance variables of the XGController object. Then, we know the object will be 'ready', or 'loaded', on the next iteration of the run loop. So, here is the process:
	- set self as observer of the XGController:
		[xgridController addObserver:self forKeyPath:@"state" options:0 context:NULL];
	- wait for the callback
	- when the state changes, call a timer with an interval of 0:
		 [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(controllerDidLoadInstanceVariables:) userInfo:nil repeats:NO];
	- on the next iteration of the run loop, change state to 'Loaded' and send notification
 
4. Loaded. The list of grids and the state of the XGController objects are set. We will now keep an eye on the list of grids to modify the various objects dependent on the grids as needed. ##NOT IMPLEMENTED YET##

*/


//the state changes as the connection progresses from not being connected to having loaded all the attributes of the server
typedef enum {
	XGSServerConnectionStateUninitialized = 1,
	XGSServerConnectionStateConnecting,
	XGSServerConnectionStateConnected,
	XGSServerConnectionStateLoaded,
	XGSServerConnectionStateDisconnected,
	XGSServerConnectionStateFailed
} XGSServerConnectionState;

//global constants used for notifications
NSString *XGSServerConnectionDidConnectNotification = @"XGSServerConnectionDidConnectNotification";
NSString *XGSServerConnectionDidLoadNotification = @"XGSServerConnectionDidLoadNotification";
NSString *XGSServerConnectionDidNotConnectNotification = @"XGSServerConnectionDidNotConnectNotification";
NSString *XGSServerConnectionDidDisconnectNotification = @"XGSServerConnectionDidDisconnectNotification";


@implementation XGSServerConnection


#pragma mark *** Class Methods ***

//this dictionary keeps track of the instances already created, so that there is only one instance of XGSServerConnection per address
NSMutableDictionary *serverConnectionInstances=nil;

//the serverConnectionInstances dictionary is created early on when the class is initialized
//I chose not to do lazy instanciation as there is only one dictionary created and the memory footprint is really small
//it is just simpler this way and probably less prone to future problems (e.g. multithreading?)
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

//this method should never be called, as the only allowed initializer takes an address as parameter
//calling 'init' raises an expection
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
	//there is a memory management gotcha, as the instance get retained when added to the global dictionary 'serverConnectionInstances', so we have to be careful to release self after adding it to the dictionary, or retaining the instance if already in the dictionary, and then to retain the instance before removing it from the dictionary in the dealloc method
	id uniqueInstance;
	if ( uniqueInstance = [serverConnectionInstances objectForKey:address] ) {
		[self release];
		self = [uniqueInstance retain];
	} else {
		self = [super init];
		if ( self !=  nil ) {
			serverName = [address copy];
			serverPassword = [password copy];
			xgridController = nil;
			xgridConnection = nil;
			serverConnectionState = XGSServerConnectionStateUninitialized;
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

- (NSString *)shortDescription
{
	return [NSString stringWithFormat:@"Server Connection to '%@' (state %d)", serverName, serverConnectionState];
}

#pragma mark *** Accessors ***

//public
//do not return xgridConnection object that are transient and may be dumped later
- (XGConnection *)xgridConnection
{
	if ( serverConnectionState == XGSServerConnectionStateConnecting )
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

- (BOOL)isConnecting
{
	return serverConnectionState == XGSServerConnectionStateConnecting;
}

- (BOOL)isConnected
{
	return serverConnectionState == XGSServerConnectionStateConnected || serverConnectionState == XGSServerConnectionStateLoaded;
}

- (BOOL)isLoaded
{
	return serverConnectionState == XGSServerConnectionStateLoaded;
}


#pragma mark *** Private connection methods ***

//trying to use a Bonjour connection without password
- (void)connect_B1
{
	DLog(NSStringFromClass([self class]),12,@"<%@:%p> %s",[self class],self,_cmd);
	
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
	DLog(NSStringFromClass([self class]),12,@"<%@:%p> %s",[self class],self,_cmd);
	
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
	DLog(NSStringFromClass([self class]),12,@"<%@:%p> %s",[self class],self,_cmd);
	
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
	DLog(NSStringFromClass([self class]),12,@"<%@:%p> %s",[self class],self,_cmd);
	
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
	DLog(NSStringFromClass([self class]),12,@"<%@:%p> %s",[self class],self,_cmd);
	
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
	DLog(NSStringFromClass([self class]),12,@"<%@:%p> %s",[self class],self,_cmd);
	
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
	DLog(NSStringFromClass([self class]),12,@"<%@:%p> %s",[self class],self,_cmd);

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
		serverConnectionState = XGSServerConnectionStateFailed;
		[[NSNotificationCenter defaultCenter] postNotificationName:XGSServerConnectionDidNotConnectNotification object:self];
	}
}

#pragma mark *** XGConnection delegate methods, going from "Connecting" to "Connected" ***

- (void)connectionDidOpen:(XGConnection *)connection;
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	//create the XGController object
	[xgridController release];
	xgridController = [[XGController alloc] initWithConnection:xgridConnection];
	
	//clean-up
	[self setConnectionSelectors:nil];
	
	//change the current state
	serverConnectionState= XGSServerConnectionStateConnected;
	[[NSNotificationCenter defaultCenter] postNotificationName:XGSServerConnectionDidConnectNotification object:self];
	
	//next step is to get the controller 'available' = all the grids and jobs loaded from the server
	[xgridController addObserver:self forKeyPath:@"state" options:0 context:NULL];
}

- (void)connectionDidNotOpen:(XGConnection *)connection withError:(NSError *)error
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	if ( serverConnectionState == XGSServerConnectionStateConnecting )
		[self startNextConnectionAttempt];
	else {
		serverConnectionState = XGSServerConnectionStateDisconnected;
		[[NSNotificationCenter defaultCenter] postNotificationName:XGSServerConnectionDidDisconnectNotification object:self];
	}
}

- (void)connectionDidClose:(XGConnection *)connection;
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	if ( serverConnectionState == XGSServerConnectionStateConnecting )
		[self startNextConnectionAttempt];
	else {
		serverConnectionState = XGSServerConnectionStateDisconnected;
		[[NSNotificationCenter defaultCenter] postNotificationName:XGSServerConnectionDidDisconnectNotification object:self];
	}
}


#pragma mark *** XGController observing, going from "Connected" to "Loaded" ***

//when the state of the XGController is modified by the XgridFoundation framework, we know all its instance variables will be set by the end of this run loop
//so we call a timer with interval 0 to be back when all the instance variables are set (e.g. grids,...)
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@\nObject = <%@:%p>\nKey Path = %@\nChange = %@",[self class],self,_cmd, [self shortDescription], [object class], object, keyPath, [change description]);

	if ( serverConnectionState == XGSServerConnectionStateConnected ) {
		if ( [xgridController state] == XGResourceStateAvailable ) {
			[xgridController removeObserver:self forKeyPath:@"state"];
			[NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(controllerDidLoadInstanceVariables:) userInfo:nil repeats:NO];
		}
	} else {
		[xgridController removeObserver:self forKeyPath:@"state"];
	}
}

//callback on the iteration of the run loop following the change in the state of the XGController
- (void)controllerDidLoadInstanceVariables:(NSTimer *)aTimer
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);

	if ( serverConnectionState == XGSServerConnectionStateConnected && [xgridController state] == XGResourceStateAvailable ) {
		serverConnectionState = XGSServerConnectionStateLoaded;
		[[NSNotificationCenter defaultCenter] postNotificationName:XGSServerConnectionDidLoadNotification object:self];
	}
}


#pragma mark *** Public connection methods ***

//function used to decide is an address string is likely to be that of a remote host or of a local (Bonjour) server
BOOL isRemoteHost (NSString *anAddress)
{
	if ( [anAddress isEqualToString:@"localhost"] )
		return YES;
	else
		return ( [anAddress rangeOfString:@"."].location != NSNotFound );
	
}



- (void)connectWithoutAuthentication
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);

	//exit if already connecting or connected
	if ( serverConnectionState == XGSServerConnectionStateConnecting || serverConnectionState == XGSServerConnectionStateConnected || serverConnectionState == XGSServerConnectionStateLoaded )
		return;
	
	//change the state of the serverConnection
	serverConnectionState = XGSServerConnectionStateConnecting;
	
	//decide on the successive attempts that will be made to connect
	//the choice depends on the address name (Bonjour or remote?) and on the password
	NSArray *selectors = nil;
	if ( isRemoteHost(serverName) )
		selectors = [NSArray arrayWithObjects:@"H1",@"H2",@"B1",@"B2",nil];
	else
		selectors = [NSArray arrayWithObjects:@"B1",@"B2",@"H1",@"H2",nil];
	[self setConnectionSelectors:selectors];
	
	//start the connection process
	[self startNextConnectionAttempt];
}

- (void)connectWithSingleSignOnCredentials
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);

	//exit if already connecting or connected
	if ( serverConnectionState == XGSServerConnectionStateConnecting || serverConnectionState == XGSServerConnectionStateConnected || serverConnectionState == XGSServerConnectionStateLoaded )
		return;
	
	//change the state of the serverConnection
	serverConnectionState = XGSServerConnectionStateConnecting;
	
	//decide on the successive attempts that will be made to connect
	//the choice depends on the address name (Bonjour or remote?) and on the password
	NSArray *selectors = nil;
	if ( isRemoteHost(serverName) )
		selectors = [NSArray arrayWithObjects:@"H3",@"B3",nil];
	else
		selectors = [NSArray arrayWithObjects:@"B3",@"H3",nil];
	[self setConnectionSelectors:selectors];
	
	//start the connection process
	[self startNextConnectionAttempt];
}

- (void)connectWithPassword
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);

	//exit if already connecting or connected
	if ( serverConnectionState == XGSServerConnectionStateConnecting || serverConnectionState == XGSServerConnectionStateConnected || serverConnectionState == XGSServerConnectionStateLoaded )
		return;
	
	//change the state of the serverConnection
	serverConnectionState = XGSServerConnectionStateConnecting;
	
	//decide on the successive attempts that will be made to connect
	//the choice depends on the address name (Bonjour or remote?) and on the password
	NSArray *selectors = nil;
	if ( isRemoteHost(serverName) )
		selectors = [NSArray arrayWithObjects:@"H2",@"B2",@"H3",@"B3",nil];
	else
		selectors = [NSArray arrayWithObjects:@"B2",@"H2",@"B3",@"H3",nil];
	[self setConnectionSelectors:selectors];
	
	//start the connection process
	[self startNextConnectionAttempt];
}

- (void)connect
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);

	//exit if already connecting or connected
	if ( serverConnectionState == XGSServerConnectionStateConnecting || serverConnectionState == XGSServerConnectionStateConnected || serverConnectionState == XGSServerConnectionStateLoaded )
		return;
	
	//change the state of the serverConnection
	serverConnectionState = XGSServerConnectionStateConnecting;
	
	//decide on the successive attempts that will be made to connect
	//the choice depends on the address name (Bonjour or remote?) and on the password
	NSArray *selectors = nil;
	BOOL remoteHost = isRemoteHost(serverName);
	BOOL usePassword = ( [serverPassword length] > 0 );
	if ( usePassword && remoteHost )
		selectors = [NSArray arrayWithObjects:@"H2",@"B2",@"H1",@"H3",@"B1",@"B3",nil];
	else if ( usePassword && !remoteHost )
		selectors = [NSArray arrayWithObjects:@"B2",@"H2",@"B1",@"B3",@"H1",@"H3",nil];
	else if ( !usePassword && remoteHost )
		selectors = [NSArray arrayWithObjects:@"H1",@"H3",@"B1",@"B3",nil];
	else if ( !usePassword && !remoteHost )
		selectors = [NSArray arrayWithObjects:@"B1",@"B3",@"H1",@"H3",nil];
	[self setConnectionSelectors:selectors];
	
	//start the connection process
	[self startNextConnectionAttempt];
}

- (void)disconnect
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);

	[xgridConnection close];
	if ( serverConnectionState == XGSServerConnectionStateConnecting ) {
		[selectorEnumerator allObjects];
		[self setConnectionSelectors:nil];
	}
}

@end
