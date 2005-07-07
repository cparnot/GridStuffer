//
//  XGSGrid.h
//  GridStuffer
//
//  Created by Charles Parnot on 5/26/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//



//Constants to use to subscribe to notifications
APPKIT_EXTERN NSString *XGSGridDidBecomeAvailableNotification;
APPKIT_EXTERN NSString *XGSGridDidBecomeUnavailableNotification;

@class XGSServer;

@interface XGSGrid : XGSManagedObject
{
	XGGrid *xgridGrid;
	NSMutableSet *availableJobs;
}

- (BOOL)isConnected; //not KVO-compliant

- (XGSServer *)server;
- (NSString *)gridID;
- (NSString *)name;

- (XGGrid *)xgridGrid;

@end
