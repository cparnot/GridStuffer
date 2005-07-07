//
//  XGSManagedObject.h
//  GridStuffer
//
//  Created by Charles Parnot on 6/23/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*
	Class only used for debugging, when the DEGUG preprocessor macro is defined.
	Several of NSManagedObject methods are overriden to allow logging.
*/


//the value of DEBUG is set in the build settings using the -D flag for gcc
//DEBUG is defined only for the Development Configuration, not Deployment


#ifdef DEBUG

@interface XGSManagedObject : NSManagedObject
{
	
}

@end

#else

#define XGSManagedObject NSManagedObject

#endif
