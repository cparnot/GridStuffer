//
//  XGSServerBrowser.h
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
The XGSServerBrowser is a singleton class. The singleton is retrieved using the class method 'sharedServerBrowser'.
 
The singleton instance does three things:

- Browsing for Xgrid controllers that advertise their services using the Bonjour technology in the local network

- Saving the servers on a persistent store located in the 'Application Support' folder; this persistent store is shared at the application level; there is only one and it is setup automatically by the XGSServerBrowser singleton instance

You can use the XGSServerBrowser singleton instance to retrieve all the servers saved in store, or just one XGSServer instance for a given address. The address does not have to correspond to one of the server available on the local network, but can be a distant address too. In all cases, the returned instance is added to the managed object context corresponding to the persisetent store saved in the Application Support folder.

*/

@class XGSServer;

@interface XGSServerBrowser : NSObject
{
    NSNetServiceBrowser *netServiceBrowser;
}

//it is best to only use the singleton instance
+ (XGSServerBrowser *)sharedServerBrowser;

//methods used to start and stop browsing for Xgrid servers avertising on Bonjour
//the servers found get automatically added to the application-level persistent store
- (void)startBrowsing;
- (void)stopBrowsing;

@end
