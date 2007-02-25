//
//  XGSTaskSource.m
//  GridStuffer
//
//  Created by Charles Parnot on 5/12/05.
//  Copyright 2005, 2006, 2007 Charles Parnot. All rights reserved.
//

/*
 This file is part of GridStuffer.
 GridStuffer is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
 GridStuffer is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with GridStuffer; if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#import "XGSTaskSource.h"
#import "XGSInputInterface.h"
#import "XGSOutputInterface.h"
#import "XGSParser.h"
#import "XGSValidator.h"

//keys used internally for the command dictionary
static NSString *CommandKey=@"Command";
static NSString *ArgumentsKey=@"Arguments";
static NSString *BasePathsKey=@"Base paths for shortcuts";
static NSString *PathsKey=@"Paths to upload";
static NSString *FilesKey=@"Files to upload";
static NSString *WorkingDirectoryKey=@"Working directory to upload";
static NSString *StdinPathKey=@"Stdin path";
//static NSString *StdinStringKey=@"Stdin string";
static NSString *StdoutPathKey=@"Stdout path";
static NSString *StderrPathKey=@"Stderr path";
static NSString *OutputPathKey=@"Output path";


@implementation XGSTaskSource

#pragma mark *** Initializations ***

- (NSString *)shortDescription
{
	return [NSString stringWithFormat:@"TaskSource"];
}


- (id)initWithEntity:(NSEntityDescription*)entity insertIntoManagedObjectContext:(NSManagedObjectContext*)context
{
	self=[super initWithEntity:entity insertIntoManagedObjectContext:context];
	if (self!=nil) {
		//just to be sure
		prototypeCommandDictionary=nil;
		prototypeShortcutDictionary=nil;
	}
	return self;
}

- (void)dealloc
{
	[prototypeCommandDictionary release];
	[prototypeShortcutDictionary release];
	[super dealloc];
}

#pragma mark *** accessors ***

- (XGSInputInterface *)inputInterface;
{
	[self willAccessValueForKey:@"inputInterface"];
	XGSInputInterface *result = [self primitiveValueForKey:@"inputInterface"];
	[self didAccessValueForKey:@"inputInterface"];
	return result;
}

- (XGSOutputInterface *)outputInterface;
{
	XGSOutputInterface *result;
	DDLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	[self willAccessValueForKey:@"outputInterface"];
	result = [self primitiveValueForKey:@"outputInterface"];
	[self didAccessValueForKey:@"outputInterface"];
	return result;
}

- (XGSValidator *)validator
{
	[self willAccessValueForKey:@"validator"];
	XGSValidator * value = [self primitiveValueForKey:@"validator"];
	[self didAccessValueForKey:@"validator"];
	return value;
}

- (void)setValidator:(XGSValidator *)aValue
{
	[self willChangeValueForKey:@"validator"];
	[self setPrimitiveValue:aValue forKey:@"validator"];
	[self didChangeValueForKey:@"validator"];
}


#pragma mark *** command parsing ***

//this is the working directory on the client,
//upon which any relative path is based on
- (NSString *)workingDirectoryPath
{
	NSString *result;
	DDLog (NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	result = [self valueForKeyPath:@"inputInterface.filePath"];
	result = [result stringByStandardizingPath];
	result = [result stringByDeletingLastPathComponent];
	return result;
}

//takes a string, supposedly a relative or absolute path, and make it absolute, prepending the working directory if necessary
- (NSString *)absolutePathForString:(NSString *)relativePath
{
	NSString *finalPath;
	DDLog (NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	
	//a path relative to the home folder is considered relative and will become an absolute path
	finalPath = [relativePath stringByExpandingTildeInPath];
	if ( [finalPath isAbsolutePath] )
		return [finalPath stringByStandardizingPath];
	
	//we have a relative path, so we need to prefix it with the working directory path
	finalPath = [self workingDirectoryPath];
	finalPath = [finalPath stringByAppendingPathComponent:relativePath];
	finalPath = [finalPath stringByStandardizingPath];

	return finalPath;
}

//takes a string and try to get an absolute path for a file that really exists on the file system, testing in this order:
//	- try to make an absolute path --> the file exists ? --> if yes, done!
//	- listed in the shortcuts --> done!
//	- otherwise, returns nil
- (NSString *)existingAbsolutePathForString:(NSString *)relativePath usingShortcutDictionary:(NSDictionary *)shortcutDictionary
{
	NSString *finalPath;
	NSFileManager *fileManager=[NSFileManager defaultManager];
	
	DDLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	//try to resolve the path in the simple way
	finalPath=[self absolutePathForString:relativePath];
	if ([fileManager fileExistsAtPath:finalPath])
		return finalPath;

	//then maybe it is in the shortcut dictionary
	return [shortcutDictionary objectForKey:relativePath];
}


//create a dictionary of shortcuts where each possible 'shortcut' (key) has an absolute path (value)
/*
 for instance, if a basepath is /Users/username/Documents/ and contains 1 folder with 2 file, plus another empty folder, you may get the following shortcuts :
	Documents/folder1			= /Users/username/Documents/folder1
	folder1						= /Users/username/Documents/folder1
	Documents/folder1/file1		= /Users/username/Documents/folder1/file1
	folder1/file1				= /Users/username/Documents/folder1/file1
	file1						= /Users/username/Documents/folder1/file1
	Documents/folder1/file2		= /Users/username/Documents/folder1/file2
	folder1/file2				= /Users/username/Documents/folder1/file2
	file2						= /Users/username/Documents/folder1/file2
	Documents/folder2			= /Users/username/Documents/folder2
	folder2						= /Users/username/Documents/folder2
 */
