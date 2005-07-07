//
//  XGSJob.h
//  GridStuffer
//
//  Created by Charles Parnot on 5/23/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//

#import <Cocoa/Cocoa.h>


//keys used in the result dictionary of each task for the stdout and sterr data streams
//other keys are the paths (on the agent) of the new or modified files
extern NSString *XGSJobResultsStandardOutputKey;
extern NSString *XGSJobResultsStandardErrorKey;

typedef enum {
	XGSJobStateUninitialized = 1,
	XGSJobStateSubmitting,
	XGSJobStateInvalid,
	XGSJobStateRunning,
	XGSJobStateFailed,
	XGSJobStateFinished,
	XGSJobStateDeleting,
	XGSJobStateDeleted,
} XGSJobState;


@class XGSGrid;

@interface XGSJob : XGSManagedObject
{
	XGJob *xgridJob;
	id delegate;
	XGActionMonitor *submissionMonitor;
	XGActionMonitor *deletionMonitor;
	XGActionMonitor *streamsMonitor;
	XGActionMonitor *filesMonitor;
	NSDictionary *jobSpecification;
	NSMutableDictionary *results;
	unsigned int countSubmissions;
	unsigned int countDeletionAttempts;
	NSMutableSet *downloads;
	id jobInfo;
	BOOL shouldLoadResultsWhenFinished;
}

//the grid is the one to which the job is submitted
//	- if set before submission, the job will try to use it and will fail to start if the grid is diconnected
//	- if not set, or set to nil, the job will query the ServerList to get a connected grid
//	- after submission and even after the submission succeded or failed, the grid cannot be modified
//	- during submission, the grid may change several times, but will be fixed once the submission has successed or failed
- (XGSGrid *)grid;
- (void)setGrid:(XGSGrid *)newGrid;

//job actions
//the 'submit' method can only be used once on a given job
//the job specification is only cached during submission, and is lost if submission failed (this is because it can be big)
- (void)submitWithJobSpecification:(NSDictionary *)jobSpecification;
- (void)delete;
//- (void)restart;
//- (void)suspend;
//- (void)resume;

//the job can be set to automatically load the results when it is finished (which may be immediately triggered if already finished)
//manual loading of the results with '-loadResults' can be called anytime, even before the job finishes for intermediary results, which will also cancel the automatic download (if not already started)
//the delegate will receive the results asynchronouly when all the task results have been loaded
//you need to wait until the results are loaded before calling '-loadResults' again (or else cancel the load first)
- (void)loadResultsWhenFinished;
- (void)loadResults;
- (BOOL)resultsAreLoading;
- (void)cancelLoadResults;

//jobInfo can be used to store persistent information about the job (can be retrieved or modified even after submission, as opposed to the job specification)
//for persistent storage, the jobInfo object has to follow the NSCoding protocol
- (id)jobInfo;
- (void)setJobInfo:(id)newJobInfo;

//see below, the informal protocol for the delegate
- (id)delegate;
- (void)setDelegate:(id)newDelegate;


//information about submitted job
- (XGJob *)xgridJob;
- (NSString *)name;
- (unsigned int)completedTaskCount;
- (NSString *)statusString;
- (BOOL)isFinished;

@end


//methods that can be implemented by the delegate
@interface NSObject (XGSJobDelegate)
- (void)jobDidStart:(XGSJob *)aJob;
- (void)jobDidNotStart:(XGSJob *)aJob;
- (void)jobDidFinish:(XGSJob *)aJob;
- (void)jobDidFail:(XGSJob *)aJob;
- (void)jobWasDeleted:(XGSJob *)aJob fromGrid:(XGSGrid *)aGrid;
- (void)jobWasNotDeleted:(XGSJob *)aJob;
- (void)jobDidProgress:(XGSJob *)aJob completedTaskCount:(unsigned int)count;
- (void)job:(XGSJob *)aJob didLoadResults:(NSDictionary *)results;
@end