//
//  XGSParser.m
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

#import "XGSParser.h"
#import "XGSCategories.h"
static XGSParser *sharedParser=nil;

//Keys used in the parsedCommandDictionary
NSString *XGSParserResultsOptionsKey=@"Options";
NSString *XGSParserResultsCommandKey=@"Command";
NSString *XGSParserResultsArgumentsKey=@"Arguments";

@implementation XGSParser

+ (XGSParser *)sharedParser
{
	if (sharedParser==nil)
		sharedParser=[[self alloc] init];
	return sharedParser;
}

#pragma mark *** parsing command strings ***

//one block = separated from others by spaces or tabs or any combination of boths
//spaces ignored if quotes, quotes removed
//the escape character '\' can be used to escape space, tab, quotes and itself
- (NSString *)nextBlockWithScanner:(NSScanner *)scanner error:(NSString **)errorDescription
{
	NSCharacterSet *specialCharacters;
	BOOL singleQuoted;
	BOOL doubleQuoted;
	BOOL isAtEnd;
	NSMutableString *result;
	NSString *temp;
	unichar nextCharacter;
	
	//BOOL switches to keep track of quotes: are we in or out?
	//initialily, we are out
	singleQuoted=NO;
	doubleQuoted=NO;
	isAtEnd=NO;
	
	//we should not skip any character
	[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
	
	//characters to look for when outside of quotes are:
	//	single quote, double quote, escape character \, space and tab
	specialCharacters=[NSCharacterSet characterSetWithCharactersInString:@" \t'\"\\"];
	
	//this is the final string that will hold the result
	result=[NSMutableString string];
	
	//move to the first character that is not a space
	[scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];
	
	//loop until a space is found and we are not inside quotes
	while ( !isAtEnd && ![scanner isAtEnd]) {
		temp=nil;
		if ( singleQuoted  )
			//if we are inside a single quoted text, get to the next single quote
			[scanner scanUpToString:@"'" intoString:&temp];
		else if (doubleQuoted)
			//if we are inside a double quoted text, get to the next double quote
			[scanner scanUpToString:@"\"" intoString:&temp];
		else
			//if we are not inside quote, get to the next special character
			[scanner scanUpToCharactersFromSet:specialCharacters intoString:&temp];
		
		//add the intermediary result string to the final result
		if (temp!=nil)
			[result appendString:temp];
		
		//what is the next special character?
		nextCharacter=[scanner XGS_scanNextCharacter];
		if ( (nextCharacter==' ') || (nextCharacter=='\t') )
			isAtEnd=YES;
		else if (nextCharacter=='\'')
			singleQuoted=!singleQuoted;
		else if (nextCharacter=='"')
			doubleQuoted=!doubleQuoted;
		else if (nextCharacter=='\\') {
			//add the escaped character to the final result string
			nextCharacter=[scanner XGS_scanNextCharacter];
			[result appendFormat:@"%C",nextCharacter];
		} 
	}
	
	//was there an error?
	if (errorDescription!=NULL) {
		if (singleQuoted)
			*errorDescription=@"Missing single quote (')\n";
		else if (doubleQuoted)
			*errorDescription=@"Missing double quote (\")\n";
		else
			*errorDescription=nil;
	}
	
	//return the concatenated string resulting from the scan
	return result;
}

//get an array of blocks from a string, by repeatedly calling
//- (NSString *)nextBlockWithScanner:(NSScanner *)scanner error:(NSString **)errorDescription
- (NSArray *)blocksWithCommandString:(NSString *)commandString error:(NSString **)errorDescription
{
	NSScanner *scanner;
	NSString *block,*error;
	NSMutableString *allErrors;
	NSMutableArray *blocks;
	
	//retrieve the different 'blocks' from the command string
	scanner=[NSScanner scannerWithString:commandString];
	blocks=[NSMutableArray array];
	allErrors=[NSMutableString string];
	while (![scanner isAtEnd]) {
		error=nil;
		block=[self nextBlockWithScanner:scanner error:&error];
		if ( (block!=nil) && (![block isEqualToString:@""]) && (![block isEqualToString:@" "]) )
			[blocks addObject:block];
		if (error!=nil)
			[allErrors appendString:error];
	}
	
	//were there errors?
	if (errorDescription!=NULL) {
		if ([allErrors isEqualToString:@""])
			*errorDescription=nil;
		else
			*errorDescription=[NSString stringWithString:allErrors];
	}
	
	//return the block array
	return [NSArray arrayWithArray:blocks];
}

//check if the command starts with 'xgrid -job submit' or 'xgrid -job run'
- (NSArray *)blocksByRemovingOptionalSuffixInBlocks:(NSArray *)blocks
{
	NSArray *commandSuffixTemplate1,*commandSuffixTemplate2,*commandSuffix;
	int countBlocks;
	countBlocks=[blocks count];
	if (countBlocks>2) {
		commandSuffix=[blocks subarrayWithRange:NSMakeRange(0,3)];
		commandSuffixTemplate1=[NSArray arrayWithObjects:@"xgrid",@"-job",@"submit",nil];
		commandSuffixTemplate2=[NSArray arrayWithObjects:@"xgrid",@"-job",@"run",nil];
		if ( [commandSuffix isEqualToArray:commandSuffixTemplate1]
			 || [commandSuffix isEqualToArray:commandSuffixTemplate2] )
			blocks=[blocks subarrayWithRange:NSMakeRange(3,countBlocks-3)];
	}
	return blocks;
}

- (NSDictionary *)parsedCommandDictionaryWithCommandString:(NSString *)commandString
{
	NSEnumerator *e;
	NSString *block,*currentFlag,*error;
	NSMutableDictionary *options,*results;
	NSMutableString *allErrors;
	NSMutableArray *args;
	NSArray *blocks;
	int n;

	//initialize the allErrors string where we will concatenate error messages, if any
	allErrors=[NSMutableString string];

	//retrieve the different 'blocks' from the command string
	blocks=[self blocksWithCommandString:commandString error:&error];
	if (error!=nil)
		[allErrors appendString:error];

	//remove optional 'xgrid -job submit' or 'xgrid -job run'
	blocks=[self blocksByRemovingOptionalSuffixInBlocks:blocks];
	
	//if nothing left, this is just an empty command (maybe the prototype will apply then)
	if ( [blocks count]<1 )
		return [NSDictionary dictionary];
	
	//otherwise, we will have something in the dictionary (up to 3 items)
	results=[NSMutableDictionary dictionaryWithCapacity:3];
	
	//there are options to consider ONLY if the first block starts with a '-'
	//otherwise, there are no gridstuffer options, and it is just a command and arguments
	block = [blocks objectAtIndex:0];
	if ( ([block length] > 1) && [[block substringToIndex:1] isEqualToString:@"-"]) {
		//we have to loop the blocks and look for flags (start with '-') and their args
		args=[NSMutableArray array]; //will hold the arguments for the different options
		options=[NSMutableDictionary dictionary];
		currentFlag=nil; //will hold the latest flag dicovered (initially none)
		e=[blocks objectEnumerator];
		while (block=[e nextObject]) {
			//if this is a flag (e.g. -x), save the arguments for the previous flag and start a new one
			if ( ([block length] > 1) && [[block substringToIndex:1] isEqualToString:@"-"]) {
				if (currentFlag!=nil)
					[options setValue:[NSArray arrayWithArray:args] forKey:currentFlag];
				currentFlag=[block substringFromIndex:1];
				[args removeAllObjects];
			} else
				//otherwise, add more args to the current flag/option
				[args addObject:block];
		}
		//finish the last flag, taking only the first item in the args array, as the others items will be the command and argument strings
		n=[args count];
		if ( n>0 ) {
			[options setValue:[NSArray arrayWithObject:[args objectAtIndex:0]] forKey:currentFlag];
			[args removeObjectAtIndex:0];
			n--;
		} else
			[options setValue:[NSArray array] forKey:currentFlag];
		//finally, we put these options and their args as one entry in the parser dictionary
		[results setValue:[NSDictionary dictionaryWithDictionary:options] forKey:XGSParserResultsOptionsKey];
	}
	
	//this is the alternative thing to do if there are no gridstuffer options: we only have a command and some arguments
	else {
		args = (NSMutableArray *)blocks; //we don't care if it is not mutable at this point
		n = [args count];
	}
		
	//the command and arguments (if any) are now in the args array and we are ready to build the final dictionary
	if (n>0)
		[results setValue:[args objectAtIndex:0] forKey:XGSParserResultsCommandKey];
	if (n>1)
		[results setValue:[args subarrayWithRange:NSMakeRange(1,n-1)] forKey:XGSParserResultsArgumentsKey];

	return [NSDictionary dictionaryWithDictionary:results];
}


@end



/*
Syntax of the input file:
	 * one string = one line in the input file, lines separated by \r or \n
     * 'xgrid -job submit' or 'xgrid -job run' is optional and ignored if present
	   at the beginning of a line
     * each line is something like :
       -ex exarg -in inarg -file file1 file2 file3 -si siarg command arg1 arg2 ...
 
Implementation of the parsing:
	* 'parsedCommandDictionaryWithCommandString:' calls the following methods:
		* 'blocksWithCommandString:error:' = generates an NSArray of NSString with the different 'blocks' of the parsed line
		* 'blocksByRemovingOptionalSuffixInBlocks:' = remove optional suffix in the form 'xgrid -job submit|run'
		* then it put groupd of blocks found after flags in arrays
		* the final flag only get one argument, the others (if any) go in the command and argument strings
	* 'blocksWithCommandString:error:' parses 'blocks' in an NSString by following the rules:
		* one block is separated by the others by spaces or tabs or any combination of boths
		* one 'block' is read using the method 'nextBlockWithScanner:error:'
		* the character '\' is used to escape spaces, tabs, quotes and itself
		* quotes (either single or double, but not mixed) can be used to escape a whole string, and nothing can be escaped inside quotes
*/
