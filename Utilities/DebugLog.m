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

void DLog(NSString *identifier, int level, NSString *fmt,...)
{
	int currentVerboseLevel = [[[NSUserDefaults standardUserDefaults] valueForKey:@"DebugLogVerboseLevel"] intValue];
	if ( level > currentVerboseLevel )
		return;
	if ( (identifier !=nil) && ([identifiers() indexOfObject:identifier] == NSNotFound) )
		return;
    va_list ap;
    va_start(ap,fmt);
    NSLogv(fmt,ap);
}

#else

inline void DLog(NSString *identifier, int level, NSString *fmt,...) {}

#endif
