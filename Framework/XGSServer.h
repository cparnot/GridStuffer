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
The XGSServer instances are managed objects that expose a simple interface for Xgrid Controllers. Behind the scenes, this class uses a number of other private classes for the server connections, the creation of an application-wide shared managed object context and browsing the local network for servers advertising their services.

To make sure everything works as expected, instances of XGSServer should only be created/retrieved using the public methods listed here. There are three ways to create/retrieve XGSServer instances:
 - using the class method '+allServers'. The returned array contain servers already connected, but also servers that were connected to in previous sessions (saved in a persistent store) and "available" servers found on the local network (when browsing was started using the 'startBrowsing', found servers are automatically added).
 - using the class method '+serverWithAddress:', which may create a new instance or retrieve an existing record from the shared managed object context created by the framework
 - using the class method '+serverWithAddress:managedObjectContext:', which you can use to create and retrieve server objects in a custom managed object context; to "copy" an existing XGSServer into a different managed object context, you can use '-serverInManagedObjectContext:'
 
These methods ensure that only one instance of XGSServer exists per server address and per managed object context. Once retrieved, the returned instance can be retained as long as needed, and will remain valid and in sync until released. However, it is possible that several instances with the same server address may exist in different managed object contexts. This is fine: connection and network traffic will not be duplicated. The connection process itself is shared by all XGSServer instances with the same address, and these instances are guaranteed to be kept in sync all the time.

To start the connection, call one of the -connect... method.
Then use a delegate or notifications to keep track of the connection status asynchronously.

IMPORTANT: in the current implementation, the password will NOT be saved to disk.
*/


//Constants to use to subscribe to notifications received in response to the connect call
//no delegate as there is only one instance of server per address; thus, several client objects trying to be delegate could overwrite each other in unpredictable ways
APPKIT_EXTERN NSString *XGSServerDidConnectNotification;
APPKIT_EXTERN NSString *XGSServerDidNotConnectNotification;
APPKIT_EXTERN NSString *XGSServerDidDisconnectNotification;

//after connection, it might take a while before the object loads all the information from the server: how many grids,...
APPKIT_EXTERN NSString *XGSServerDidLoadNotification;


@class XGSServerConnection;
@class XGSGrid;
@class XGSJob;

@interface XGSServer : XGSManagedObject
{
	XGSServerConnection *serverConnection;
	id delegate;
}

//Creating server instances
//Server instances are added to the default persistent store (see XGSFrameworkSettings), that can be used with bindings to display an automatically updated list of all the servers in the GUI
+ (void)startBrowsing;
+ (void)stopBrowsing;
+ (NSArray *)allServers;
+ (XGSServer *)serverWithAddress:(NSString *)address;

//New instances are always added to the default persistent store (see XGSFrameworkSettings), but using this method, a server can in addition be attached to a custom context (e.g. for document-based app)
//Instances are guaranteed to be unique for a given address and a given managed object context, but you will get two different instances for servers with the same addresses on 2 separate contexts 
+ (XGSServer *)serverWithAddress:(NSString *)address inManagedObjectContext:(NSManagedObjectContext *)context;

//Connecting (either automatically or using a specific protocol)
- (void)connect;
- (void)disconnect;
- (void)connectWithoutAuthentication;
- (void)connectWithSingleSignOnCredentials;
- (void)connectWithPassword:(NSString *)password;

//Submitting jobs using the default grid (notifications received by the XGSJob object, see header for that class)
//The XGSJob is added to the same managed object context as the server
//To submit jobs to different grids, use XGSGrid class instead
- (XGSJob *)submitJobWithSpecifications:(NSDictionary *)specs;


//KVO/KVC-compliant accessors
- (NSString *)address;
- (XGSGrid *)defaultGrid;
- (NSSet *)grids; //XGSGrid objects, not XGGrid
- (NSSet *)jobs; //XGSJob objects, not XGJob
- (BOOL)isAvailable;
- (BOOL)isConnecting;
- (BOOL)isConnected;
- (BOOL)isLoaded;
- (NSString *)statusString;
- (BOOL)shouldRememberPassword;
- (void)setShouldRememberPassword:(BOOL)flag;
- (void)setPassword:(NSString *)aString;

//low-level accessors
- (XGController *)xgridController;
- (XGConnection *)xgridConnection;
- (NSArray *)xgridGrids; //array of XGGrid
- (NSArray *)xgridJobs;  //array of XGJob



//see below, the informal protocol for the delegate and notifications
- (id)delegate;
- (void)setDelegate:(id)newDelegate;


@end

/*
//methods that can be implemented by the delegate
@interface NSObject (XGSServerDelegate)
- (void)serverDidConnect:(XGSServer *)aServer;
- (void)serverDidNotConnect:(XGSServer *)aServer;
- (void)serverDidDisconnect:(XGSServer *)aServer;
//- (void)server:(XGSServer *)aServer didAddGrid:(XGSGrid *)aGrid;
//- (void)server:(XGSServer *)aServer didRemoveGrid:(XGSGrid *)aGrid;
@end
*/