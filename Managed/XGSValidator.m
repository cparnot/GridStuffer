//
//  XGSValidator.m
//  GridStuffer
//
//  Created by Charles Parnot on 6/27/05.
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

#import "XGSValidator.h"

@implementation XGSValidator

- (BOOL)validateFiles:(NSDictionary *)files
{
	//use local variables for readability of the code
	BOOL failureIfAllFilesEmpty		= [self failureIfAllFilesEmpty];
	BOOL failureIfNoFile			= [self failureIfNoFile];
	BOOL failureIfNothing			= [self failureIfNothing];
	BOOL failureIfOneFileEmpty		= [self failureIfOneFileEmpty];
	BOOL failureIfStderrEmpty		= [self failureIfStderrEmpty];
	BOOL failureIfStderrNonEmpty	= [self failureIfStderrNonEmpty];
	BOOL failureIfStdoutEmpty		= [self failureIfStdoutEmpty];
	BOOL failureIfStdoutNonEmpty	= [self failureIfStdoutNonEmpty];
	
	//get stdout and stderr streams
	NSData *stdoutData = [files objectForKey:GEZJobResultsStandardOutputKey];
	NSData *stderrData = [files objectForKey:GEZJobResultsStandardErrorKey];
	BOOL stdoutIsEmpty = ( [stdoutData length] == 0 );
	BOOL stderrIsEmpty = ( [stderrData length] == 0 );
	BOOL theResultsAreGood = YES;

	//remove stdout and stderr from files
	if ( stdoutIsEmpty == NO || stderrIsEmpty == NO ) {
		NSMutableDictionary *temp = [NSMutableDictionary dictionaryWithDictionary:files];
		[temp removeObjectsForKeys:[NSArray arrayWithObjects:GEZJobResultsStandardErrorKey,GEZJobResultsStandardOutputKey,nil]];
		files = [NSDictionary dictionaryWithDictionary:temp];
	}
	
	if ( failureIfNothing && ( [files count] == 0 ) && stdoutIsEmpty && stderrIsEmpty )
		theResultsAreGood = NO;
	else if ( failureIfStdoutEmpty && stdoutIsEmpty )
		theResultsAreGood = NO;
	else if ( failureIfStdoutNonEmpty && ( ! stdoutIsEmpty) )
		theResultsAreGood = NO;
	else if ( failureIfStderrEmpty && stderrIsEmpty )
		theResultsAreGood = NO;
	else if ( failureIfStderrNonEmpty && ( ! stderrIsEmpty) )
		theResultsAreGood = NO;
	else if ( failureIfNoFile || failureIfOneFileEmpty || failureIfAllFilesEmpty ) {
		if ( [files count] == 0 )
			theResultsAreGood = NO;
		else if ( failureIfOneFileEmpty || failureIfAllFilesEmpty ) {
			NSEnumerator *e = [files objectEnumerator];
			int countEmptyFiles=0;
			NSData  *oneFile;
			while ( oneFile = [e nextObject] ) {
				if ( [oneFile length] == 0 )
					countEmptyFiles++;
			}
			if ( failureIfOneFileEmpty && (countEmptyFiles >= 1) )
				theResultsAreGood = NO;
			else if ( failureIfAllFilesEmpty && (countEmptyFiles == [files count] ) )
				theResultsAreGood = NO;
		}
	}
	
	return theResultsAreGood;
	
}

- (BOOL)failureIfAllFilesEmpty
{
	[self willAccessValueForKey:@"failureIfAllFilesEmpty"];
	BOOL failureIfAllFilesEmptyLocal = [[self primitiveValueForKey:@"failureIfAllFilesEmpty"] boolValue];
	[self didAccessValueForKey:@"failureIfAllFilesEmpty"];
	return failureIfAllFilesEmptyLocal;
}

- (BOOL)failureIfNoFile
{
	[self willAccessValueForKey:@"failureIfNoFile"];
	BOOL failureIfNoFileLocal = [[self primitiveValueForKey:@"failureIfNoFile"] boolValue];
	[self didAccessValueForKey:@"failureIfNoFile"];
	return failureIfNoFileLocal;
}

- (BOOL)failureIfNothing
{
	[self willAccessValueForKey:@"failureIfNothing"];
	BOOL failureIfNothingLocal = [[self primitiveValueForKey:@"failureIfNothing"] boolValue];
	[self didAccessValueForKey:@"failureIfNothing"];
	return failureIfNothingLocal;
}

- (BOOL)failureIfOneFileEmpty
{
	[self willAccessValueForKey:@"failureIfOneFileEmpty"];
	BOOL failureIfOneFileEmptyLocal = [[self primitiveValueForKey:@"failureIfOneFileEmpty"] boolValue];
	[self didAccessValueForKey:@"failureIfOneFileEmpty"];
	return failureIfOneFileEmptyLocal;
}

- (BOOL)failureIfStderrEmpty
{
	[self willAccessValueForKey:@"failureIfStderrEmpty"];
	BOOL failureIfStderrEmptyLocal = [[self primitiveValueForKey:@"failureIfStderrEmpty"] boolValue];
	[self didAccessValueForKey:@"failureIfStderrEmpty"];
	return failureIfStderrEmptyLocal;
}

- (BOOL)failureIfStderrNonEmpty
{
	[self willAccessValueForKey:@"failureIfStderrNonEmpty"];
	BOOL failureIfStderrNonEmptyLocal = [[self primitiveValueForKey:@"failureIfStderrNonEmpty"] boolValue];
	[self didAccessValueForKey:@"failureIfStderrNonEmpty"];
	return failureIfStderrNonEmptyLocal;
}

- (BOOL)failureIfStdoutEmpty
{
	[self willAccessValueForKey:@"failureIfStdoutEmpty"];
	BOOL failureIfStdoutEmptyLocal = [[self primitiveValueForKey:@"failureIfStdoutEmpty"] boolValue];
	[self didAccessValueForKey:@"failureIfStdoutEmpty"];
	return failureIfStdoutEmptyLocal;
}

- (BOOL)failureIfStdoutNonEmpty
{
	[self willAccessValueForKey:@"failureIfStdoutNonEmpty"];
	BOOL failureIfStdoutNonEmptyLocal = [[self primitiveValueForKey:@"failureIfStdoutNonEmpty"] boolValue];
	[self didAccessValueForKey:@"failureIfStdoutNonEmpty"];
	return failureIfStdoutNonEmptyLocal;
}
@end
