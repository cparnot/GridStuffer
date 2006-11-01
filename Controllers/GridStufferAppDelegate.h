//  GridStufferAppDelegate.h
//  GridStuffer
//
//  Created by Charles Parnot on 5/10/05.
//  Copyright Charles Parnot 2005 . All rights reserved.

/*
 This file is part of GridStuffer.
 GridStuffer is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
 GridStuffer is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with GridStuffer; if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

@class GEZServerListController;
@class XGSJobListController;
@class XGSToolbarController;

@interface GridStufferAppDelegate : NSObject 
{
    IBOutlet NSWindow *metaJobListWindow;
	IBOutlet NSPanel *metaJobInspectorPanel;
	XGSToolbarController *metaJobToolbarController;
    
	GEZServerListController *serverListController;
	XGSJobListController *jobListController;
	IBOutlet NSArrayController *jobArrayController;
	IBOutlet NSTableView *metaJobTableView;
	
	//Progress tab
	IBOutlet NSTableView *taskInspectorTableView;
	IBOutlet NSTextField *taskDescriptionTextField;
}

// Actions
- (IBAction)insertNewMetaJob:(id)sender;
- (IBAction)showMetaJobInspectorPanel:(id)sender;
- (IBAction)startMetaJob:(id)sender;
- (IBAction)suspendMetaJob:(id)sender;
- (IBAction)deleteSelectedMetaJobs:(id)sender;
- (IBAction)showServerListWindow:(id)sender;
- (IBAction)showJobListWindow:(id)sender;
- (IBAction)openWithFinder:(id)sender;

// CoreData
- (NSManagedObjectContext *)managedObjectContext;
- (IBAction)saveAction:sender;

@end