- (NSDictionary *)shortcutDictionaryForBasePaths:(NSArray *)basepaths
{
	NSFileManager *fileManager;
	NSEnumerator *e;
	NSDirectoryEnumerator *edir;
	NSString *base,*lastBase,*relPath,*absPath,*shortcut;
	NSMutableDictionary *shortcutDictionary;
	NSArray *components;
	int i,n;

	DDLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);

	shortcutDictionary = [NSMutableDictionary dictionary];
	fileManager=[NSFileManager defaultManager];
	e=[basepaths objectEnumerator];
	while (base=[e nextObject]) {
		//the last path component of the base can be used in the shortcuts, so we will need it
		lastBase=[base lastPathComponent];
		//now, look at all the subpaths recursively
		edir=[fileManager enumeratorAtPath:base];
		while (relPath=[edir nextObject]) {
			//the absolute path will be the value for all the shortcuts
			absPath=[base stringByAppendingPathComponent:relPath];
			//add the basepath last path component to the subpath
			relPath=[lastBase stringByAppendingPathComponent:relPath];
			//to generate all the shortcuts, we need to extract the different components and then recombine them using shorter and shorter paths, all ending with the last component of relPath. We don't need to generate all the combinations that do not include the last component, because these will be included with the other [edir nextObject]
			components=[relPath pathComponents];
			n=[components count];
			for (i=0;i<n;i++) {
				shortcut=[[components subarrayWithRange:NSMakeRange(i,n-i)] componentsJoinedByString:@"/"];
				[shortcutDictionary setObject:absPath forKey:shortcut];
			}
		}
	}
	return [NSDictionary dictionaryWithDictionary:shortcutDictionary];
}


