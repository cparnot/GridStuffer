//
//  XGSServerConnection.h
//  GridStuffer
//
//  Created by Charles Parnot on 8/2/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*
 The XGSServerConnection class is a private class used by the framework to ensure that
 each Xgrid Server establishes only one connection with the application.
 The uniqueness is based on the server name: one name, one server.
 The uniqueness is enforced at the implementation level by having a static dictionary
 keeping track of created instances, one instance per name.
 
 The XGSServerConnection is really a wrapper around the XGController and XGConnection class
 provided by the Xgrid APIs.
 The XGSServerConnection objects are used by the XGSServer objects to perform network operations.
 The XGSServeConnection sends notifications to keep the XGSServer objects in sync. There might
 be several XGSServer objects for one XGSServerConnection.
 So the two classes XGSServerConnection and XGSServer are somewhat coupled, though the implementation
 tries to keep them encapsulated and separated from each other.
 
*/

//Constants to use to subscribe to notifications
APPKIT_EXTERN NSString *XGSServerConnectionDidConnectNotification;
APPKIT_EXTERN NSString *XGSServerConnectionDidNotConnectNotification;
APPKIT_EXTERN NSString *XGSServerConnectionDidDisconnectNotification;

typedef enum {
	XGSServerConnectionStateUninitialized = 1,
	XGSServerConnectionStateConnecting,
	XGSServerConnectionStateConnected,
	XGSServerConnectionStateDisconnected,
	XGSServerConnectionStateFailed
} XGSServerConnectionState;


@interface XGSServerConnection : NSObject
{
	XGConnection *xgridConnection;
	XGController *xgridController;
	NSString *serverName;
	NSString *serverPassword;
	XGSServerConnectionState serverState;
	
	//keeping track of connection attempts
	NSArray *connectionSelectors;
	NSEnumerator *selectorEnumerator;	
}

- (id)initWithAddress:(NSString *)address password:(NSString *)password;
+ (XGSServerConnection *)serverConnectionWithAddress:(NSString *)address password:(NSString *)password;

- (void)connect;
- (void)disconnect;

/*
- (void)connectWithoutAuthentication;
- (void)connectWithSingleSignOnCredentials;
- (void)connectWithPassword:(NSString *)password;
*/

@end
