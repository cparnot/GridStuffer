//  GridStufferAppDelegate.h
//  GridStuffer
//
//  Created by Charles Parnot on 5/10/05.
//  Copyright Charles Parnot 2005 . All rights reserved.



@class XGSServerListController;
@class XGSJobListController;
@class XGSToolbarController;

@interface GridStufferAppDelegate : NSObject 
{
    IBOutlet NSWindow *metaJobListWindow;
	IBOutlet NSPanel *metaJobInspectorPanel;
	XGSToolbarController *metaJobToolbarController;
    
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
	
	XGSServerListController *serverListController;
	XGSJobListController *jobListController;
	IBOutlet NSArrayController *jobArrayController;
	IBOutlet NSTableView *metaJobTableView;
}

// Actions
- (IBAction)insertNewMetaJob:(id)sender;
- (IBAction)showMetaJobInspectorPanel:(id)sender;
- (IBAction)startMetaJob:(id)sender;
- (IBAction)suspendMetaJob:(id)sender;
- (IBAction)deleteSelectedMetaJobs:(id)sender;
- (IBAction)showServerListWindow:(id)sender;
- (IBAction)showJobListWindow:(id)sender;

// CoreData stuff
- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;
- (IBAction)saveAction:sender;

@end
