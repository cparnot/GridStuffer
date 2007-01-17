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

//I struggle a bit to get Dlog to be completely gone when DEBUG is not defined, this is the best I could come up with: any occurence of DDLog is replaced by a ';' thanks to the #define 

#define DDLog(...) ;

//the following is what I had hoped would work, but it turns out the arguments are still evaluated
//inline void DDLog(NSString *identifier, int level, NSString *fmt,...);

#endif
