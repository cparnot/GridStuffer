//
//  XGSOutputInterface.m
//  GridStuffer
//
//  Created by Charles Parnot on 5/14/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//

/*
 This file is part of GridStuffer.
 GridStuffer is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
 GridStuffer is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with GridStuffer; if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

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


//given a path, e.g. '/some/path/to/file.txt', returns the path for a non-existing file with the first suffix i >= suffix, such that file_i.txt does not exist yet; the 'suffix' pointer is used both as the starting value and to return the final value
static NSString *UniqueNameWithPath(NSString *path, unsigned int *suffix)
{
    NSFileManager *fileManager;
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
	unsigned int n = *suffix - 1;
	do {
		n++;
		path = [NSString stringWithFormat:@"%@_%d",name,n];
		if ( hasExtension ) 
			 path = [path stringByAppendingPathExtension:extension];
		path = [parent stringByAppendingPathComponent:path];
	} while ( [fileManager fileExistsAtPath:path] );
	*suffix=n;
	return path;
}

- (BOOL)saveFiles:(NSDictionary *)dictionaryRepresentation inFolder:(NSString *)path
{
	return [self saveFiles:dictionaryRepresentation inFolder:path duplicatesInSubfolder:nil];
}

- (BOOL)saveFiles:(NSDictionary *)files inFolder:(NSString *)path duplicatesInSubfolder:(NSString *)duplicatesPath;
{
	NSString *rootPath,*aString,*aPath;
	NSData *someData;
	NSFileManager *fileManager;
	BOOL isDir,success;
	NSEnumerator *e;
	unsigned int suffix;

	DDLog(NSStringFromClass([self class]),10,@"[<%@:%p> %s]",[self class],self,_cmd);
	DDLog(NSStringFromClass([self class]),10,@"\nFiles:\n%@",[files description]);

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
	
	//if one of the file already exists, we need to handle things differently
	e = [files keyEnumerator];
	BOOL oneOfTheFileAlreadyExists = NO;
	while ( ( oneOfTheFileAlreadyExists==NO ) && (aPath = [e nextObject]) )
		oneOfTheFileAlreadyExists = [fileManager fileExistsAtPath:[rootPath stringByAppendingPathComponent:aPath]];

	//if oneOfTheFileAlreadyExists, we check the value of 'duplicatesPath'
	//if non-nil, use the string to create a subdirectoty inside rootpath
	//for that particular set, with the naming convention e.g. 'results_1', 'results_2', ...
	if ( oneOfTheFileAlreadyExists && (duplicatesPath != nil) ) {
		aPath = [rootPath stringByAppendingPathComponent:duplicatesPath];
		suffix = 1;
		rootPath = UniqueNameWithPath(aPath, &suffix);
		if ( CreateDirectory(rootPath) == NO )
			return NO;
	}

	//if oneOfTheFileAlreadyExists, and 'duplicatesPath' == nil
	//all the files need to be renamed with the first free _i suffix
	if ( oneOfTheFileAlreadyExists && (duplicatesPath == nil) ) {
		unsigned int lastSuffix = 0;
		suffix = 1;
		
		//loop until suffix is valid for all the paths
		while ( suffix != lastSuffix ) {
			lastSuffix = suffix;
			e = [files keyEnumerator];
			while ( aString = [e nextObject] ) {
				aPath = [rootPath stringByAppendingPathComponent:aString];
				aPath = UniqueNameWithPath(aPath, &suffix);				
			}
		}
		
		//update the files array to add the suffix
		NSMutableDictionary *modifiedFiles = [NSMutableDictionary dictionaryWithCapacity:[files count]];
		e = [files keyEnumerator];
		while ( aString = [e nextObject] ) {
			aPath = [rootPath stringByAppendingPathComponent:aString];
			aPath = UniqueNameWithPath(aPath,&suffix);
			[modifiedFiles setObject:[files objectForKey:aString] forKey:[aPath lastPathComponent]];
		}
		files = modifiedFiles;

	}
	
	//now save the files to disk in rootPath
	success=YES;
	e = [files keyEnumerator];
	while ( aString = [e nextObject] ) {
		aPath = [rootPath stringByAppendingPathComponent:aString];
		if ( CreateDirectory([aPath stringByDeletingLastPathComponent]) == NO )
			success = NO;
		else {
			someData = [files objectForKey:aString];
			if ( [someData writeToFile:aPath atomically:NO] == NO )
				success = NO;
		}
	}
	
	return success;
}

- (BOOL)saveData:(NSData *)someData withPath:(NSString *)path
{
	NSFileManager *fileManager;
	unsigned int suffix = 1;
	
	//determine the absolute path
	if ( [path isAbsolutePath] ==NO )
		path=[[self folderPath] stringByAppendingPathComponent:path];
	
	//if the file already exists, the file name must be changed, e.g. afile_1.txt instead of afile.txt
	fileManager=[NSFileManager defaultManager];
	if ( [fileManager fileExistsAtPath:path] )
		path = UniqueNameWithPath(path, &suffix);
	
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




@end
