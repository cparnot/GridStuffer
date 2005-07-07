//
//  XGSToolbarController.h
//  GridStuffer
//
//  Created by Charles Parnot on 7/3/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface XGSToolbarController : NSObject
{
	NSString *toolbarDescriptionFile;
	NSToolbar *toolbar;
}

- (id)initWithToolbarDescriptionFile:(NSString *)plistFileNameInBundle;
- (NSToolbar *)toolbar;

@end
