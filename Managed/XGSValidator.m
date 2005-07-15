//
//  XGSValidator.m
//  GridStuffer
//
//  Created by Charles Parnot on 6/27/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//

/*
 This file is part of GridStuffer.
 GridStuffer is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
 GridStuffer is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with Foobar; if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#import "XGSValidator.h"

@implementation XGSValidator

- (BOOL)validateFiles:(NSDictionary *)files standardOutput:(NSData *)stdoutData standardError:(NSData *)stderrData
{
	BOOL failureIfAllFilesEmpty		= [self failureIfAllFilesEmpty];
	BOOL failureIfNoFile			= [self failureIfNoFile];
	BOOL failureIfNothing			= [self failureIfNothing];
	BOOL failureIfOneFileEmpty		= [self failureIfOneFileEmpty];
	BOOL failureIfStderrEmpty		= [self failureIfStderrEmpty];
	BOOL failureIfStderrNonEmpty	= [self failureIfStderrNonEmpty];
	BOOL failureIfStdoutEmpty		= [self failureIfStdoutEmpty];
	BOOL failureIfStdoutNonEmpty	= [self failureIfStdoutNonEmpty];
	
	BOOL stdoutIsEmpty = ( [stdoutData length] == 0 );
	BOOL stderrIsEmpty = ( [stderrData length] == 0 );
	BOOL theResultsAreGood = YES;
	
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
	BOOL failureIfAllFilesEmptyLocal;
	[self willAccessValueForKey:@"failureIfAllFilesEmpty"];
	failureIfAllFilesEmptyLocal = [[self primitiveValueForKey:@"failureIfAllFilesEmpty"] boolValue];
	[self didAccessValueForKey:@"failureIfAllFilesEmpty"];
	return failureIfAllFilesEmptyLocal;
}

- (BOOL)failureIfNoFile
{
	BOOL failureIfNoFileLocal;
	[self willAccessValueForKey:@"failureIfNoFile"];
	failureIfNoFileLocal = [[self primitiveValueForKey:@"failureIfNoFile"] boolValue];
	[self didAccessValueForKey:@"failureIfNoFile"];
	return failureIfNoFileLocal;
}

- (BOOL)failureIfNothing
{
	BOOL failureIfNothingLocal;
	[self willAccessValueForKey:@"failureIfNothing"];
	failureIfNothingLocal = [[self primitiveValueForKey:@"failureIfNothing"] boolValue];
	[self didAccessValueForKey:@"failureIfNothing"];
	return failureIfNothingLocal;
}

- (BOOL)failureIfOneFileEmpty
{
	BOOL failureIfOneFileEmptyLocal;
	[self willAccessValueForKey:@"failureIfOneFileEmpty"];
	failureIfOneFileEmptyLocal = [[self primitiveValueForKey:@"failureIfOneFileEmpty"] boolValue];
	[self didAccessValueForKey:@"failureIfOneFileEmpty"];
	return failureIfOneFileEmptyLocal;
}

- (BOOL)failureIfStderrEmpty
{
	BOOL failureIfStderrEmptyLocal;
	[self willAccessValueForKey:@"failureIfStderrEmpty"];
	failureIfStderrEmptyLocal = [[self primitiveValueForKey:@"failureIfStderrEmpty"] boolValue];
	[self didAccessValueForKey:@"failureIfStderrEmpty"];
	return failureIfStderrEmptyLocal;
}

- (BOOL)failureIfStderrNonEmpty
{
	BOOL failureIfStderrNonEmptyLocal;
	[self willAccessValueForKey:@"failureIfStderrNonEmpty"];
	failureIfStderrNonEmptyLocal = [[self primitiveValueForKey:@"failureIfStderrNonEmpty"] boolValue];
	[self didAccessValueForKey:@"failureIfStderrNonEmpty"];
	return failureIfStderrNonEmptyLocal;
}

- (BOOL)failureIfStdoutEmpty
{
	BOOL failureIfStdoutEmptyLocal;
	[self willAccessValueForKey:@"failureIfStdoutEmpty"];
	failureIfStdoutEmptyLocal = [[self primitiveValueForKey:@"failureIfStdoutEmpty"] boolValue];
	[self didAccessValueForKey:@"failureIfStdoutEmpty"];
	return failureIfStdoutEmptyLocal;
}

- (BOOL)failureIfStdoutNonEmpty
{
	BOOL failureIfStdoutNonEmptyLocal;
	[self willAccessValueForKey:@"failureIfStdoutNonEmpty"];
	failureIfStdoutNonEmptyLocal = [[self primitiveValueForKey:@"failureIfStdoutNonEmpty"] boolValue];
	[self didAccessValueForKey:@"failureIfStdoutNonEmpty"];
	return failureIfStdoutNonEmptyLocal;
}
@end
