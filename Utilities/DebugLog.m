//
//  DebugLog.m
//  CLIckXG
//

#import "DebugLog.h"

#ifdef DEBUG

static NSArray *identifierArray = nil;

NSArray *identifiers ()
{
	if ( identifierArray == nil )
		identifierArray = [[[NSUserDefaults standardUserDefaults] objectForKey:@"DebugIdentifiers"] retain];
	return identifierArray;
}

//valid identifiers and verbose level may be set using the user defaults
//if the value for one of the user defaults is nil, just ignore that setting
void DLog(NSString *identifier, int level, NSString *fmt,...)
{
	//check the verbose level
	id currentVerboseLevel = [[NSUserDefaults standardUserDefaults] valueForKey:@"DebugLogVerboseLevel"];
	if ( currentVerboseLevel != nil && level > [currentVerboseLevel intValue] )
		return;
	
	//check the identifer
	NSArray *ids = identifiers();
	if ( (identifier !=nil) && ( ids!=nil ) && ([ids indexOfObject:identifier] == NSNotFound) )
		return;
	
	//now, we can log!
    va_list ap;
    va_start(ap,fmt);
    NSLogv(fmt,ap);
}

#else

inline void DLog(NSString *identifier, int level, NSString *fmt,...) {}

#endif
