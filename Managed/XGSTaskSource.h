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
 You should have received a copy of the GNU General Public License along with Foobar; if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

@class XGSMetaJob;
@class XGSInputInterface;
@class XGSOutputInterface;

@interface XGSTaskSource : XGSManagedObject
{
	NSDictionary *prototypeCommandDictionary;
	NSDictionary *prototypeShortcutDictionary;
}

- (XGSInputInterface *)inputInterface;
- (XGSOutputInterface *)outputInterface;


//MetaJob data source methods
/* - (BOOL)initializeTasksForMetaJob:(XGSMetaJob *)metaJob; */
- (unsigned int)numberOfTasksForMetaJob:(XGSMetaJob *)aJob;
- (id)metaJob:(XGSMetaJob *)metaJob taskAtIndex:(unsigned int)taskIndex;

- (NSString *)metaJob:(XGSMetaJob *)metaJob commandStringForTask:(id)task;
- (NSArray *)metaJob:(XGSMetaJob *)metaJob argumentStringsForTask:(id)task;
- (NSArray *)metaJob:(XGSMetaJob *)metaJob pathsToUploadForTask:(id)task;
- (NSString *)metaJob:(XGSMetaJob *)metaJob stdinPathForTask:(id)task;

- (BOOL)metaJob:(XGSMetaJob *)metaJob validateResultsWithFiles:(NSDictionary *)dictionaryRepresentation standardOutput:(NSData *)stdoutData standardError:(NSData *)stderrData forTask:(id)task;
- (BOOL)metaJob:(XGSMetaJob *)metaJob saveStandardOutput:(NSData *)data forTask:(id)task;
- (BOOL)metaJob:(XGSMetaJob *)metaJob saveStandardError:(NSData *)data forTask:(id)task;
- (BOOL)metaJob:(XGSMetaJob *)metaJob saveOutputFiles:(NSDictionary *)dictionaryRepresentation forTask:(id)task;


@end
