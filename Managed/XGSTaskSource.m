//
//  XGSTaskSource.m
//  GridStuffer
//
//  Created by Charles Parnot on 5/12/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//

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
static NSString *StdinStringKey=@"Stdin string";
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
	XGSInputInterface *result;
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	[self willAccessValueForKey:@"inputInterface"];
	result = [self primitiveValueForKey:@"inputInterface"];
	[self didAccessValueForKey:@"inputInterface"];
	return result;
}

- (XGSOutputInterface *)ouputInterface;
{
	XGSOutputInterface *result;
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	[self willAccessValueForKey:@"outputInterface"];
	result = [self primitiveValueForKey:@"outputInterface"];
	[self didAccessValueForKey:@"outputInterface"];
	return result;
}


#pragma mark *** command parsing ***

//this is the working directory on the client,
//upon which any relative path is based on
- (NSString *)workingDirectoryPath
{
	NSString *result;
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	result=[self valueForKeyPath:@"inputInterface.filePath"];
	result=[result stringByStandardizingPath];
	result=[result stringByDeletingLastPathComponent];
	return result;
}

//takes a string, supposedly a relative or absolute path, and make it absolute, prepending the working directory if necessary
- (NSString *)absolutePathForString:(NSString *)relativePath
{
	NSString *finalPath;
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	
	//is it really a relative path??
	finalPath=[relativePath stringByExpandingTildeInPath];
	if ([finalPath isAbsolutePath])
		return [finalPath stringByStandardizingPath];
	
	//yes, so we need to prefix it with the working directory path
	finalPath=[self workingDirectoryPath];
	finalPath=[finalPath stringByAppendingPathComponent:relativePath];
	finalPath=[finalPath stringByStandardizingPath];

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
	
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
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

	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);

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

	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s %d]",[self class],self,_cmd,commandIndex);

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
	
	//standard in
	args=[options objectForKey:@"si"];
	if ([args count]>0) {
		aString=[args objectAtIndex:0];
		aPath=[self absolutePathForString:aString];
		if ([fileManager fileExistsAtPath:aPath])
			//the argument for the -si option is a path
			[commandDictionary setObject:aPath forKey:StdinPathKey];
		else
			//consider that the argument is in fact a string
			[commandDictionary setObject:aString forKey:StdinStringKey];
	}
		
	//working directory
	args=[options objectForKey:@"in"];
	if ([args count]>0) {
		aPath=[args objectAtIndex:0];
		aPath=[self absolutePathForString:aPath];
		isDir=NO;
		exists=[fileManager fileExistsAtPath:aPath isDirectory:&isDir];
		if ( exists==NO || isDir==NO )
			[[self valueForKey:@"outputInterface"] logLevel:2 format:@"Task %d, -in option: no working directory at path %@\n",commandIndex,aPath];
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
			[[self valueForKey:@"outputInterface"] logLevel:2 format:@"Task %d, -dirs option: no directory at path %@\n", commandIndex,aPath];
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
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	if (prototypeCommandDictionary==nil) {
		prototypeCommandDictionary=[[self dictionaryForCommandAtIndex:0] copy];
	}
	return prototypeCommandDictionary;
}