//creates the command dictionary based on the command string
// THIS IS A VERY LONG METHOD !!
- (NSDictionary *)dictionaryForCommandAtIndex:(unsigned int)commandIndex
{
	NSDictionary *parserDictionary, *options;
	NSMutableDictionary *commandDictionary;
	NSArray *args;
	NSMutableArray *basepaths,*files;
	NSString *aPath,*anotherPath,*aString;
	NSFileManager *fileManager;
	BOOL exists,isDir;
	NSEnumerator *e;

	DDLog(NSStringFromClass([self class]),10,@"[%@:%p %s %d]",[self class],self,_cmd,commandIndex);

	//final dictionary to send
	commandDictionary=[NSMutableDictionary dictionaryWithCapacity:9];
	
	//parse the line at commandIndex stored by the input interface
	aString=[[self valueForKey:@"inputInterface"] lineAtIndex:commandIndex];
	parserDictionary=[[XGSParser sharedParser] parsedCommandDictionaryWithCommandString:aString];
	options=[parserDictionary valueForKey:XGSParserResultsOptionsKey];
	fileManager=[NSFileManager defaultManager];
	
	//stdout path
	args=[options objectForKey:@"so"];
	if ([args count]>0) {
		aPath=[args objectAtIndex:0];
		aPath=[self absolutePathForString:aPath];
		[commandDictionary setObject:aPath forKey:StdoutPathKey];
	}

	//stderr path
	args=[options objectForKey:@"se"];
	if ([args count]>0) {
		aPath=[args objectAtIndex:0];
		aPath=[self absolutePathForString:aPath];
		[commandDictionary setObject:aPath forKey:StderrPathKey];
	}
	
	//output dir path
	args=[options objectForKey:@"out"];
	if ([args count]>0) {
		aPath=[args objectAtIndex:0];
		aPath=[self absolutePathForString:aPath];
		[commandDictionary setObject:aPath forKey:OutputPathKey];
	}
	
	//standard in path
	args=[options objectForKey:@"si"];
	if ([args count]>0) {
		aString=[args objectAtIndex:0];
		aPath=[self absolutePathForString:aString];
		if ([fileManager fileExistsAtPath:aPath])
			//the argument for the -si option is a path
			[commandDictionary setObject:aPath forKey:StdinPathKey];
	}
		
	//working directory
	args = [options objectForKey:@"in"];
	if ( [args count] > 0 ) {
		aPath = [args objectAtIndex:0];
		aPath = [self absolutePathForString:aPath];
		isDir = NO;
		exists = [fileManager fileExistsAtPath:aPath isDirectory:&isDir];
		if ( exists==NO || isDir==NO )
			;//[[self valueForKey:@"outputInterface"] logLevel:2 format:@"Task %d, -in option: no working directory at path %@\n",commandIndex,aPath];
		else
			[commandDictionary setObject:aPath forKey:WorkingDirectoryKey];

	}

	//basepaths = from option '-dirs' --> will be later used to recognize shortcuts for the files that they contain
	basepaths=[NSMutableArray array];
	args=[options objectForKey:@"dirs"];
	e=[args objectEnumerator];
	while (aPath=[e nextObject]) {
		anotherPath=[self absolutePathForString:aPath];
		isDir=NO;
		exists=[fileManager fileExistsAtPath:anotherPath isDirectory:&isDir];
		if ( exists==NO || isDir==NO )
			;//[[self valueForKey:@"outputInterface"] logLevel:2 format:@"Task %d, -dirs option: no directory at path %@\n", commandIndex,aPath];
		else
			[basepaths addObject:anotherPath];
	}
	if ([basepaths count]>0)
		[commandDictionary setObject:basepaths forKey:BasePathsKey];
	
	//option '-files' --> will be later scanned for relative paths and shortcuts
	files=[NSMutableArray array];
	args=[options objectForKey:@"files"];
	if ([args count]>0)
		[commandDictionary setObject:args forKey:FilesKey];
	
	//Command string --> will be later scanned for relative paths and shortcuts
	aString=[parserDictionary objectForKey:XGSParserResultsCommandKey];
	if ([aString length]>0)
		[commandDictionary setObject:aString forKey:CommandKey];
	
	//Argument strings = same process as command string
	args=[parserDictionary objectForKey:XGSParserResultsArgumentsKey];
	if ([args count]>0)
		[commandDictionary setObject:args forKey:ArgumentsKey];
	
	//return a non-mutable dictionary
	return [NSDictionary dictionaryWithDictionary:commandDictionary];
}

//the command dictionary for the prototype is cached (an example of too early optimization??)
- (NSDictionary *)prototypeCommandDictionary
{
	DDLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	if (prototypeCommandDictionary==nil) {
		prototypeCommandDictionary=[[self dictionaryForCommandAtIndex:0] copy];
	}
	return prototypeCommandDictionary;
}

