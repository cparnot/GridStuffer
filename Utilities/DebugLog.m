//
//  DebugLog.m
//  CLIckXG
//

#import "DebugLog.h"

#ifdef DEBUG

//valid identifiers and verbose level may be set using the user defaults
//if the value for one of the user defaults is nil, just ignore that setting
void DDLog(NSString *identifier, int level, NSString *fmt,...)
{
	//check the verbose level
	id currentVerboseLevel = [[NSUserDefaults standardUserDefaults] valueForKey:@"DebugLogVerboseLevel"];
	if ( currentVerboseLevel != nil && level > [currentVerboseLevel intValue] )
		return;
		
	//now, we can log!
    va_list ap;
    va_start(ap,fmt);
    NSLogv(fmt,ap);
}

#else

//inline void DDLog(NSString *identifier, int level, NSString *fmt,...) {}

#endif
