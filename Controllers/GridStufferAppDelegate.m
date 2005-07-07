//  GridStufferAppDelegate.m
//  GridStuffer
//
//  Created by Charles Parnot on 5/10/05.
//  Copyright Charles Parnot 2005 . All rights reserved.

#import "GridStufferAppDelegate.h"
#import "XGSNewJobController.h"
#import "XGSServerList.h"
#import "XGSServerListController.h"
#import "XGSJobListController.h"
#import "XGSMetaJob.h"
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
}


#pragma mark *** grids controller and window ***

- (IBAction)showServerListWindow:(id)sender
{
	[serverListController showWindow:self];
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

- (XGSMetaJob *)uniquelySelectedMetaJobInTheTableView
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

	XGSNewJobController *newJobWindowController;
	newJobWindowController = [[XGSNewJobController alloc] init];
	[newJobWindowController showWindow:self];
}

- (IBAction)startMetaJob:(id)sender
{
	XGSMetaJob *selectedJob;
	
	DLog(NSStringFromClass([self class]),10,@"[<%@:%p> %s]",[self class],self,_cmd);
	
	selectedJob = [self uniquelySelectedMetaJobInTheTableView];
	[[[selectedJob dataSource] inputInterface] loadFile];
	[selectedJob start];
}

- (IBAction)suspendMetaJob:(id)sender
{
	XGSMetaJob *selectedJob;
	
	DLog(NSStringFromClass([self class]),10,@"[<%@:%p> %s]",[self class],self,_cmd);
	
	selectedJob = [self uniquelySelectedMetaJobInTheTableView];
	[[[selectedJob dataSource] inputInterface] loadFile];
	[selectedJob suspend];
}

- (IBAction)deleteSelectedMetaJobs:(id)sender
{
	NSEnumerator *e;
	NSArray *metaJobs;
	XGSJob *aMetaJob;
	
	metaJobs = [self selectedMetaJobsInTheTableView];
	e = [metaJobs objectEnumerator];
	while ( aMetaJob = [e nextObject] )
		[aMetaJob deleteFromStore];
}

/*
#define OPEN_INPUT_FILE 1
#define OPEN_OUTPUT_FOLDER 2
//open the input file or output folder in the Finder
- (IBAction)openInputOrOutput:(id)sender
{
	NSString *path;
	int tag;
	
	//tag value is dependent on which 'Open' button was pressed
	tag=[sender tag];
	if (tag==OPEN_INPUT_FILE)
		path=[someObject valueForKeyPath:];
	else if (tag==OPEN_OUTPUT_FOLDER)
		pathTextField=outputFolderTextField;
	
	//open the path set up in the GUI in the finder
	path=[pathTextField stringValue];
	[[NSWorkspace sharedWorkspace] openFile:[path stringByStandardizingPath]];
}
*/

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
	//ask the user for a connection
	serverListController = [[XGSServerListController alloc] init];
	[serverListController showWindow:self];
	[serverListController connectToFirstAvailableServer:self];
}

#pragma mark *** CoreData stuff ***

- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel) return managedObjectModel;
	
	NSMutableSet *allBundles = [[NSMutableSet alloc] init];
	[allBundles addObject: [NSBundle mainBundle]];
	[allBundles addObjectsFromArray: [NSBundle allFrameworks]];
    
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles: [allBundles allObjects]] retain];
    [allBundles release];
    
    return managedObjectModel;
}

/* Change this path/code to point to your App's data store. */
- (NSString *)applicationSupportFolder
{
    NSString *applicationSupportFolder = nil;
	NSString *folderName,*version;

	//there might be several stores at the same time:
	//	- in use by different applications or by the same application
	//	- in addition, each version will use a different location because backward compatibility is not yet implemented
	//	- finally, the store is different in debug mode
	folderName = @"GridStuffer";
	version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	folderName = [folderName stringByAppendingFormat:@"_version_%@",version];
#ifdef DEBUG
	folderName = [folderName stringByAppendingString:@"_DEBUG";
#endif
	
    FSRef foundRef;
    OSErr err = FSFindFolder(kUserDomain, kApplicationSupportFolderType, kDontCreateFolder, &foundRef);
    if (err != noErr) {
        NSRunAlertPanel(@"Alert", @"Can't find application support folder", @"Quit", nil, nil);
        [[NSApplication sharedApplication] terminate:self];
    } else {
        unsigned char path[1024];
        FSRefMakePath(&foundRef, path, sizeof(path));
        applicationSupportFolder = [NSString stringWithUTF8String:(char *)path];
        applicationSupportFolder = [applicationSupportFolder stringByAppendingPathComponent:folderName];
    }
    return applicationSupportFolder;
}

- (NSManagedObjectContext *) managedObjectContext
{
    NSError *error;
    NSString *applicationSupportFolder = nil;
    NSURL *url;
    NSFileManager *fileManager;
    NSPersistentStoreCoordinator *coordinator;
    
    if (managedObjectContext) {
        return managedObjectContext;
    }
    
    fileManager = [NSFileManager defaultManager];
    applicationSupportFolder = [self applicationSupportFolder];
    if ( ![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL] ) {
        [fileManager createDirectoryAtPath:applicationSupportFolder attributes:nil];
    }
    
    url = [NSURL fileURLWithPath: [applicationSupportFolder stringByAppendingPathComponent: @"GridStuffer.xml"]];
    coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if ([coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]){
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    } else {
        [[NSApplication sharedApplication] presentError:error];
    }    
    [coordinator release];
    
    return managedObjectContext;
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}

- (IBAction) saveAction:(id)sender {
	DLog(NSStringFromClass([self class]),10,@"[<%@:%p> %s]",[self class],self,_cmd);
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    NSError *error;
    NSManagedObjectContext *context;
    int reply = NSTerminateNow;
    
	DLog(NSStringFromClass([self class]),10,@"<%@:%p> %s",[self class],self,_cmd);
	
	//[[NSUserDefaults standardUserDefaults] setInteger:15 forKey:@"DebugLogVerboseLevel"];
	
    context = [self managedObjectContext];
    if (context != nil) {
        if ([context commitEditing]) {
            if (![context save:&error]) {
				
				// This default error handling implementation should be changed to make sure the error presented includes application specific error recovery. For now, simply display 2 panels.
                BOOL errorResult = [[NSApplication sharedApplication] presentError:error];
				
				if (errorResult == YES) { // Then the error was handled
					reply = NSTerminateCancel;
				} else {
					
					// Error handling wasn't implemented. Fall back to displaying a "quit anyway" panel.
					int alertReturn = NSRunAlertPanel(nil, @"Could not save changes while quitting. Quit anyway?" , @"Quit anyway", @"Cancel", nil);
					if (alertReturn == NSAlertAlternateReturn) {
						reply = NSTerminateCancel;	
					}
				}
            }
        } else {
            reply = NSTerminateCancel;
        }
    }
    return reply;
}

@end
