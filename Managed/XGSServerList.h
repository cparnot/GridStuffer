//
//  XGSServerList.h
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

/**
The XGSServerList class is used to manage list of XGSServer (wrappers for XGControllers).
It encapsulates the fetch request needed to ensure that each ServerInterface is
present only once in the persistent store of a managed object context.
The XGSServerList is thus the prefered way to retrieve servers.

There should be only one instance of XGSServerList per managed object context,
which can be retrieved with the class method '+sharedServerListForContext:',
It can then be used to create/retrieve servers with the instance method '-serverWithName:'.

*/

@class XGSServer;

@interface XGSServerList : XGSManagedObject
{
    NSNetServiceBrowser *netServiceBrowser;
}

//there is one instance of XGSServerList per context that should only be accessed through this method
+ (XGSServerList *)sharedServerListForContext:(NSManagedObjectContext *)context;

//methods used to start and stop browsing for servers using Bonjour
//servers found get automatically added to the store
- (void)startBrowsing;
- (void)stopBrowsing;

//this is the prefered way to add/retrieve servers
//if no server is found using Bonjour, it will try to use the name as an internet hostname
- (XGSServer *)serverWithName:(NSString *)name;
- (XGSServer *)firstAvailableServer;
- (XGSServer *)firstConnectedServer;

- (void)removeServer:(XGSServer *)aServer;

//retrieve a XGController, if any is connected
//the key "xgridController" is KVO-compliant and can thus be 'observed' (but can not be used for KVC)
//- (XGController *)xgridController;


@end
