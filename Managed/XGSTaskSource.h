//
//  XGSTaskSource.h
//  GridStuffer
//
//  Created by Charles Parnot on 5/12/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//



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
/* - (NSData *)metaJob:(XGSMetaJob *)metaJob stdinDataForTask:(id)task; */
- (NSString *)metaJob:(XGSMetaJob *)metaJob stdinStringForTask:(id)task;
- (NSString *)metaJob:(XGSMetaJob *)metaJob stdinPathForTask:(id)task;

- (BOOL)metaJob:(XGSMetaJob *)metaJob validateResultsWithFiles:(NSDictionary *)dictionaryRepresentation standardOutput:(NSData *)stdoutData standardError:(NSData *)stderrData forTask:(id)task;
- (BOOL)metaJob:(XGSMetaJob *)metaJob saveStandardOutput:(NSData *)data forTask:(id)task;
- (BOOL)metaJob:(XGSMetaJob *)metaJob saveStandardError:(NSData *)data forTask:(id)task;
- (BOOL)metaJob:(XGSMetaJob *)metaJob saveOutputFiles:(NSDictionary *)dictionaryRepresentation forTask:(id)task;


@end
