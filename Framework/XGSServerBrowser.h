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

The XGSServerBrowser is a private class. To use it, one should first retrieve the singleton instance using the class method 'sharedServerBrowser'. The singleton instance can them be used to browse for Xgrid controllers that advertise their services using the Bonjour technology in the local network. Servers found by the browser will then be added to the list of servers by calling the appropriate XGSServer methods. See the XGSServer class for more details: the server instances are saved in the default managed object context as defined by XGSFrameworkSettings.
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
