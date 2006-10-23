//
//  XGSServerListController.m
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

#import "XGSServerListController.h"
#import "XGSServerBrowser.h"
#import "XGSServer.h"
#import "XGSStringToImageTransformer.h"

@implementation XGSServerListController

+ (void)initialize
{
	XGSStringToImageTransformer *transformer;
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	//register the string --> image transformer
	transformer = [[[XGSStringToImageTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"XGSStringToImageTransformer"];
}

- (id)init
{
	NSManagedObjectContext *context;
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	self = [super initWithWindowNibName:@"Servers"];
	if (self!=nil) {
		context = [[NSApp delegate] managedObjectContext];
		//serverList = [[XGSServerBrowser sharedServerListForContext:context] retain];
		isConnecting = NO;
		[self setWindowFrameAutosaveName:@"XGSServerListWindow"];
	}
	return self;
}

- (void)awakeFromNib
{
	[XGSServer startBrowsing];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self]; 
	//[serverList release];
	[super dealloc];
}

#pragma mark *** Glue code for the connection ***

- (XGSServer *)selectedServerInTheTableView
{
	NSArray *servers;
	servers = [serverArrayController selectedObjects];
	if ( [servers count] == 1 )
		return [servers objectAtIndex:0];
	else
		return nil;
}

//returns the server with the name typed in the text field or the one selected in the table view
- (XGSServer *)selectedServer
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);

	//if the text view has the focus and is not empty, use that for the server
	if ( [[self window] firstResponder] ) {
		NSString *address =  [serverAddressTextField stringValue];
		if ( [address length] > 0 )
			return [XGSServer serverWithAddress:address];
	}
	
	//otherwise, use the server selected in the table view, if any
	return [self selectedServerInTheTableView];
}

- (void)startConnectionProcessWithServer:(XGSServer *)aServer
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);

	if ( isConnecting || [[self window] attachedSheet] )
		return;
	
	if ([aServer isConnected])
		return;
	
	//change the Connect button into a Cancel button
	[mainWindowConnectButton setKeyEquivalent:@"\e"];
	[mainWindowConnectButton setTitle:@"Cancel"];
	[mainWindowConnectButton setAction:@selector(cancelConnect:)];
	
	//start the connection
	currentServer = [aServer retain];
	[self setValue:[NSNumber numberWithBool:YES] forKey:@"isConnecting"];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverDidConnectNotification:) name:XGSServerDidConnectNotification object:aServer];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverDidNotConnectNotification:) name:XGSServerDidNotConnectNotification object:aServer];
	[currentServer connectWithoutAuthentication];
}

- (void)endConnectionProcess
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	//change the Cancel button into a Connect button
	[mainWindowConnectButton setKeyEquivalent:@"\r"];
	[mainWindowConnectButton setTitle:@"Connect"];
	[mainWindowConnectButton setAction:@selector(connect:)];

	//reset the currentServer
	[[NSNotificationCenter defaultCenter] removeObserver:self]; 
	[currentServer release];
	currentServer = nil;
	[self setValue:[NSNumber numberWithBool:NO] forKey:@"isConnecting"];
	
	//remove the connect sheet if open
	if ( [[self window] attachedSheet] ) {
		[passwordField setStringValue:@""];
		[NSApp endSheet:connectSheet];
		[connectSheet orderOut:self];
	}
}


//triggered by the user when typing a password in the connect sheet
//the radio button is then automatically selected
- (void)controlTextDidBeginEditing:(NSNotification *)aNotification
{
	[[authenticationTypeMatrix cellWithTag:1] performClick:self];
}


- (void)serverDidNotConnectNotification:(NSNotification *)aNotification
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	if ( [aNotification object] != currentServer ) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:[aNotification object]];
		return;
	}
	[self setValue:[NSNumber numberWithBool:NO] forKey:@"isConnecting"];
	//if the authentication sheet is already on, then it means the authentication failed
	if ( [[self window] attachedSheet] )
		[authenticationFailedTextField setHidden:NO];
	//otherwise, it means we need to ask authentication from the user
	else {
		[authenticationFailedTextField setHidden:YES];
		[serverNameField setStringValue:[currentServer address]];
		[NSApp beginSheet:connectSheet modalForWindow:[self window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
	}
}

- (void)serverDidConnectNotification:(NSNotification *)aNotification
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	if ( [aNotification object] != currentServer ) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:[aNotification object]];
		return;
	}
	[self endConnectionProcess];
}


#pragma mark *** User actions ***

- (IBAction)connect:(id)sender
{	
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	if (isConnecting)
		return;
	
	//if the 'connect' button is from the main window, first try to connect without anthentication
	if ( [sender tag] == 1 ) {
		currentServer = [self selectedServer];
		[self startConnectionProcessWithServer:currentServer];
	}
	
	//if the 'connect' button is from the connect sheet, connect with authentication
	if ( [sender tag] == 2 ) {
		[authenticationFailedTextField setHidden:YES];
		if ( [[authenticationTypeMatrix selectedCell] tag] == 0 )
			[currentServer connectWithSingleSignOnCredentials];
		else
			[currentServer connectWithPassword:[passwordField stringValue]];
	}
}

//start the dialogue to connect to an xgrid server, if none is connected and one is available
- (IBAction)connectToFirstAvailableServer:(id)sender;
{
	XGSServer *aServer;
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	//if ( ([serverList firstConnectedServer]!=nil) && (aServer=[serverList firstAvailableServer]) )
	//	[self startConnectionProcessWithServer:aServer];
}

- (IBAction)cancelConnect:(id)sender
{
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	[self endConnectionProcess];
}

- (IBAction)removeSelectedServer:(id)sender;
{
	XGSServer *aServer;
	aServer = [self selectedServerInTheTableView];
	if ( [aServer isConnecting] ) {
		NSBeginAlertSheet(@"Not allowed", @"OK", nil,  nil, [self window], nil, NULL, NULL, NULL,
						  @"You cannot delete a controller from the list while it is connecting.");
		return;
	}
	if ( [aServer isConnected] ) {
		NSBeginAlertSheet(@"Not allowed", @"OK", nil,  nil, [self window], nil, NULL, NULL, NULL,
						  @"You cannot delete a controller from the list while it is connected.");
		return;
	}
	
	//this should not even happen, because of the Bindings set up in the nib
	if ( [aServer isAvailable] ) {
		NSBeginAlertSheet(@"Not allowed", @"OK", nil,  nil, [self window], nil, NULL, NULL, NULL,
						  @"You cannot delete from the list a controller using Bonjour to advertise its service.");
		return;
	}
	
	if ( [[aServer valueForKeyPath:@"grids.jobs"] count] > 0 ) {
		NSBeginAlertSheet(@"Error", @"OK", nil,  nil, [self window], nil, NULL, NULL, NULL,
						  @"This controller still have jobs running. You cannot delete it.");
		return;
	}
	//[serverList removeServer:aServer];
}

@end
