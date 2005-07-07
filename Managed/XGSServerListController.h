//
//  XGSServerListController.h
//  GridStuffer
//
//  Created by Charles Parnot on 5/18/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//


@class XGSServerList;
@class XGSServer;

@interface XGSServerListController : NSWindowController
{
	XGSServerList *serverList;

	//for the main window
	IBOutlet NSArrayController *serverArrayController;
	IBOutlet NSTextField *serverAddressTextField;
	
	//for the connection
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
