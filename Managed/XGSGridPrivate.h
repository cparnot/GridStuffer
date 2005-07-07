//
//  XGSGridPrivate.h
//  GridStuffer
//
//  Created by Charles Parnot on 6/21/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//

/*
Header for private methods used internally by XGSGrid and XGSServer
*/

#import "XGSGrid.h"

@interface XGSGrid (XGSGridPrivate)

- (void)setServer:(XGSServer *)newServer;
- (void)setGridID:(NSString *)gridID;
- (void)setName:(NSString *)nameNew;

- (void)awakeFromServerConnection;
- (void)initializeXgridGridObject;
- (void)xgridGridStateDidChange;
- (void)xgridGridNameDidChange;
- (void)xgridGridJobsDidChange;

@end