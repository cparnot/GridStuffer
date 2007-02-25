//
//  XGSCategories.m
//  GridStuffer
//
//  Created by Charles Parnot on 5/13/05.
//  Copyright 2005, 2006, 2007 Charles Parnot. All rights reserved.
//

/*
 This file is part of GridStuffer.
 GridStuffer is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
 GridStuffer is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with GridStuffer; if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#import "XGSCategories.h"


@implementation NSScanner (XGS_ScannerCategory)

- (unichar)XGS_scanNextCharacter;
{
	unsigned int location;
	unichar nextCharacter;
	
	if ([self isAtEnd])
		return 0;
	else {
		location=[self scanLocation];
		nextCharacter=[[self string] characterAtIndex:location];
		[self setScanLocation:location+1];
		return nextCharacter;
	}
}

@end

#ifdef DEBUG
#define MAXNUMBEROFBYTES 16
#define NUMBEROFBYTEPERGROUP 4

@implementation NSData(CLICKNSDataCategory)

//returns a description that corresponds only to the first MAXNUMBEROFBYTES bytes at most
- (NSString *)description
{
	NSMutableString *dataString;
	int i,n;
	char *bytes;
	unsigned long *l;
	char lc[4];
	
	lc[0]=0;
	lc[1]=0;
	lc[2]=0;
	lc[3]=0;
	l=(unsigned long *)lc;
	
	n=[self length];
	bytes=(char *)[self bytes];
	dataString=[NSMutableString string];
	[dataString appendString:@"<"];
	for (i=0; (i<n) && (i<MAXNUMBEROFBYTES);i++) {
		if (i%NUMBEROFBYTEPERGROUP==0)
			[dataString appendString:@" "];
		lc[3]=*bytes;
		[dataString appendFormat:@"%02x",*l];
		bytes++;
	}
	if (n>MAXNUMBEROFBYTES)
		[dataString appendFormat:@"... > (%d bytes)",n];
	else
		[dataString appendString:@" >"];
	
	return [NSString stringWithString:dataString];
}

@end

#undef MAXNUMBEROFBYTES
#undef NUMBEROFBYTEPERGROUP
#endif DEBUG
