//
//  XGSParser.h
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
