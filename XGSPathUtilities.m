//
//  XGSPathUtilities.m
//  GridStuffer
//
//  Created by Charles Parnot on 2/22/07.
//  Copyright 2005,2006,2007 Charles Parnot. All rights reserved.

/*
 This file is part of GridStuffer.
 GridStuffer is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
 GridStuffer is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with GridStuffer; if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#import "XGSPathUtilities.h"


BOOL CreateDirectory(NSString *aPath)
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
NSString *UniqueNameWithPath(NSString *path, unsigned int *suffix)
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

/*
@implementation XGSPathUtilities
@end
*/