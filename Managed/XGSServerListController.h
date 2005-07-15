//
//  XGSServerListController.h
//  GridStuffer
//
//  Created by Charles Parnot on 5/18/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//

/*
 This file is part of GridStuffer.
 GridStuffer is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
 GridStuffer is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with Foobar; if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

@class XGSServerList;
@class XGSServer;

@interface XGSServerListController : NSWindowController
{
	XGSServerList *serverList;

	//for the main window
	IBOutlet NSArrayController *serverArrayController;
	IBOutlet NSTextField *serverAddressTextField;
	IBOutlet NSButton *mainWindowConnectButton;

	//for the connection sheet
	XGSServer *currentServer;
	IBOutlet NSWindow *connectSheet;
	IBOutlet NSMatrix *authenticationTypeMatrix;
	IBOutlet NSTextField *serverNameField;
	IBOutlet NSSecureTextField *passwordField;
	IBOutlet NSTextField *authenticationFailedTextField;
	BOOL isConnecting;
	//BOOL shouldEnableConnectButton;
}

//connect to the selected server or use the address typed in the text field
- (IBAction)connect:(id)sender;
- (IBAction)cancelConnect:(id)sender;
- (IBAction)removeSelectedServer:(id)sender;

//initiate the connection process for the first available server, if any
- (IBAction)connectToFirstAvailableServer:(id)sender;

@end
