//
//  XGSInputInterface.m
//  GridStuffer
//
//  Created by Charles Parnot on 5/14/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//

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

- (void)setLines:(NSArray *)newArray
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	[newArray retain];
	[lines release];
	lines=newArray;
	[self setValue:[NSNumber numberWithInt:[lines count]] forKey:@"countLines"];
}

- (NSString *)stringWithFileContents
{
	BOOL storeFlag;
	NSString *path, *contents;
	//NSError *error;
	//NSStringEncoding encoding;

	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);

	//already in store
	storeFlag = [[self valueForKey:@"shouldStoreFileContents"] boolValue];
	if ( storeFlag ) {
		contents = [self valueForKey:@"fileContents"];
		if ( contents!=nil )
			return contents;
	}
	
	//read the file and make a string with it
	path = [self valueForKey:@"filePath"];
	/*** THIS METHOD IS DEPCRECATED BUT I COULD NOT GET THE RECOMMANDED METHOD TO WORK ***/
	contents = [NSString stringWithContentsOfFile:path];
	if ( storeFlag )
		[self setValue:contents forKey:@"fileContents"];
	return contents;
}

- (void)resetLines
{
	NSString *commands;
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	[self setLines:nil];
	commands=[self stringWithFileContents];
	if (commands==nil)
		[self setLines:[NSArray array]];
	else
		[self setLines:[commands componentsSeparatedByString:@"\n"]];
}

- (NSArray *)lines
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	if ( lines == nil )
		[self resetLines];
	return lines;
}

- (NSString *)lineAtIndex:(unsigned int)index
{
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	return [[self lines] objectAtIndex:index];
}

- (void)loadFile
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	if ( lines == nil )
		[self resetLines];
}

@end
