//
//  XGSInputInterface.m
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

#import "XGSInputInterface.h"

@implementation XGSInputInterface

- (NSString *)shortDescription
{
	return [NSString stringWithFormat:@"InputInterface with file '%@'",[self primitiveValueForKey:@"filePath"]];
}

- (void)dealloc
{
	[lines release];
	lines=nil;
	[super dealloc];
}


- (NSString *)filePath
{
	[self willAccessValueForKey:@"filePath"];
	NSString *filePathLocal = [self primitiveValueForKey:@"filePath"];
	[self didAccessValueForKey:@"filePath"];
	return filePathLocal;
}

- (void)setFilePath:(NSString *)filePathNew
{
	[self willChangeValueForKey:@"filePath"];
	[self setPrimitiveValue:filePathNew forKey:@"filePath"];
	[self didChangeValueForKey:@"filePath"];
}

- (void)setLines:(NSArray *)newArray
{
	DDLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	[newArray retain];
	[lines release];
	lines=newArray;
	[self setValue:[NSNumber numberWithInt:[lines count]] forKey:@"countLines"];
}

- (NSString *)stringWithFileContents
{
	DDLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);

	NSString *contents = nil;

	//already in store
	BOOL storeFlag = [[self valueForKey:@"shouldStoreFileContents"] boolValue];
	if ( storeFlag ) {
		contents = [self valueForKey:@"fileContents"];
		if ( contents!=nil )
			return contents;
	}
	
	//read the file and make a string with it
	NSString *path = [self valueForKey:@"filePath"];
	/*** THIS METHOD IS DEPCRECATED BUT I COULD NOT GET THE RECOMMANDED METHOD TO WORK ***/
	contents = [NSString stringWithContentsOfFile:path];
	if ( storeFlag )
		[self setValue:contents forKey:@"fileContents"];
	return contents;
}

- (void)resetLines
{
	DDLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	[self setLines:nil];
	NSString *commands = [self stringWithFileContents];
	if ( commands == nil )
		[self setLines:[NSArray array]];
	else
		[self setLines:[commands componentsSeparatedByString:@"\n"]];
}

- (NSArray *)lines
{
	DDLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	if ( lines == nil )
		[self resetLines];
	return lines;
}

- (NSString *)lineAtIndex:(unsigned int)index
{
	DDLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	return [[self lines] objectAtIndex:index];
}

- (void)loadFile
{
	DDLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	if ( lines == nil )
		[self resetLines];
}

@end
