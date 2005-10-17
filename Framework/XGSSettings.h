//
//  XGSSettings.h
//  GridStuffer
//
//  Created by Charles Parnot on 8/14/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

/*
 The XGSSettings class is used to retrieve and set framework-wide or application-wide settings and objects.
 See individual methods for details.
*/

#import <Cocoa/Cocoa.h>


@interface XGSSettings : NSObject
{
	NSManagedObjectModel *managedObjectModel;
	NSManagedObjectContext *managedObjectContext;
}

//the managed object context is used to store objects at the application level; this context is unique for the whole application. In particular, it is used to store XGSServer objects. A persistent store is automatically created too, in the 'Application Support' folder. This path is specific for the running application and will not be the same when the framework is used in two different applications.
+ (NSManagedObjectContext *)sharedManagedObjectContext;

@end
