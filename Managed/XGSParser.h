//
//  XGSParser.h
//  GridStuffer
//
//  Created by Charles Parnot on 5/13/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//



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

}

+ (XGSParser *)sharedParser;
- (NSDictionary *)parsedCommandDictionaryWithCommandString:(NSString *)commandString;

@end
