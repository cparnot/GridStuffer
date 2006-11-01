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

@implementation GridStufferAppDelegate

#pragma mark *** Initializations ***

+ (void)initialize
{
	NSBundle *myBundle;
	NSString *thePath;
	NSUserDefaults *defaults;
	NSDictionary *factory;
	
	//get the app factory defaults from the file GridStufferFactoryDefaults.plist in the resources
	myBundle=[NSBundle bundleForClass:self];
	thePath=[myBundle pathForResource:@"GridStufferFactoryDefaults" ofType:@"plist"];
	factory=[[NSDictionary alloc] initWithContentsOfFile:thePath];
	
	//set the factory defaults for the user defaults
	defaults = [NSUserDefaults standardUserDefaults];
	[defaults registerDefaults:factory];
}

- (id)init
{
	self = [super init];
	if (self!=nil) {
		serverListController = nil;
		jobListController = nil;
	}
	return self;
}

- (void)dealloc
{
	[serverListController release];
	[jobListController release];
	[super dealloc];
}

- (void)awakeFromNib
{
	metaJobToolbarController = [[XGSToolbarController alloc] initWithToolbarDescriptionFile:@"MetaJobToolbar"];
	[metaJobListWindow setToolbar:[metaJobToolbarController toolbar]];
	[[[metaJobTableView tableColumnWithIdentifier:@"progress"] dataCell] setControlSize:NSMiniControlSize];
	[taskInspectorTableView reloadData];
}


#pragma mark *** grids controller and window ***

- (IBAction)showServerListWindow:(id)sender
{
	[GEZManager showServerWindow];
}

- (IBAction)showJobListWindow:(id)sender
{
	if ( jobListController == nil )
		jobListController = [[XGSJobListController alloc] initWithManagedObjectContext:[self managedObjectContext]];
	[jobListController showWindow:self];
}

- (IBAction)showMetaJobInspectorPanel:(id)sender;
{
	[metaJobInspectorPanel makeKeyAndOrderFront:self];
}

#pragma mark *** Job Actions ***

- (NSArray *)selectedMetaJobsInTheTableView
{
	return [jobArrayController selectedObjects];
}

- (GEZMetaJob *)uniquelySelectedMetaJobInTheTableView
{
	NSArray *jobs;
	jobs = [jobArrayController selectedObjects];
	if ( [jobs count] == 1 )
		return [jobs objectAtIndex:0];
	else
		return nil;
}

- (IBAction)insertNewMetaJob:(id)sender
{
	DLog(NSStringFromClass([self class]),10,@"[<%@:%p> %s]",[self class],self,_cmd);

	//it is a rare case where the release is handled by the object itself
	//so do not worry about the alloc below
	XGSNewJobController *newJobWindowController;
	newJobWindowController = [[XGSNewJobController alloc] init];
	[newJobWindowController showWindow:self];
}

- (IBAction)startMetaJob:(id)sender
{
	GEZMetaJob *selectedJob;
	
	DLog(NSStringFromClass([self class]),10,@"[<%@:%p> %s]",[self class],self,_cmd);
	
	selectedJob = [self uniquelySelectedMetaJobInTheTableView];
	[selectedJob setDelegate:self];
	[[[selectedJob dataSource] inputInterface] loadFile];
	[selectedJob start];
	[taskInspectorTableView reloadData];
}

- (IBAction)suspendMetaJob:(id)sender
{
	GEZMetaJob *selectedJob;
	
	DLog(NSStringFromClass([self class]),10,@"[<%@:%p> %s]",[self class],self,_cmd);
	
	selectedJob = [self uniquelySelectedMetaJobInTheTableView];
	[[[selectedJob dataSource] inputInterface] loadFile];
	[selectedJob suspend];
	[taskInspectorTableView reloadData];
}

- (IBAction)deleteSelectedMetaJobs:(id)sender
{
	NSEnumerator *e;
	NSArray *metaJobs;
	GEZJob *aMetaJob;
	
	metaJobs = [self selectedMetaJobsInTheTableView];
	e = [metaJobs objectEnumerator];
	while ( aMetaJob = [e nextObject] )
		[aMetaJob deleteFromStore];
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

#pragma mark *** initializations ***


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[GEZManager showServerWindow];
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
	DLog(NSStringFromClass([self class]),10,@"[<%@:%p> %s]",[self class],self,_cmd);
	/*
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
	 */
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
	DLog(NSStringFromClass([self class]),10,@"[<%@:%p> %s]",[self class],self,_cmd);
	if ( selectedTableView == metaJobTableView ) {
		DLog(NSStringFromClass([self class]),10,@"[<%@:%p> %s] for MetaJobs table",[self class],self,_cmd);
		[taskInspectorTableView reloadData];		
	}
	else if ( selectedTableView == taskInspectorTableView ) {
		DLog(NSStringFromClass([self class]),10,@"[<%@:%p> %s] for Tasks table",[self class],self,_cmd);
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
	[taskInspectorTableView reloadData];
}

- (void)metaJob:(GEZMetaJob *)metaJob didProcessTaskAtIndex:(int)index
{
	[taskInspectorTableView reloadData];
}

@end
