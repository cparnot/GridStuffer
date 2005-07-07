//
//  XGSOutputInterface.m
//  GridStuffer
//
//  Created by Charles Parnot on 5/14/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//

#import "XGSOutputInterface.h"

@implementation XGSOutputInterface

#pragma mark *** accessors ***

- (NSString *)folderPath
{
	NSString *folderPathLocal;
	[self willAccessValueForKey:@"folderPath"];
	folderPathLocal = [self primitiveValueForKey:@"folderPath"];
	[self didAccessValueForKey:@"folderPath"];
	return folderPathLocal;
}

- (NSString *)logFileName
{
	NSString *logFileNameLocal;
	[self willAccessValueForKey:@"logFileName"];
	logFileNameLocal = [self primitiveValueForKey:@"logFileName"];
	[self didAccessValueForKey:@"logFileName"];
	return logFileNameLocal;
}

- (void)setFolderPath:(NSString *)folderPathNew
{
	[self willChangeValueForKey:@"folderPath"];
	[self setPrimitiveValue:folderPathNew forKey:@"folderPath"];
	[self didChangeValueForKey:@"folderPath"];
}

- (void)setLogFileName:(NSString *)logFileNameNew
{
	[self willChangeValueForKey:@"logFileName"];
	[self setPrimitiveValue:logFileNameNew forKey:@"logFileName"];
	[self didChangeValueForKey:@"logFileName"];
}


#pragma mark *** files saving ***

static BOOL CreateDirectory(NSString *aPath)
{
	NSString *parent;
    NSFileManager *fileManager;
	BOOL isDir;
	
	//impossible!!
    if ( ( aPath==nil ) || [aPath isEqualToString:@""] )
        return NO;
	
	//already done?
	if ( [aPath isEqualToString:@"/"] ) 
		return YES;
	fileManager = [NSFileManager defaultManager];
	isDir = NO;
    if ( [fileManager fileExistsAtPath:aPath isDirectory:&isDir] )
		return isDir;
	
	//create the parent and then the directory
    parent = [aPath stringByDeletingLastPathComponent];
	return ( CreateDirectory(parent) && [fileManager createDirectoryAtPath:aPath attributes:nil] );
}

//given a path, e.g. '/some/path/to/file.txt', returns the first suffix i > 0 such that file_i.txt does not exist yet
static NSString *UniqueNameWithPath(NSString *path)
{
    NSFileManager *fileManager;
	int n;
	NSString *name, *parent, *extension;
	BOOL hasExtension;
	
	//get the different pieces of the path
	parent = [path stringByDeletingLastPathComponent];
	extension = [path pathExtension];
	if ( [extension isEqualToString:@""] )
		hasExtension = NO;
	else
		hasExtension = YES;
	name = [[path lastPathComponent] stringByDeletingPathExtension];

	//now test different integer suffixes until the file does not exist
	// (testing n>0 ensures that the loop will end, when n reaches MAX_INT)
	fileManager = [NSFileManager defaultManager];
	n=0;
	do {
		n++;
		path = [NSString stringWithFormat:@"%@_%d",name,n];
		if ( hasExtension ) 
			 path = [path stringByAppendingPathExtension:extension];
		path = [parent stringByAppendingPathComponent:path];
	} while ( (n > 0) && ([fileManager fileExistsAtPath:path]) );
	return path;
}

- (BOOL)saveFiles:(NSDictionary *)dictionaryRepresentation inFolder:(NSString *)path
{
	NSString *rootPath,*aString,*aPath;
	NSData *someData;
	NSFileManager *fileManager;
	BOOL isDir,exists,success;
	NSArray *files;
	NSEnumerator *e;

	DLog(NSStringFromClass([self class]),10,@"[<%@:%p> %s]",[self class],self,_cmd);
	DLog(NSStringFromClass([self class]),10,@"\nFiles:\n%@",[dictionaryRepresentation description]);

	//determine the root path
	if ( [path isAbsolutePath] )
		rootPath = path;
	else {
		rootPath=[[self folderPath] stringByAppendingPathComponent:path];
	}
	
	//check existence and try to create it
	fileManager=[NSFileManager defaultManager];
	if ( [fileManager fileExistsAtPath:rootPath isDirectory:&isDir] && !isDir )
		//the 'rootpath' exists but is not a dir!
		return NO;
	if ( CreateDirectory(rootPath)==NO )
		return NO;
	
	//if one of the file already exists, we need to create inside rootpath
	//a subdirectory for that particular set, with the naming convention 'results_1', 'results_2', ...
	files = [dictionaryRepresentation allKeys];
	e = [files objectEnumerator];
	exists = NO;
	while ( ( exists==NO ) && (aPath = [e nextObject]) )
		exists = [fileManager fileExistsAtPath:[rootPath stringByAppendingPathComponent:aPath]];
	if ( exists ) {
		aPath = [rootPath stringByAppendingPathComponent:@"results"];
		rootPath = UniqueNameWithPath(aPath);
		if ( CreateDirectory(rootPath) == NO )
			return NO;
	}
	
	//now save the files to disk in rootPath
	success=YES;
	e = [files objectEnumerator];
	while ( aString = [e nextObject] ) {
		aPath = [rootPath stringByAppendingPathComponent:aString];
		if ( CreateDirectory([aPath stringByDeletingLastPathComponent]) == NO )
			success = NO;
		else {
			someData = [dictionaryRepresentation objectForKey:aString];
			if ( [someData writeToFile:aPath atomically:NO] == NO )
				success = NO;
		}
	}
	
	return success;
}

- (BOOL)saveData:(NSData *)someData withPath:(NSString *)path
{
	NSFileManager *fileManager;
	
	//determine the absolute path
	if ( [path isAbsolutePath] ==NO )
		path=[[self folderPath] stringByAppendingPathComponent:path];
	
	//if the file already exists, the file name must be changed, e.g. afile_1.txt instead of afile.txt
	fileManager=[NSFileManager defaultManager];
	if ( [fileManager fileExistsAtPath:path] )
		path = UniqueNameWithPath(path);
	
	//try to create the parent dir and the file with someData
	if ( CreateDirectory([path stringByDeletingLastPathComponent]) == NO )
		return NO;
	else
		return [someData writeToFile:path atomically:NO];
}


- (BOOL)saveData:(NSData *)someData fileName:(NSString *)fileName
{
	//TO DO!!!
	return NO;
}

- (BOOL)appendData:(NSData *)someData fileName:(NSString *)fileName
{
	//TO DO!!!
	return NO;
}

- (BOOL)saveString:(NSString *)aString fileName:(NSString *)fileName
{
	//TO DO!!!
	return NO;
}

- (BOOL)appendString:(NSString *)aString fileName:(NSString *)fileName
{
	//TO DO!!!
	return NO;
}



#pragma mark *** logging methods ***

- (unsigned int)logVerboseLevelInteger
{
	return [[self valueForKey:@"logVerboseLevel"] intValue];
}

- (void)writeString:(NSString *)message
{
	//NEED CODE!!!
	DLog(nil,0,message);
}

- (void)logString:(NSString *)message
{
	[self logLevel:1 format:message];
}


- (void)logLevel:(unsigned int)level string:(NSString *)message
{
	if (level>=[self logVerboseLevelInteger])
		[self writeString:message];
}

- (void)logLevel:(unsigned int)level format:(NSString *)format, ...
{
    va_list ap;
	NSString *message;
	if (level>=[self logVerboseLevelInteger]) {
		va_start(ap,format);
		message=[NSString stringWithFormat:format,ap];
		[self writeString:message];
	}
}

@end