//the shortcut dictionary for the prototype is cached (another example of too early optimization??)
- (NSDictionary *)prototypeShortcutDictionary
{
	NSDictionary *temp;
	DDLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	if (prototypeShortcutDictionary==nil) {
		temp=[self prototypeCommandDictionary];
		temp=[self shortcutDictionaryForBasePaths:[temp objectForKey:BasePathsKey]];
		prototypeShortcutDictionary=[temp copy];
	}
	return prototypeShortcutDictionary;
}

//the final dictionary is generated by merging the dictionaries for the prototype and the command at line commandIndex
//and then resolving potential relative paths and shortcuts
- (NSDictionary *)finalDictionaryForCommandAtIndex:(unsigned int)commandIndex
{
	DDLog(NSStringFromClass([self class]),10,@"[%@:%p %s %d]",[self class],self,_cmd,commandIndex);

	//this is the returned dictionary, for now it is mutable
	NSMutableDictionary *finalDictionary;
	
	//merge prototype and command dictionaries
	NSDictionary *commandDictionary = [self dictionaryForCommandAtIndex:commandIndex];
	if ( commandIndex != 0) {
		finalDictionary = [NSMutableDictionary dictionaryWithDictionary:[self prototypeCommandDictionary]];
		[finalDictionary addEntriesFromDictionary:commandDictionary];
	} else
		finalDictionary = [NSMutableDictionary dictionaryWithDictionary:commandDictionary];
	
	//generate the shortcut dictionary from the basepaths of the current command or of the prototype
	NSArray *basepaths = [commandDictionary objectForKey:BasePathsKey];
	NSDictionary *shortcutDictionary;
	if ( basepaths == nil ) {
		//try the prototype
		basepaths = [[self prototypeCommandDictionary] objectForKey:BasePathsKey];
		shortcutDictionary = [self prototypeShortcutDictionary];
	}
	else
		shortcutDictionary = [self shortcutDictionaryForBasePaths:basepaths];
	
	//we will need the file manager to check if files exist
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	//the paths will ultimately hold all of the paths that need to be uploaded for the task
	//these paths are all absolute
	NSMutableArray *paths = [NSMutableArray array];
	
	//each base paths is added to the uploaded paths to ensure the agent will create at least the root directory of each basepath
	[paths addObjectsFromArray:basepaths];
	
	//all the paths in the working directory are added (except for the root)
	//(note there could be a bug/limitation here: if the working dir is part of one of the -dirs, the working dir will be sucked in the -dir and will not be the working directory on the agent --> to add to the docs!!)
	NSString *aPath = [finalDictionary objectForKey:WorkingDirectoryKey];
	NSDirectoryEnumerator *edir = [fileManager enumeratorAtPath:aPath];
	NSString *anotherPath;
	while ( anotherPath = [edir nextObject] )
		[paths addObject:[aPath stringByAppendingPathComponent:anotherPath]];
	
	//scan the -files for relative paths and shortcuts (skip non existing files)
	NSArray *files = [finalDictionary objectForKey:FilesKey];
	NSEnumerator *e=[files objectEnumerator];
	while (aPath=[e nextObject]) {
		//try to resolve the path the easy way
		anotherPath=[self absolutePathForString:aPath];
		if ([fileManager fileExistsAtPath:anotherPath])
			[paths addObject:anotherPath];
		//then maybe it is in the shortcut dictionary
		else if (anotherPath=[shortcutDictionary objectForKey:aPath])
			[paths addObject:anotherPath];
		else
			;//Error [[self valueForKey:@"outputInterface"] logLevel:2 format:@"Task %d: the file %@ could not be found\n",commandIndex,aPath];
	}
	
	//scan the command string for relative paths and shortcuts, otherwise keep the string as is
	aPath=[finalDictionary objectForKey:CommandKey];
	if (aPath!=nil) {
		//if absolute path but not using '~' to get to the home folder, use as is...
		if ( ( [aPath rangeOfString:@"~"].location != 0 ) && [aPath isAbsolutePath] ) {
			[finalDictionary setObject:aPath forKey:CommandKey];
		} else {
			//is it a path relative to the working directory or home directory, for a file that exists?
			anotherPath=[self absolutePathForString:aPath];
			if ([fileManager fileExistsAtPath:anotherPath])
				[paths addObject:anotherPath];
			//or maybe it is a shortcut to a file in one of the -dirs?
			else if (anotherPath=[shortcutDictionary objectForKey:aPath])
				[paths addObject:anotherPath];
			//no, this is just a relative path to something on the agent... don't upload, just use the string
			else
				anotherPath=aPath;
			[finalDictionary setObject:anotherPath forKey:CommandKey];
		}
	}
	
	//Argument strings = same process as command string
	NSArray * args = [finalDictionary objectForKey:ArgumentsKey];
	if ([args count]>0) {
		NSMutableArray *finalArgs = [NSMutableArray arrayWithCapacity:[args count]];
		e = [args objectEnumerator];
		//we call it 'aPath', but it could be anything; if it is indeed a path, then it is interesting
		while (aPath=[e nextObject]) {
			//if absolute path, use as is...
			if ( ( [aPath rangeOfString:@"~"].location != 0 ) && [aPath isAbsolutePath] ) {
				[finalArgs addObject:aPath];
			} else {
				//is it a path relative to the working directory or home directory, for a file that exists?
				anotherPath=[self absolutePathForString:aPath];
				if ([fileManager fileExistsAtPath:anotherPath])
					[paths addObject:anotherPath];
				//or maybe it is a shortcut to a file in one of the -dirs?
				else if (anotherPath=[shortcutDictionary objectForKey:aPath])
					[paths addObject:anotherPath];
				//no, this is just a string... don't upload, just use the string
				else
					anotherPath=aPath;
				[finalArgs addObject:anotherPath];
			}
		}
		[finalDictionary setObject:finalArgs forKey:ArgumentsKey];
	}
	
	//all of the paths from the working dir, the command and the argument strings have been changed to absolute paths as needed, and have been stored in the 'paths' variable
	//these paths are stored in the finalDictionary, PathsKey (different from the FilesKey = from the -files arguments)
	[finalDictionary setObject:paths forKey:PathsKey];
	
	DDLog(NSStringFromClass([self class]),10,@"[%@:%p %s] --> %@",[self class],self,_cmd,finalDictionary);

	//return a non-mutable dictionary
	return [NSDictionary dictionaryWithDictionary:finalDictionary];
}

