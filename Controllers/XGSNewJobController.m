//
//  XGSNewJobController.m
//  GridStuffer
//
//  Created by Charles Parnot on 5/13/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//

/*
 This file is part of GridStuffer.
 GridStuffer is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
 GridStuffer is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with GridStuffer; if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#import "XGSNewJobController.h"
#import "XGSOutputInterface.h"
#import "XGSInputInterface.h"
#import "XGSValidator.h"
#import "XGSTaskSource.h"
#import "XGSPathUtilities.h"


//description of the demos is stored in a plist as an array of dictionaries
static NSArray *demoDictionaries = nil;

@implementation XGSNewJobController

#define BROWSE_INPUT_FILE 1
#define BROWSE_OUTPUT_FOLDER 2

#pragma mark *** birth and death ***

//description of the demos is stored in a plist as an array of dictionaries
- (NSArray *)demoDictionaries
{
	NSBundle *thisBundle;
	NSString *plistFilePath;
	if ( demoDictionaries == nil ) {
		thisBundle = [NSBundle mainBundle];
		plistFilePath = [thisBundle pathForResource:@"gridstuffer_demos" ofType:@"plist"];
		demoDictionaries = [[NSArray alloc] initWithContentsOfFile:plistFilePath];
	}
	return demoDictionaries;
}


- (id)init;
{
	return [self initWithWindowNibName:@"NewJob"];
}

- (void)awakeFromNib
{
	//Populate the 'Load Demo' pop-up button with the demo names
	
	//the first item of the NSPopUpButton for the demos = 'Load demo...'
	[loadDemoPopUpButton removeAllItems];
	[loadDemoPopUpButton addItemWithTitle:@"Load demo..."];
	[[loadDemoPopUpButton lastItem] setTag:-1];
	[[loadDemoPopUpButton lastItem] setToolTip:@"Click here to load one of the pre-built demos on toyour desktop"];

	//the other items are provided by the demoDictionaries array
	NSArray *demos = [self demoDictionaries];
	NSEnumerator *e = [demos objectEnumerator];
	NSDictionary *oneDemo;
	int currentMenuItemTag = 0;
	while ( oneDemo = [e nextObject] ) {
		[loadDemoPopUpButton addItemWithTitle:[oneDemo objectForKey:@"Name"]];
		[[loadDemoPopUpButton lastItem] setTag:currentMenuItemTag];
		[[loadDemoPopUpButton lastItem] setToolTip:[oneDemo objectForKey:@"Description"]];
		currentMenuItemTag++;
	}
	
	//initial values for inputFile and outputFolder are stored in user defaults
	[inputFileTextField setStringValue:[[NSUserDefaults standardUserDefaults] valueForKey:@"LastInputFilePath"]];
	[outputFolderTextField setStringValue:[[NSUserDefaults standardUserDefaults] valueForKey:@"LastOutputFolderPath"]];
	
	//reset the GUI bindings
	[self updateObservedKeys:nil];
}

#pragma mark *** checking paths ***

//the followings methods are used here but also for bindings in the GUI

- (BOOL)inputFileExists
{
	NSString *inputPath;
	NSFileManager *fileManager;
	BOOL isDir;
	inputPath=[[inputFileTextField stringValue] stringByStandardizingPath];
	fileManager=[NSFileManager defaultManager];
	return [fileManager fileExistsAtPath:inputPath isDirectory:&isDir];
}

- (BOOL)inputFileIsFile
{
	NSString *inputPath;
	NSFileManager *fileManager;
	BOOL isDir;
	fileManager=[NSFileManager defaultManager];
	inputPath=[[inputFileTextField stringValue] stringByStandardizingPath];
	[fileManager fileExistsAtPath:inputPath isDirectory:&isDir];
	return !isDir;
}

- (BOOL)inputFileIsValid
{
	return [self inputFileExists] && [self inputFileIsFile];
}

- (BOOL)outputFolderExists
{
	NSString *outputPath;
	NSFileManager *fileManager;
	BOOL isDir;
	outputPath=[[outputFolderTextField stringValue] stringByStandardizingPath];
	fileManager=[NSFileManager defaultManager];
	return [fileManager fileExistsAtPath:outputPath isDirectory:&isDir];
}

- (BOOL)outputFolderIsDir
{
	NSString *outputPath;
	NSFileManager *fileManager;
	BOOL isDir;
	outputPath=[[outputFolderTextField stringValue] stringByStandardizingPath];
	fileManager=[NSFileManager defaultManager];
	[fileManager fileExistsAtPath:outputPath isDirectory:&isDir];
	return isDir;
}

- (BOOL)outputFolderIsValid
{
	return [self outputFolderExists] && [self outputFolderIsDir];
}

- (BOOL)pathsAreValid
{
	return [self inputFileIsValid] && [self outputFolderIsValid];
}

- (BOOL)checkPaths
{
	//Check the input file chosen by the user in the GUI
	if (![self inputFileExists]) {
		NSBeginAlertSheet(@"Error", @"OK", nil,  nil, [self window], nil, NULL, NULL, NULL,
						  @"The path provided for the input file does not exist.");
		return NO;
	}
	if (![self inputFileIsFile]) {
		NSBeginAlertSheet(@"Error", @"OK", nil,  nil, [self window], nil, NULL, NULL, NULL,
						  @"The path provided for the input file is a directory but should be a file.");
		return NO;
	}
	
	//Check the output file chosen by the user in the GUI
	if (![self outputFolderExists]) {
		NSBeginAlertSheet(@"Error", @"OK", nil,  nil, [self window], nil, NULL, NULL, NULL,
						  @"The path provided for the output folder does not exist.");
		return NO;
	}
	if (![self outputFolderIsDir]) {
		NSBeginAlertSheet(@"Error", @"OK", nil,  nil, [self window], nil, NULL, NULL, NULL,
						  @"The path provided for the output folder is a file but should be a directory.");
		return NO;
	}
	
	return YES;
}

//for the bindings to work, I need to notify of changes in certain keys
//because the methods above do not have corresponding setters
- (IBAction)updateObservedKeys:(id)sender
{
	[self willChangeValueForKey:@"inputFileIsValid"];
	[self didChangeValueForKey:@"inputFileIsValid"];
	[self willChangeValueForKey:@"outputFolderIsValid"];
	[self didChangeValueForKey:@"outputFolderIsValid"];
	[self willChangeValueForKey:@"pathsAreValid"];
	[self didChangeValueForKey:@"pathsAreValid"];
}


#pragma mark *** NSWindow delegate methods ***

- (void)windowWillClose:(NSNotification *)notification
{
	if ([self window]==[notification object]) {
		DDLog(NSStringFromClass([self class]),10,@"<%@:%p> closing window and autorelease", [self class], self);
		[self autorelease];
	}
}

#pragma mark *** actions ***

- (IBAction)cancel:(id)sender
{
	[[self window] performClose:self];
}

- (IBAction)browse:(id)sender
{
	
	//tag value is dependent on which 'Browse' button was pressed
	int tag = [sender tag];
	if ( ( tag != BROWSE_INPUT_FILE ) && ( tag != BROWSE_OUTPUT_FOLDER ) )
		return;
	
	//set up the open panel
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setAccessoryView:nil];
	[panel setAllowsMultipleSelection:NO];
	[panel setCanChooseFiles:((tag==BROWSE_INPUT_FILE)?YES:NO)];		
	[panel setCanChooseDirectories:((tag==BROWSE_INPUT_FILE)?NO:YES)];
	[panel setCanCreateDirectories:YES];
	
	//from the result, populate the corresponding text field
	int runResult = [panel runModalForDirectory:nil file:nil types:nil];
	if ( runResult == NSOKButton ) {
		NSString *filePath = [panel filename];
		NSTextField *pathTextField = nil;
		if ( tag == BROWSE_INPUT_FILE )
			pathTextField = inputFileTextField;
		else if ( tag == BROWSE_OUTPUT_FOLDER )
			pathTextField = outputFolderTextField;
		[pathTextField setStringValue:filePath];
	}
	
	//notify KVO
	[self updateObservedKeys:self];
}

//open the input file or output folder in the Finder
- (IBAction)openWithFinder:(id)sender
{
	//tag value is dependent on which 'Open' button was pressed
	int tag = [sender tag];
	if ( ( tag != BROWSE_INPUT_FILE) && ( tag != BROWSE_OUTPUT_FOLDER ) )
		return;	
	NSTextField *pathTextField = nil;
	if ( tag == BROWSE_INPUT_FILE )
		pathTextField = inputFileTextField;
	else if ( tag == BROWSE_OUTPUT_FOLDER )
		pathTextField = outputFolderTextField;
	
	//open the path set up in the GUI in the finder
	[[NSWorkspace sharedWorkspace] openFile:[[pathTextField stringValue] stringByStandardizingPath]];
}


//load a demo example using the info stored in the demoDictionaries
//this will overwrite by default --> TO DO : ask the user before overwriting
- (IBAction)loadDemo:(id)sender
{
	DDLog(NSStringFromClass([self class]),10,@"[%@:%p %s]",[self class],self,_cmd);

	//get the demo dictionary where all the info for the chosen demo is stored
	NSArray *demos = [self demoDictionaries];
	int demoIndex = [[sender selectedItem] tag];
	if ( demoIndex < 0 || demoIndex > [demos count]-1 )
		return;
	NSDictionary *demoInfo = [demos objectAtIndex:demoIndex];

	//reset the position of the 'Load Demo...' popup menu
	[sender selectItemAtIndex:0];
	
	//this is the root path where all the files for the demo will be loaded
	NSFileManager *fileManager=[NSFileManager defaultManager];
	NSBundle *thisBundle = [NSBundle mainBundle];
	NSString *demoPath = [[demoInfo objectForKey:@"Path"] stringByStandardizingPath];
	BOOL success = YES;
	if ( [fileManager fileExistsAtPath:demoPath isDirectory:&success] == NO )
		success = [fileManager createDirectoryAtPath:demoPath attributes:nil];
	if ( success == NO ) {
		//there was a problem...
		NSBeginAlertSheet(@"Error", @"OK", nil,  nil, [self window], nil, NULL, NULL, NULL, @"Could not create the folder needed to load the demo.");
		return;
	}
	
	//files to copy from the bundle
	NSArray *files = [demoInfo objectForKey:@"Files"];
	files = [files arrayByAddingObject:[demoInfo objectForKey:@"Commands"]];
	NSEnumerator *e = [files objectEnumerator];
	success = YES;
	NSString *filePath;
	BOOL isDir;
	while ( filePath = [e nextObject] ) {
		//filePath may be a complex path that includes subdirectories, but to find the file in the bundle, we only need the filename
		NSString *fileName = [filePath lastPathComponent];
		NSString *path1 = [thisBundle pathForResource:[fileName stringByDeletingPathExtension] ofType:[fileName pathExtension]];
		NSString *path2 = [demoPath stringByAppendingPathComponent:filePath];
		success = CreateDirectory([path2 stringByDeletingLastPathComponent]);
		if ( [fileManager fileExistsAtPath:path2 isDirectory:&isDir] )
			success = success && [fileManager removeFileAtPath:path2 handler:nil];
		success = success && [fileManager copyPath:path1 toPath:path2 handler:nil];
	}
	
	//set the input file value in the GUI
	[inputFileTextField setStringValue:[demoPath stringByAppendingPathComponent:[demoInfo objectForKey:@"Commands"]]];
	
	//set the output folder on disk and in the GUI
	NSString *outputPath = [demoPath stringByAppendingPathComponent:@"output"];
	if ( [fileManager fileExistsAtPath:outputPath isDirectory:&isDir] )
		success = success && [fileManager removeFileAtPath:outputPath handler:nil];
	success = success && [fileManager createDirectoryAtPath:outputPath attributes:nil];
	[outputFolderTextField setStringValue:outputPath];
	
	//notify KVO
	[self updateObservedKeys:self];
	
	//error message?
	if ( success == NO )
		NSBeginAlertSheet(@"Error", @"OK", nil,  nil, [self window], nil, NULL, NULL, NULL, @"Could not create some of the files needed for the demo.");
}

//convenience method called to add a job to the managed object context
- (void)addMetaJobToManagedObjectContext
{
	DDLog(NSStringFromClass([self class]),10,@"[%@:%p %s]",[self class],self,_cmd);

	//get the context
	NSManagedObjectContext *context = [GEZManager managedObjectContext];

	//set up the input and output interface first...
	XGSInputInterface *input = [NSEntityDescription insertNewObjectForEntityForName:@"InputInterface" inManagedObjectContext:context];
	XGSOutputInterface *output = [NSEntityDescription insertNewObjectForEntityForName:@"OutputInterface" inManagedObjectContext:context];
	[input setValue:[inputFileTextField stringValue] forKey:@"filePath"];
	[output setValue:[outputFolderTextField stringValue] forKey:@"folderPath"];
	
	//... then the task source ...
	XGSValidator *filter = [NSEntityDescription insertNewObjectForEntityForName:@"Validator" inManagedObjectContext:context];
	XGSTaskSource *taskSource = [NSEntityDescription insertNewObjectForEntityForName:@"DataSource" inManagedObjectContext:context];
	[taskSource setValue:input       forKey:@"inputInterface"];
	[taskSource setValue:output      forKey:@"outputInterface"];
	[taskSource setValue:filter      forKey:@"validator"];
		
	//...then the metaJob
	GEZMetaJob *metaJob = [GEZMetaJob metaJobWithName:[jobNameTextField stringValue]];
	[metaJob setDataSource:taskSource];
	
	//this forces update of core data bindings in the GUI
	[context processPendingChanges];
	
	//store the values to the NSUSerDefaults
	[[NSUserDefaults standardUserDefaults] setValue:[inputFileTextField stringValue] forKey:@"LastInputFilePath"];
	[[NSUserDefaults standardUserDefaults] setValue:[outputFolderTextField stringValue] forKey:@"LastOutputFolderPath"];
	
	//self suicide (that's a pleonasm)
	[[self window] performClose:self];
}

- (IBAction)addMetaJob:(id)sender
{
	DDLog(NSStringFromClass([self class]),10,@"[%@:%p %s]",[self class],self,_cmd);

	//check the paths
	if (![self checkPaths])
		return;

	[self addMetaJobToManagedObjectContext];
	[self close];
}

@end
