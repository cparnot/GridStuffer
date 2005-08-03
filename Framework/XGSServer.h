//
//  XGSServer.h
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

/*
The XGSServer class is a wrapper for the XGController class. Because they are managed objects,
they can be saved and remembered  between sessions, particularly useful for servers
with ip addresses). The connection step is also simpler.

To add and retrieve servers, use the XGSServerList class. Then call one of the
two -connect... method. These methods take care of all the implementation details.
In particular, it will try first to connect without authenticating, and only try
the password or the single sign on if it fails the easy way. 

After calling the connect methods, use KVO on the key 'isConnected' to check
the connection status and get notified when the server is ready.

IMPORTANT: the password will NOT be remembered or saved to disk.
*/

//Constants to use to subscribe to notifications
APPKIT_EXTERN NSString *XGSServerDidConnectNotification;
APPKIT_EXTERN NSString *XGSServerDidNotConnectNotification;
APPKIT_EXTERN NSString *XGSServerDidDisconnectNotification;

@class XGSServerConnection;
@class XGSGrid;

@interface XGSServer : XGSManagedObject
{
	//XGController *xgridController;
	//XGConnection *xgridConnection;
	XGSServerConnection *serverConnection;
	id delegate;
	NSMutableSet *availableGrids;
}

+ (XGSServer *)serverWithAddress:(NSString *)address;

//accessors
- (XGController *)xgridController;
- (XGSGrid *)defaultGrid;

//see below, the informal protocol for the delegate and notifications
- (id)delegate;
- (void)setDelegate:(id)newDelegate;

//after calling these methods, use the delegate or the notifications to be notified asynchronously of the connection results
- (void)connectWithoutAuthentication;
- (void)connectWithSingleSignOnCredentials;
- (void)connectWithPassword:(NSString *)password;
- (void)disconnect;

//These keys can be observed with KVO
//To get a notification that the connection is ready, observe isConnecting until NO, then check if isConnected is YES
- (BOOL)isAvailable;
- (BOOL)isConnected;
- (BOOL)isConnecting;
- (NSString *)statusString;

@end

//methods that can be implemented by the delegate
@interface NSObject (XGSServerDelegate)
- (void)serverDidConnect:(XGSServer *)aServer;
- (void)serverDidNotConnect:(XGSServer *)aServer;
- (void)serverDidDisconnect:(XGSServer *)aServer;
//- (void)server:(XGSServer *)aServer didAddGrid:(XGSGrid *)aGrid;
//- (void)server:(XGSServer *)aServer didRemoveGrid:(XGSGrid *)aGrid;
@end
