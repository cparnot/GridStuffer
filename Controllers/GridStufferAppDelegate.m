//  GridStufferAppDelegate.m
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

#import "GridStufferAppDelegate.h"
#import "XGSNewJobController.h"
#import "XGSJobListController.h"
#import "XGSTaskSource.h"
#import "XGSOutputInterface.h"
#import "XGSInputInterface.h"
#import "XGSToolbarController.h"

@class XGSStringToImageTransformer;

@implementation GridStufferAppDelegate

#pragma mark *** Initializations ***

+ (void)initialize
{
	DDLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);

	//get the app factory defaults from the file GridStufferFactoryDefaults.plist in the resources
	NSDictionary *factory=[[[NSDictionary alloc] initWithContentsOfFile:[[NSBundle bundleForClass:self] pathForResource:@"GridStufferFactoryDefaults" ofType:@"plist"]] autorelease];
	[[NSUserDefaults standardUserDefaults] registerDefaults:factory];
	
	//register the string to image transformer, used to display little icons in tables to indicate status of metajob
	[NSValueTransformer setValueTransformer:[[[XGSStringToImageTransformer alloc] init] autorelease] forName:@"XGSStringToImageTransformer"];

}

- (id)init
{
	self = [super init];
	if (self!=nil) {
		jobListController = nil;
	}
	return self;
}

- (void)dealloc
{
	[jobListController release];
	[super dealloc];
}

- (void)awakeFromNib
{
	metaJobToolbarController = [[XGSToolbarController alloc] initWithToolbarDescriptionFile:@"MetaJobToolbar"];
	[metaJobListWindow setToolbar:[metaJobToolbarController toolbar]];
	[[[metaJobTableView tableColumnWithIdentifier:@"progress"] dataCell] setControlSize:NSMiniControlSize];
	[taskInspectorTableView reloadData];
	
	//set all GEZMetaJob delegate to be 'self'
	//to retrieve ALL records for a given entity, one can use a fetch request with no predicate
	NSManagedObjectContext *context = [GEZManager managedObjectContext];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[NSEntityDescription entityForName:GEZMetaJobEntityName inManagedObjectContext:context]];
	NSError *error;
	NSArray *allMetaJobs = [context executeFetchRequest:request error:&error];	
	NSEnumerator *e = [allMetaJobs objectEnumerator];
	GEZMetaJob *metaJob;
	while ( metaJob = [e nextObject] )
		[metaJob setDelegate:self];
}


#pragma mark *** window menu actions ***

- (IBAction)showXgridPanel:(id)sender
{
	DDLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	//ask the user for confirmation the first time
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EnableXgridPanelAccess"] == NO ) {
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:@"Open Xgrid Panel"];
		[alert addButtonWithTitle:@"Cancel"];
		[alert setMessageText:@"Open the Xgrid Panel?"];
		[alert setInformativeText:@"The Xgrid Panel offers advanced features to manage your Xgrid controllers and jobs. It is more complicated to use than the Controllers window, and is even more experimental than the rest of GridStuffer. I will ask this only once: are you sure you want to open the Xgrid Panel?"];
		[alert setAlertStyle:NSWarningAlertStyle];
		if ([alert runModal] == NSAlertFirstButtonReturn)
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"EnableXgridPanelAccess"];
		else
			return;
	}	

	[GEZManager showXgridPanel];
}

- (IBAction)showServerListWindow:(id)sender
{
	DDLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	[GEZManager showServerWindow];
}

- (IBAction)showJobListWindow:(id)sender
{
	DDLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	if ( jobListController == nil )
		jobListController = [[XGSJobListController alloc] initWithManagedObjectContext:[self managedObjectContext]];
	[jobListController showWindow:self];
}

- (IBAction)showMetaJobInspectorPanel:(id)sender;
{
	DDLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	[metaJobInspectorPanel makeKeyAndOrderFront:self];
}

#pragma mark *** Job Actions ***

- (NSArray *)selectedMetaJobsInTheTableView
{
	return [metaJobArrayController selectedObjects];
}

- (GEZMetaJob *)uniquelySelectedMetaJobInTheTableView
{
	NSArray *metaJobs;
	metaJobs = [metaJobArrayController selectedObjects];
	if ( [metaJobs count] == 1 )
		return [metaJobs objectAtIndex:0];
	else
		return nil;
}

