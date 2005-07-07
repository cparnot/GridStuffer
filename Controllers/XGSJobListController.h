//
//  XGSJobListController.h
//  GridStuffer
//
//  Created by Charles Parnot on 7/5/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface XGSJobListController : NSWindowController
{
    NSManagedObjectContext *managedObjectContext;
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context;


@end
