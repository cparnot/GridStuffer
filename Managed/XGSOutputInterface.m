//
//  XGSOutputInterface.m
//  GridStuffer
//
//  Created by Charles Parnot on 5/14/05.
//  Copyright 2005, 2006, 2007, 2008 Charles Parnot. All rights reserved.
//

/* GRIDSTUFFER_LICENSE_START */
/* This file is part of GridStuffer. GridStuffer is free software; you can redistribute it and/or modify it under the terms of the Berkeley Software Distribution (BSD) Modified License.*/
/* Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the owner Charles Parnot nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */
/* GRIDSTUFFER_LICENSE_END */

#import "XGSOutputInterface.h"
#import "XGSPathUtilities.h"

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
