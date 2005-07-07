//
//  XGSJobPrivate.h
//  GridStuffer
//
//  Created by Charles Parnot on 6/22/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//

/*
 Header for private methods used internally by XGSJob and XGSGrid
 */

#import "XGSJob.h"

@interface XGSJob (XGSJobPrivate)

- (void)awakeFromServerConnection;

- (XGSJobState)state;
- (void)setState:(XGSJobState)newState;
- (void)checkDidLoadResults;

- (void)initializeXgridJobObject;
- (void)syncStateWithXgridJob;
- (void)xgridJobStateDidChange;
- (void)xgridJobCompletedTaskCountDidChange;

@end
