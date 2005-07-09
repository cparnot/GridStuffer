//
//  XGSMetaJob.h
//  GridStuffer
//
//  Created by Charles Parnot on 5/12/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//

/**

An XGSMetaJob object encapsulates an array of tasks that need to be completed.
The MetaJob object takes care of the scheduling and submission of XGJob.
There can be several XGJob for one MetaJob, e.g. when failures occur or
when there are too many tasks.

A MetaJob works hand-in-hand with its data source, that will provide the
description of the tasks, and will take care of saving the results, as they come
back. A MetaJob can also have a delegate.

In GridStuffer, the data source is an instance of XGSTaskSource.
*/



@class XGSJob;
@class XGSGrid;

@interface XGSMetaJob : XGSManagedObject
{
	id delegate;
	NSMutableIndexSet *availableTasks; //keep track of the indexes of the available commands = not running, not done
	NSTimer *submissionTimer;
}

- (id)dataSource;
- (void)setDataSource:(id)newDataSource;
- (id)delegate;
- (void)setDelegate:(id)newDelegate;
- (NSString *)name;
- (void)setName:(NSString *)nameNew;

- (void)start;
- (BOOL)isRunning;
- (void)suspend; //stop submitting more jobs
- (void)deleteFromStore;

//info about the MetaJob
- (NSNumber *)countTotalTasks;
- (NSNumber *)countDoneTasks;
- (NSNumber *)countPendingTasks;
- (NSNumber *)percentDone;
- (NSNumber *)percentPending;
- (NSNumber *)percentCompleted;
- (NSNumber *)percentDismissed;
- (NSNumber *)percentSubmitted;

//info about the individual tasks
- (int)countFailuresForTaskAtIndex:(int)index;
- (int)countSuccessesForTaskAtIndex:(int)index;
- (int)countSubmissionsForTaskAtIndex:(int)index;
- (NSString *)statusStringForTaskAtIndex:(int)index;

//short description, handy for debugging
- (NSString *)shortDescription;

//MetaJob is a delegate of multiple XGSJob
//these are XGSJob delegate methods
- (void)jobDidNotStart:(XGSJob *)aJob;
- (void)jobDidFinish:(XGSJob *)aJob;
- (void)jobDidFail:(XGSJob *)aJob;
- (void)job:(XGSJob *)aJob didLoadResults:(NSDictionary *)results;

@end


/* the methods declared here provide public typed accessors for CoreData properties of XGSMetaJob */
@interface XGSMetaJob (XGSMetaJobAccessors)
- (int)successCountsThreshold;
- (int)failureCountsThreshold;
- (int)maxSubmissionsPerTask;
- (void)setFailureCountsThreshold:(int)failureCountsThresholdNew;
- (void)setMaxSubmissionsPerTask:(int)maxSubmissionsPerTaskNew;
- (void)setSuccessCountsThreshold:(int)successCountsThresholdNew;

@end


// XGSMetaJob data source methods
@interface NSObject (XGSMetaJobDataSource)

- (BOOL)initializeTasksForMetaJob:(XGSMetaJob *)metaJob;
- (unsigned int)numberOfTasksForMetaJob:(XGSMetaJob *)aJob;
- (id)metaJob:(XGSMetaJob *)metaJob taskAtIndex:(unsigned int)taskIndex;

- (NSString *)metaJob:(XGSMetaJob *)metaJob commandStringForTask:(id)task;
- (NSArray *)metaJob:(XGSMetaJob *)metaJob argumentStringsForTask:(id)task;
- (NSArray *)metaJob:(XGSMetaJob *)metaJob pathsToUploadForTask:(id)task;
- (NSData *)metaJob:(XGSMetaJob *)metaJob stdinDataForTask:(id)task;
- (NSString *)metaJob:(XGSMetaJob *)metaJob stdinStringForTask:(id)task;
- (NSString *)metaJob:(XGSMetaJob *)metaJob stdinPathForTask:(id)task;

- (BOOL)metaJob:(XGSMetaJob *)metaJob validateResultsWithFiles:(NSDictionary *)dictionaryRepresentation standardOutput:(NSData *)stdoutData standardError:(NSData *)stderrData forTask:(id)task;
- (BOOL)metaJob:(XGSMetaJob *)metaJob saveStandardOutput:(NSData *)data forTask:(id)task;
- (BOOL)metaJob:(XGSMetaJob *)metaJob saveStandardError:(NSData *)data forTask:(id)task;
- (BOOL)metaJob:(XGSMetaJob *)metaJob saveOutputFiles:(NSDictionary *)dictionaryRepresentation forTask:(id)task;

//- (BOOL)metaJob:(XGSMetaJob *)metaJob saveResults:(NSDictionary *)results forTask:(id)task;

@end


// XGSMetaJob delegate methods
@interface NSObject(XGSMetaJobDelegate)
- (void)metaJobDidStart:(XGSMetaJob *)metaJob;
- (void)metaJobDidSuspend:(XGSMetaJob *)metaJob;
- (void)metaJob:(XGSMetaJob *)metaJob didSubmitTaskAtIndex:(int)index;
- (void)metaJob:(XGSMetaJob *)metaJob didProcessTaskAtIndex:(int)index;
@end
	
/*
// XGSMetaJob delegate methods
@interface NSObject(XGSMetaJobDelegate)
- (void)didStartMetaJob:(XGSMetaJob *)metaJob;
- (void)didFinishMetaJob:(XGSMetaJob *)metaJob;
- (BOOL)metaJob:(XGSMetaJob *)metaJob shouldSubmitTask:(NSDictionary *)info;
- (void)metaJob:(XGSMetaJob *)metaJob didSubmitTask:(NSDictionary *)info identifier:(NSString *)jobID;
- (void)metaJob:(XGSMetaJob *)metaJob didCancelTask:(NSDictionary *)info identifier:(NSString *)jobID;
- (void)metaJob:(XGSMetaJob *)metaJob didFailTask:(NSDictionary *)info identifier:(NSString *)jobID;
- (void)metaJob:(XGSMetaJob *)metaJob didReceiveEmptyResultsForTask:(NSDictionary *)info identifier:(NSString *)jobID;
- (void)metaJob:(XGSMetaJob *)metaJob didFinishTask:(NSDictionary *)info identifier:(NSString *)jobID;
- (void)metaJob:(XGSMetaJob *)metaJob didProcessTask:(NSDictionary *)info success:(BOOL)flag identifier:(NSString *)jobID;
- (void)metaJob:(XGSMetaJob *)metaJob latestSTDOUT:(NSString *)aString forTask:(NSDictionary *)info identifier:(NSString *)jobID;
- (void)metaJob:(XGSMetaJob *)metaJob latestSTDERR:(NSString *)aString forTask:(NSDictionary *)info identifier:(NSString *)jobID;
*/