#pragma mark *** data source methods for GEZMetaJob ***

- (unsigned int)numberOfTasksForMetaJob:(GEZMetaJob *)aJob
{
	DDLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	[[self inputInterface] loadFile];
	return [[[self inputInterface] valueForKey:@"countLines"] unsignedIntValue];
}


//this implementation is a left-over from previous version where taskDescription could be directly handed over to GEZMetaJob; the implementation of MetaJob has been changed, so the dictionary has to be actually different, so the whole thing looks a bit awkward now
- (id)metaJob:(GEZMetaJob *)metaJob taskAtIndex:(unsigned int)taskIndex
{
	DDLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	if ( taskIndex > [self numberOfTasksForMetaJob:metaJob] || taskIndex < 0 )
		return nil;
	
	//this is the dictionary generated by self
	NSDictionary *taskDescription = [self finalDictionaryForCommandAtIndex:taskIndex];
	
	//this is the dictionary needed by GEZMetaJob
	NSMutableDictionary *taskObject = [NSMutableDictionary dictionaryWithCapacity:4];
	
	//only add entries that are releavant
	NSString *stdinPath = [taskDescription objectForKey:StdinPathKey];
	if ( stdinPath != nil )
		[taskObject setObject:stdinPath forKey:GEZTaskSubmissionStandardInputKey];
	NSString *commandString = [taskDescription objectForKey:CommandKey];
	if ( commandString != nil )
		[taskObject setObject:commandString forKey:GEZTaskSubmissionCommandKey];
	NSArray *arguments = [taskDescription objectForKey:ArgumentsKey];
	if ( arguments != nil )
		[taskObject setObject:arguments forKey:GEZTaskSubmissionArgumentsKey];
	NSArray *paths = [taskDescription objectForKey:PathsKey];
	if  ( paths != nil )
		[taskObject setObject:paths forKey:GEZTaskSubmissionUploadedPathsKey];
	
	return [NSDictionary dictionaryWithDictionary:taskObject];
}


