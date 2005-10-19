//
//  XGSServerConnection.h
//  GridStuffer
//
//  Created by Charles Parnot on 8/2/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*
 The XGSServerConnection class is a private class.
 
 The XGSServerConnection class is a wrapper around the XGController and XGConnection class provided by the Xgrid APIs. The implementation ensures that there is only one instance of XGSServerConnection for each different address, which ensures that network traffic, notifications,... are not duplicated when communicating with the same server. The XGSServer class use the XGSServerConnection class for its network operations. There might thus be several XGSServer objects (living in different managed contexts, see the header) that all use the same XGSServerConnection. The XGSServeConnection sends notifications to keep the XGSServer objects in sync.

So the two classes, XGSServerConnection & XGSServer, are somewhat coupled, though the implementation tries to keep them encapsulated.
*/


//Constants to use to subscribe to notifications
APPKIT_EXTERN NSString *XGSServerConnectionDidConnectNotification;
APPKIT_EXTERN NSString *XGSServerConnectionDidNotConnectNotification;
APPKIT_EXTERN NSString *XGSServerConnectionDidDisconnectNotification;
APPKIT_EXTERN NSString *XGSServerConnectionDidLoadNotification;

@interface XGSServerConnection : NSObject
{
	XGConnection *xgridConnection;
	XGController *xgridController;
	NSString *serverName;
	NSString *serverPassword;
	int serverConnectionState; //private enum
	
	//keeping track of connection attempts
	NSArray *connectionSelectors;
	NSEnumerator *selectorEnumerator;
}

- (id)initWithAddress:(NSString *)address password:(NSString *)password;
+ (XGSServerConnection *)serverConnectionWithAddress:(NSString *)address password:(NSString *)password;

//accessors
- (XGConnection *)xgridConnection;
- (XGController *)xgridController;
- (void)setPassword:(NSString *)newPassword;
- (BOOL)isConnecting;
- (BOOL)isConnected;
- (BOOL)isLoaded;

//connection
- (void)connect;
- (void)disconnect;
- (void)connectWithoutAuthentication;
- (void)connectWithPassword;
- (void)connectWithSingleSignOnCredentials;

@end