- (IBAction)insertNewMetaJob:(id)sender
{
	DDLog(NSStringFromClass([self class]),10,@"[<%@:%p> %s]",[self class],self,_cmd);

	//it is a rare case where the release is handled by the object itself
	//so do not worry about the alloc below
	XGSNewJobController *newJobWindowController;
	newJobWindowController = [[XGSNewJobController alloc] init];
	[newJobWindowController showWindow:self];
}

- (IBAction)startMetaJob:(id)sender
{
	GEZMetaJob *selectedMetaJob;
	
	DDLog(NSStringFromClass([self class]),10,@"[<%@:%p> %s]",[self class],self,_cmd);
	
	selectedMetaJob = [self uniquelySelectedMetaJobInTheTableView];
	[selectedMetaJob setDelegate:self];
	[[[selectedMetaJob dataSource] inputInterface] loadFile];
	[selectedMetaJob start];
	[taskInspectorTableView reloadData];
}

- (IBAction)suspendMetaJob:(id)sender
{
	DDLog(NSStringFromClass([self class]),10,@"[<%@:%p> %s]",[self class],self,_cmd);
	
	GEZMetaJob *selectedMetaJob = [self uniquelySelectedMetaJobInTheTableView];
	[[[selectedMetaJob dataSource] inputInterface] loadFile];
	[selectedMetaJob suspend];
	[taskInspectorTableView reloadData];
}

- (IBAction)deleteSelectedMetaJobs:(id)sender
{
	DDLog(NSStringFromClass([self class]),10,@"[<%@:%p> %s]",[self class],self,_cmd);
	
	GEZMetaJob *aMetaJob;	
	NSEnumerator *e = [[self selectedMetaJobsInTheTableView] objectEnumerator];
	while ( aMetaJob = [e nextObject] ) {
		XGSTaskSource *dataSource = [aMetaJob dataSource];
		[aMetaJob setDataSource:nil];
		[aMetaJob setDelegate:nil];
		[aMetaJob deleteFromStore];
		[[GEZManager managedObjectContext] deleteObject:dataSource];
		//the dataSource was retained by the XGSNewJobController instance, and now needs to be released
		[dataSource autorelease];
	}
	[taskInspectorTableView reloadData];
}


#define OPEN_INPUT_FILE 1
#define OPEN_OUTPUT_FOLDER 2
//open the input file or output folder in the Finder
- (IBAction)openWithFinder:(id)sender
{
	NSString *path;
	int tag;
	
	//tag value is dependent on which 'Open' button was pressed
	tag=[sender tag];
	if ( (tag!=OPEN_INPUT_FILE) && (tag!=OPEN_OUTPUT_FOLDER) )
		return;	
	if (tag==OPEN_INPUT_FILE)
		path = [[[[self uniquelySelectedMetaJobInTheTableView] dataSource] inputInterface] filePath];
	else if (tag==OPEN_OUTPUT_FOLDER)
		path = [[[[self uniquelySelectedMetaJobInTheTableView] dataSource] outputInterface] folderPath];
	
	//open the path in the finder
	[[NSWorkspace sharedWorkspace] openFile:[path stringByStandardizingPath]];
}


#pragma mark *** KVC and KVO ***

//(AppKit bug?) the level indicator can be 'edited' by clicking on it --> this prevents it
// (done by using binding for 'enabled' ; does not work with 'editable' !!??!)
- (BOOL)shouldEnableLevelIndicator
{
	return NO;
}

#pragma mark *** NSApp delegate methods ***


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[GEZManager setMaxFileDownloads:[[NSUserDefaults standardUserDefaults] integerForKey:@"MaxFileDownloads"]];
	[GEZManager showServerWindow];
	//[GEZManager showXgridPanel];
	
	//set a timer that is going to be always there during the life of the application, and will save the store every xx seconds; the timer will call saveAction: with an NSTimer as argument, which is not exactly right; it is OK, we don't use the argument anyway
	NSTimeInterval autosaveInterval = [[NSUserDefaults standardUserDefaults] integerForKey:@"AutosaveIntervalInSeconds"];
	NSTimer *eternalTimer;
	eternalTimer = [NSTimer scheduledTimerWithTimeInterval:autosaveInterval target:self selector:@selector(saveAction:) userInfo:nil repeats:YES];
	
	//disable Debug menu
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"EnableDebugMenu"] == NO ) {
		NSMenu *mainMenu = [NSApp mainMenu];
		NSMenuItem *debugSubmenu = [mainMenu itemWithTitle:@"Debug"];
		[mainMenu removeItem:debugSubmenu];
	}
	
	//
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	[self saveAction:self];
    return YES;
}