//the shortcut dictionary for the prototype is cached (another example of too early optimization??)
- (NSDictionary *)prototypeShortcutDictionary
{
	NSDictionary *temp;
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
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
	NSDictionary *commandDictionary,*shortcutDictionary;
	NSMutableDictionary *finalDictionary;
	NSArray *basepaths,*files,*args;
	NSMutableArray *paths,*finalArgs;
	NSString *aPath,*anotherPath;
	NSFileManager *fileManager;
	NSDirectoryEnumerator *edir;
	NSEnumerator *e;

	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s %d]",[self class],self,_cmd,commandIndex);

	//merge prototype and command dictionaries
	commandDictionary=[self dictionaryForCommandAtIndex:commandIndex];
	if (commandIndex!=0) {
		finalDictionary=[NSMutableDictionary dictionaryWithDictionary:[self prototypeCommandDictionary]];
		[finalDictionary addEntriesFromDictionary:commandDictionary];
	} else
		finalDictionary=[NSMutableDictionary dictionaryWithDictionary:commandDictionary];
	
	//generate the shortcut dictionary from the basepaths of the current command or of the prototype
	basepaths = [commandDictionary objectForKey:BasePathsKey];
	if ( basepaths==nil ) {
		//try the prototype
		basepaths = [[self prototypeCommandDictionary] objectForKey:BasePathsKey];
		shortcutDictionary = [self prototypeShortcutDictionary];
	}
	else
		shortcutDictionary = [self shortcutDictionaryForBasePaths:basepaths];
	
	//we will need the file manager to check if files exist
	fileManager=[NSFileManager defaultManager];
	
	//the paths will ultimately hold all of the paths that need to be uploaded for the task
	//these paths are all absolute
	paths=[NSMutableArray array];
	
	//each base paths is added to the uploaded paths to ensure the agent will create at least the root directory of each basepath
	[paths addObjectsFromArray:basepaths];
	
	//all the paths in the working directory are added (except for the root)
	//(note there could be a bug/limitation here: if the working dir is part of one of the -dirs, the working dir will be sucked in the -dir and will not be the working directory on the agent --> to add to the docs!!)
	aPath = [finalDictionary objectForKey:WorkingDirectoryKey];
	edir = [fileManager enumeratorAtPath:aPath];
	while (anotherPath = [edir nextObject])
		[paths addObject:[aPath stringByAppendingPathComponent:anotherPath]];
	
	//scan the -files for relative paths and shortcuts (skip non existing files)
	files=[finalDictionary objectForKey:FilesKey];
	e=[files objectEnumerator];
	while (aPath=[e nextObject]) {
		//try to resolve the path the easy way
		anotherPath=[self absolutePathForString:aPath];
		if ([fileManager fileExistsAtPath:anotherPath])
			[paths addObject:anotherPath];
		//then maybe it is in the shortcut dictionary
		else if (anotherPath=[shortcutDictionary objectForKey:aPath])
			[paths addObject:anotherPath];
		else
			[[self valueForKey:@"outputInterface"] logLevel:2 format:@"Task %d: the file %@ could not be found\n",commandIndex,aPath];
	}
	
	//scan the command string for relative paths and shortcuts, otherwise keep the string as is
	aPath=[finalDictionary objectForKey:CommandKey];
	if (aPath!=nil) {
		//if absolute path, use as is...
		if ([aPath isAbsolutePath]) {
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
	args=[finalDictionary objectForKey:ArgumentsKey];
	if ([args count]>0) {
		finalArgs=[NSMutableArray arrayWithCapacity:[args count]];
		e=[args objectEnumerator];
		//we call it 'aPath', but it could be anything; if it is indeed a path, then it is interesting
		while (aPath=[e nextObject]) {
			//if absolute path, use as is...
			if ([aPath isAbsolutePath]) {
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
	
	//all of the paths in the command and argument strings have been changed to absolute paths if they correspond to existing files
	//now, to make sure they get uploaded, we keep track of those files using the PathsKey (the FilesKey were from the -files arguments)
	[finalDictionary setObject:paths forKey:PathsKey];
	
	//return a non-mutable dictionary
	return [NSDictionary dictionaryWithDictionary:finalDictionary];
}

#pragma mark *** data source methods for XGSMetaJob ***

- (unsigned int)numberOfTasksForMetaJob:(XGSMetaJob *)aJob
{
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	[[self inputInterface] loadFile];
	return [[[self inputInterface] valueForKey:@"countLines"] unsignedIntValue];
}

- (id)metaJob:(XGSMetaJob *)metaJob taskAtIndex:(unsigned int)taskIndex
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	if ( taskIndex > [self numberOfTasksForMetaJob:metaJob] || taskIndex < 0 )
		return nil;
	else
		return [self finalDictionaryForCommandAtIndex:taskIndex];
}

- (NSString *)metaJob:(XGSMetaJob *)metaJob commandStringForTask:(id)task
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	return [task objectForKey:CommandKey];
}

- (NSArray *)metaJob:(XGSMetaJob *)metaJob argumentStringsForTask:(id)task
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	return [task objectForKey:ArgumentsKey];
}

- (NSArray *)metaJob:(XGSMetaJob *)metaJob pathsToUploadForTask:(id)task
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	return [task objectForKey:PathsKey];
}

- (NSString *)metaJob:(XGSMetaJob *)metaJob stdinPathForTask:(id)task;
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	return [task objectForKey:StdinPathKey];
}

- (NSString *)metaJob:(XGSMetaJob *)metaJob stdinStringForTask:(id)task;
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	return [task objectForKey:StdinStringKey];
}

- (BOOL)metaJob:(XGSMetaJob *)metaJob validateResultsWithFiles:(NSDictionary *)files standardOutput:(NSData *)stdoutData standardError:(NSData *)stderrData forTask:(id)task;
{
	BOOL resultsAreGood = [[self valueForKey:@"validator"] validateFiles:files standardOutput:stdoutData standardError:stderrData];
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@ --> %@",[self class],self,_cmd,[self shortDescription],resultsAreGood?@"SUCCESS":@"FAILURE");
	return resultsAreGood;
}

- (BOOL)metaJob:(XGSMetaJob *)metaJob saveStandardOutput:(NSData *)data forTask:(id)task
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s]",[self class],self,_cmd);
	DLog(NSStringFromClass([self class]),15,@"\nTask:\n%@",[task description]);	
	DLog(NSStringFromClass([self class]),15,@"\nStdout:\n%@",[[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding] autorelease]);
	return NO;
}

- (BOOL)metaJob:(XGSMetaJob *)metaJob saveStandardError:(NSData *)data forTask:(id)task
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s]",[self class],self,_cmd);
	DLog(NSStringFromClass([self class]),15,@"\nTask:\n%@",[task description]);	
	DLog(NSStringFromClass([self class]),10,@"\nStderr:\n%@",[[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding] autorelease]);
	return NO;
}

- (BOOL)metaJob:(XGSMetaJob *)metaJob saveFiles:(NSDictionary *)dictionaryRepresentation forTask:(id)task
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s]",[self class],self,_cmd);
	DLog(NSStringFromClass([self class]),15,@"\nTask:\n%@",[task description]);	
	DLog(NSStringFromClass([self class]),15,@"\nFiles:\n%@",[dictionaryRepresentation description]);
	return NO;
}

//unused data source methods
/*
- (BOOL)initializeTasksForMetaJob:(XGSMetaJob *)metaJob;
- (NSData *)metaJob:(XGSMetaJob *)metaJob stdinDataForTask:(id)task 
*/

@end