- (BOOL)metaJob:(GEZMetaJob *)metaJob validateTaskAtIndex:(int)taskIndex results:(NSDictionary *)results;
{
/*TODO : save to files*/

	BOOL resultsAreValid = [[self validator] validateFiles:results];
	
	//I will need that information to process some of the results
	NSDictionary *task = [self finalDictionaryForCommandAtIndex:taskIndex];
	
	//in this dictionary, all the files that will be saved in the default path (not handled by -so, -se or -out)
	NSMutableDictionary *resultsAutosaved = [NSMutableDictionary dictionaryWithCapacity:[results count]];
	int streamCount = 0;
	
	//stdout might be handled by the -so flag
	NSData *stdoutData = [results objectForKey:GEZJobResultsStandardOutputKey];
	if ( stdoutData != nil ) {
		streamCount ++;
		NSString *stdoutPath = [task objectForKey:StdoutPathKey];
		if ( stdoutPath != nil )
			[[self outputInterface] saveData:stdoutData withPath:stdoutPath];
		else
			[resultsAutosaved setObject:stdoutData forKey:GEZJobResultsStandardOutputKey];
	}

	//stderr might be handled by the -se flag
	NSData *stderrData = [results objectForKey:GEZJobResultsStandardErrorKey];
	if ( stderrData != nil ) {
		streamCount ++;
		NSString *stderrPath = [task objectForKey:StderrPathKey];
		if ( stderrPath != nil )
			[[self outputInterface] saveData:stderrData withPath:stderrPath];
		else
			[resultsAutosaved setObject:stderrData forKey:GEZJobResultsStandardErrorKey];
	}
		
	//results files might be handled by the -out flag, in which case outputPath != nil
	if ( [results count] > streamCount ) {
		//remove the streams from the results
		NSMutableDictionary *filesOnly = [NSMutableDictionary dictionaryWithDictionary:results];
		[filesOnly removeObjectForKey:GEZJobResultsStandardOutputKey];
		[filesOnly removeObjectForKey:GEZJobResultsStandardErrorKey];
		NSString *outputPath = [task objectForKey:OutputPathKey];
		if ( outputPath != nil )
			[[self outputInterface] saveFiles:filesOnly inFolder:outputPath];
		else
			[resultsAutosaved addEntriesFromDictionary:filesOnly];
	}
	
	//whatever is left to be saved will be saved in the default output folder; the path to use for the output interface is different for valid and invalid results; results are grouped in subfolders if more than the max allowed
	if ( [resultsAutosaved count] > 0 ) {
		NSString *resultSubPath;
		if ( resultsAreValid )
			resultSubPath = @"";
		else
			resultSubPath = @"failures";
		int total = [[[self inputInterface] valueForKey:@"countLines"] unsignedIntValue];
		int max = [[self valueForKey:@"maxTasksPerFolder"] intValue];
		if ( total > max ) {
			int start, end;
			start = taskIndex / max;
			start *= max;
			end = start + max - 1;
			NSString *rangeSubPath = [NSString stringWithFormat:@"%d-%d/",start,end];
			resultSubPath = [resultSubPath stringByAppendingPathComponent:rangeSubPath];
		}
		resultSubPath = [resultSubPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d",taskIndex]];
		[[self outputInterface] saveFiles:resultsAutosaved inFolder:resultSubPath duplicatesInSubfolder:@"results"];
	}
	
		//for debug purposes
	DDLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@ --> %@",[self class],self,_cmd,[self shortDescription],resultsAreValid?@"SUCCESS":@"FAILURE");

	return resultsAreValid;
}


@end
