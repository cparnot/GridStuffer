//
//  XGSParser.h
//  GridStuffer
//
//  Created by Charles Parnot on 5/13/05.
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

/*
 Singleton class in charge of parsing a line of the inpput file.
 Returns an NSDictionary

	<key>XGSParserResultsOptionsKey</key>
	<dict>
		<key>flag1</key>
		<array>
			<string>argument 1 for flag 1</string>
			<string>argument 2 for flag 1</string>
		</array>
		 <key>flag1</key>
		 <array>
		 </array>
	</dict>
	<key>XGSParserResultsCommandKey</key>
	<string>/usr/bin/perl</string>
	<key>XGSParserResultsArgumentsKey</key>
	 <array>
		 <string>argument 1</string>
		 <string>argument 2</string>
	 </array>
 
 The parsing assumes that the last flag has only one argument
*/

//Keys used in the parsedCommandDictionary
extern NSString *XGSParserResultsOptionsKey;
extern NSString *XGSParserResultsCommandKey;
extern NSString *XGSParserResultsArgumentsKey;

@interface XGSParser : NSObject
{
	//list of the official xgrid options (to distinguish them from the user-specific options)
	NSArray *gridStufferOptions;
}

+ (XGSParser *)sharedParser;
- (NSDictionary *)parsedCommandDictionaryWithCommandString:(NSString *)commandString;

//the defaults should work fine = { -so, -se, -out, -si, -in, -dirs, -files }
- (void)setGridStufferOptions:(NSArray *)options;

@end
