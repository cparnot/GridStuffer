//
//  XGSFrameworkSettings.h
//  GridStuffer
//
//  Created by Charles Parnot on 8/14/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

/*
 The XGSFrameworkGlobals class is used to retrieve and set framework-wide or application-wide settings and objects.
*/

#import <Cocoa/Cocoa.h>


@interface XGSFrameworkSettings : NSObject
{
	NSManagedObjectModel *managedObjectModel;
	NSManagedObjectContext *managedObjectContext;
}

//the managed object context is used to store servers; it is unique for the application
+ (NSManagedObjectContext *)sharedManagedObjectContext;

@end
