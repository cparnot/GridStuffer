//
//  XGSTaskSource.h
//  GridStuffer
//
//  Created by Charles Parnot on 5/12/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//

/*
 This file is part of GridStuffer.
 GridStuffer is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
 GridStuffer is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with GridStuffer; if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

@class GEZMetaJob;
@class XGSInputInterface;
@class XGSOutputInterface;
@class XGSValidator;

@interface XGSTaskSource : NSManagedObject
{
	NSDictionary *prototypeCommandDictionary;
	NSDictionary *prototypeShortcutDictionary;
}

- (XGSInputInterface *)inputInterface;
- (XGSValidator *)validator;
- (XGSOutputInterface *)outputInterface;


//MetaJob data source methods
- (unsigned int)numberOfTasksForMetaJob:(GEZMetaJob *)aJob;
- (id)metaJob:(GEZMetaJob *)metaJob taskAtIndex:(unsigned int)taskIndex;
- (BOOL)metaJob:(GEZMetaJob *)metaJob validateTaskAtIndex:(int)taskIndex results:(NSDictionary *)results;

@end
