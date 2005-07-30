//
//  XGSGridPrivate.h
//  GridStuffer
//
//  Created by Charles Parnot on 6/21/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//

/*
 This file is part of GridStuffer.
 GridStuffer is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
 GridStuffer is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with GridStuffer; if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

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