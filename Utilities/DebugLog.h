//
//  DebugLog.h
//  CLIckXG
//

/*
	DDLog is equivalent to NSLog
	but is only used and compiled #ifdef DEBUG
 */

//the value of DEBUG is set in the build settings using the -D flag for gcc, in 'Preprocessor Macros', add 'DEBUG'
//DEBUG is defined only for the Development Configuration, not Deployment

#ifdef DEBUG
void DDLog(NSString *identifier, int level, NSString *fmt,...);
#else
inline void DDLog(NSString *identifier, int level, NSString *fmt,...);
#endif