#pragma mark *** CoreData ***


- (NSManagedObjectContext *) managedObjectContext
{
	return [GEZManager managedObjectContext];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}

- (IBAction) saveAction:(id)sender
{
	DDLog(NSStringFromClass([self class]),10,@"[<%@:%p> %s]",[self class],self,_cmd);
    NSError *error = nil;
    if ( [[self managedObjectContext] save:&error] == NO ) {
		NSLog(@"Error while attempting to save:\n%@",error);
		// [[NSApplication sharedApplication] presentError:error];
	}
	//save again if changes made - temporary fix for a limitation in GEZProxy - this needs to be addressed in the framework!!
	if ( [[self managedObjectContext] hasChanges] ) {
		DDLog(NSStringFromClass([self class]),10,@"[<%@:%p> %s] SAVING AGAIN!!",[self class],self,_cmd);
		if  ( [[self managedObjectContext] save:&error] == NO ) {
			NSLog(@"Error while attempting to save:\n%@",error);
			// [[NSApplication sharedApplication] presentError:error];
		}
	}
}



#pragma mark *** NSTableView data source and delegate ***


//data source for the command progress table view
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[[self uniquelySelectedMetaJobInTheTableView] countTotalTasks] intValue];
}

//data source for the command progress table view
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	NSString *idf;
	idf=[aTableColumn identifier];
	
	if ([idf isEqualToString:@"index"])
		return [NSNumber numberWithInt:rowIndex];
	if ([idf isEqualToString:@"status"])
		return [NSImage imageNamed:[[self uniquelySelectedMetaJobInTheTableView] statusStringForTaskAtIndex:rowIndex]];
	
	int integerValue = 0;
	GEZMetaJob *selectedJob = [self uniquelySelectedMetaJobInTheTableView];
	if ([idf isEqualToString:@"successes"])
		integerValue = [selectedJob countSuccessesForTaskAtIndex:rowIndex];
	else if ([idf isEqualToString:@"failures"])
		integerValue = [selectedJob countFailuresForTaskAtIndex:rowIndex];
	else if ([idf isEqualToString:@"submissions"])
		integerValue = [selectedJob countSubmissionsForTaskAtIndex:rowIndex];
	if ( integerValue )
		return [NSNumber numberWithInt:integerValue];
	else
		return @"";
}

//delegate for the MetaJobs list --> triggers update of command list
//delegete for the Command list --> shows the command from the file
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSTableView *selectedTableView = [aNotification object];
	DDLog(NSStringFromClass([self class]),10,@"[<%@:%p> %s]",[self class],self,_cmd);
	if ( selectedTableView == metaJobTableView ) {
		DDLog(NSStringFromClass([self class]),10,@"[<%@:%p> %s] for MetaJobs table",[self class],self,_cmd);
		[taskInspectorTableView reloadData];		
	}
	else if ( selectedTableView == taskInspectorTableView ) {
		DDLog(NSStringFromClass([self class]),10,@"[<%@:%p> %s] for Tasks table",[self class],self,_cmd);
		GEZMetaJob *selectedJob = [self uniquelySelectedMetaJobInTheTableView];
		int index = [taskInspectorTableView selectedRow];
		NSString *taskString = @"No Selection";;
		if ( index >= 0 )
			taskString = [[selectedJob valueForKeyPath:@"dataSource.inputInterface"] lineAtIndex:index];
		[taskDescriptionTextField setStringValue:taskString];
	}
}


#pragma mark *** MetaJob delegate methods --> used for the GUI ***

//- (void)metaJobDidStart:(GEZMetaJob *)metaJob;
//- (void)metaJobDidSuspend:(GEZMetaJob *)metaJob;

-(void)metaJob:(GEZMetaJob *)metaJob didSubmitTaskAtIndex:(int)index
{
	DDLog(NSStringFromClass([self class]),10,@"[<%@:%p> %s]",[self class],self,_cmd);
	[taskInspectorTableView reloadData];
}

- (void)metaJob:(GEZMetaJob *)metaJob didProcessTaskAtIndex:(int)index
{
	DDLog(NSStringFromClass([self class]),10,@"[<%@:%p> %s]",[self class],self,_cmd);
	[taskInspectorTableView reloadData];
}

@end
