//
//  XGSJob.m
//  GridStuffer
//
//  Created by Charles Parnot on 5/23/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//

/*
 This file is part of GridStuffer.
 GridStuffer is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
 GridStuffer is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with GridStuffer; if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#import "XGSJob.h"
#import "XGSJobPrivate.h"
#import "XGSServerBrowser.h"
#import "XGSServer.h"
#import "XGSGrid.h"

#define XGSJOB_MAX_SUBMISSIONS 3
#define XGSJOB_SUBMISSION_INTERVAL 5
#define XGSJOB_MAX_DELETION_ATTEMPTS 3
#define XGSJOB_DELETION_ATTEMPT_INTERVAL 120


//public global
//keys used in the results dictionary = same as the 'symbolic file path' used by XGFile
NSString *XGSJobResultsStandardOutputKey;
NSString *XGSJobResultsStandardErrorKey;


//private
//use to convert XGSJobState enum into NSStrings - see +(void)initialize
static NSString *StateStrings[XGSJobStateDeleted+1];


@implementation XGSJob

#pragma mark *** Initializations and deallocations ***

+ (void)initialize
{
	//POTENTIAL PROBLEM
	//not guaranteed to be set before use, but they are only use for result retrieval, so unlikely to be a problem
	//using the same as the 'symbolic file path' used by XGFile
	XGSJobResultsStandardOutputKey = XGFileStandardOutputPath;
	XGSJobResultsStandardErrorKey = XGFileStandardErrorPath;
	//initialization of the private array of NSString used to convert from XGSJobState enum
	StateStrings[XGSJobStateUninitialized] = @"Uninitialized";
	StateStrings[XGSJobStateSubmitting] = @"Submitting";
	StateStrings[XGSJobStateInvalid] = @"Invalid";
	StateStrings[XGSJobStateRunning] = @"Running";
	StateStrings[XGSJobStateFailed] = @"Failed";
	StateStrings[XGSJobStateFinished] = @"Finished";
	//StateStrings[XGSJobStateLoading] = @"Loading";
	StateStrings[XGSJobStateDeleting] = @"Deleting";
	StateStrings[XGSJobStateDeleted] = @"Deleted";
	[self setKeys:[NSArray arrayWithObject:@"state"] triggerChangeNotificationsForDependentKey:@"statusString"];
}

- (NSString *)shortDescription
{
	return [NSString stringWithFormat:@"Job %@ = '%@'", [self primitiveValueForKey:@"jobID"], [self primitiveValueForKey:@"name"]];
}

//private method called by self or XGSGrid
//it may be called several times because of the way the Xgrid framework and GridStuffer behave,
//but the initializations done here will be run only once
- (void)awakeFromServerConnection
{
	XGSJobState state;
	
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	
	state = [self state];
	
	//better to ignore this call if no submission yet or if in the submission process
	if ( state == XGSJobStateUninitialized || state == XGSJobStateSubmitting)
		return;
	
	//all we want to do here is initialize the wrapped XGJob object, in particular to monitor it with KVO
	if ( xgridJob == nil )
		[self initializeXgridJobObject];
}

- (void)awakeFromFetch
{
	[super awakeFromFetch];
	countSubmissions = 0;
	countDeletionAttempts = 0;
	shouldLoadResultsWhenFinished = NO;
	
	//if state = submitting, it means the object was left in an undefined state (submitting) and we did not get the jobID
	if ( [self state] == XGSJobStateSubmitting )
		[self setState:XGSJobStateDeleting];
	
	//this will try to initialize the xgrid object
	[self awakeFromServerConnection];
	
	//start the deletion process if needed
	if ( [self state] == XGSJobStateDeleting )
		[self delete];
}

//very thorough clean-up
- (void)dealloc
{
	[self setDelegate:nil];
	[self cancelLoadResults];
	[submissionMonitor removeObserver:self forKeyPath:@"outcome"];
	[deletionMonitor removeObserver:self forKeyPath:@"outcome"];
	[submissionMonitor release];
	[deletionMonitor release];
	[jobSpecification release];
	submissionMonitor = nil;
	deletionMonitor = nil;
	jobSpecification = nil;
	[xgridJob removeObserver:self forKeyPath:@"state"];
	[xgridJob removeObserver:self forKeyPath:@"completedTaskCount"];
	[xgridJob release];
	xgridJob = nil;
	[super dealloc];
}


#pragma mark *** Private accessors ***

- (XGSJobState)state
{
	XGSJobState result;
	[self willAccessValueForKey:@"state"];
	result = [[self primitiveValueForKey:@"state"] intValue];
	[self didAccessValueForKey:@"state"];
	return result;
}

- (void)setState:(XGSJobState)newState
{
	[self willChangeValueForKey:@"state"];
	[self setPrimitiveValue:[NSNumber numberWithInt:newState] forKey:@"state"];
	[self didChangeValueForKey:@"state"];
}

- (NSString *)jobID
{
	NSString *jobIDLocal;
	[self willAccessValueForKey:@"jobID"];
	jobIDLocal = [self primitiveValueForKey:@"jobID"];
	[self didAccessValueForKey:@"jobID"];
	return jobIDLocal;
}

- (void)setJobID:(NSString *)jobIDNew
{
	[self willChangeValueForKey:@"jobID"];
	[self setPrimitiveValue:jobIDNew forKey:@"jobID"];
	[self didChangeValueForKey:@"jobID"];
}

#pragma mark *** Public accessors ***

- (XGSGrid *)grid
{
	XGSGrid *grid;
	[self willAccessValueForKey:@"grid"];
	grid = [self primitiveValueForKey:@"grid"];
	[self didAccessValueForKey:@"grid"];
	return grid;
}

- (void)setGrid:(XGSGrid *)newGrid
{
	if ( [self state]!=XGSJobStateUninitialized && [self state]!=XGSJobStateSubmitting )
		return;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self willChangeValueForKey:@"grid"];
	[self setPrimitiveValue:newGrid forKey:@"grid"];
	[self didChangeValueForKey:@"grid"];
	if ( newGrid!=nil ) {
		if ( [newGrid isConnected] )
			[self awakeFromServerConnection];
		else
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gridDidBecomeAvailableNotification:) name:XGSGridDidBecomeAvailableNotification object:newGrid];
	}
}

- (id)jobInfo
{
	NSData *jobInfoData;
	NSValueTransformer *transformer;
	[self willAccessValueForKey:@"jobInfo"];
	if ( jobInfo == nil) {
		jobInfoData = [self valueForKey:@"jobInfoData"];
		transformer = [NSValueTransformer valueTransformerForName:NSUnarchiveFromDataTransformerName];
		jobInfo = [transformer transformedValue:jobInfoData];
		if ( jobInfo == nil )
			jobInfo = [NSData data];
	}
	[self didAccessValueForKey:@"jobInfo"];
	return jobInfo;
}
- (void)setJobInfo:(id)newJobInfo
{
	NSData *jobInfoData;
	NSValueTransformer *transformer;
	
	//change the ivar jobInfo
	if ( jobInfo == newJobInfo )
		return;
	[self willChangeValueForKey:@"jobInfo"];
	[newJobInfo retain];
	[jobInfo release];
	jobInfo = newJobInfo;
	[self didChangeValueForKey:@"jobInfo"];
	
	//update the value of jobInfoData
	transformer = [NSValueTransformer valueTransformerForName:NSUnarchiveFromDataTransformerName];
	jobInfoData = [transformer reverseTransformedValue:jobInfo];
	[self setValue:jobInfoData forKey:@"jobInfoData"];
}

- (id)delegate
{
	return delegate;
}

- (void)setDelegate:(id)newDelegate
{
	delegate = newDelegate;
}

- (XGJob *)xgridJob
{
	if ( xgridJob==nil )
		[self initializeXgridJobObject];
	return xgridJob;
}

- (NSString *)name
{
	NSString *name;
	[self willAccessValueForKey:@"name"];
	name = [self primitiveValueForKey:@"name"];
	[self didAccessValueForKey:@"name"];
	return name;
}

- (unsigned int)completedTaskCount
{
	return [[self xgridJob] completedTaskCount];
}

- (NSString *)statusString
{
	return StateStrings[[self state]];
}

- (BOOL)isFinished
{
	return ( [self state] == XGSJobStateFinished );
}


#pragma mark *** submission ***

//private - should ONLY be called by 'submitWithTimer:'
- (BOOL)submit
{
	XGSGrid *grid;
	XGSServer *server;

	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);

	//increment the submission count (even if no job can actually be submitted because of connection failure)
	countSubmissions++;	
	
	//define the grid and the server (if not defined yet, use a default grid)
	grid = [self grid];
	if ( grid ==nil ) {
		server = [[XGSServerBrowser sharedServerListForContext:[self managedObjectContext]] firstConnectedServer];
		grid = [server defaultGrid];
		[self setGrid:grid];
	}

	//if connection problem, give up
	if ( grid==nil || [grid isConnected]==NO )
		return NO;
	
	//set up the submissionMonitor - nothing will happen until the monitor outcome changes
	server = [grid server];
	submissionMonitor = [[server xgridController] performSubmitJobActionWithJobSpecification:jobSpecification gridIdentifier:[grid gridID]];
	[submissionMonitor retain];
	[submissionMonitor addObserver:self forKeyPath:@"outcome" options:NSKeyValueObservingOptionNew context:NULL];
	return YES;
}

//this method really starts the submission process after everything has been set up:
//	- first call with argument 'nil' --> starts the process
//  - call 'submit' if not yet MAX_SUBMISSIONS, otherwise stop the whole process
//	- if 'submit' returns NO, try again later by calling itself with a timer
//	- will also be called if the submissionMonitor fails
- (void)submitWithTimer:(NSTimer *)aTimer
{

	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);

	//that should not happen, but just in case
	if ( submissionMonitor!=nil )
		return;
	
	//if the number of submissions = max allowed, give up
	if ( countSubmissions >= XGSJOB_MAX_SUBMISSIONS ) {
		[self setState:XGSJobStateInvalid];
		[jobSpecification release];
		jobSpecification = nil;
		if ( [delegate respondsToSelector:@selector(jobDidNotStart:)] )
			[delegate jobDidNotStart:self];
		return;
	}
	
	//if 'submit' returns NO, try again later
	if ( [self submit] == NO )
		[NSTimer scheduledTimerWithTimeInterval:XGSJOB_SUBMISSION_INTERVAL target:self selector:@selector(submitWithTimer:) userInfo:nil repeats:NO];
}

//this is the public method that starts the submission process:
//	- the state goes from Uninitiallized to Connecting
//	- XGSJob will try to submit several times (max = XGSJOB_MAX_SUBMISSIONS)
//	- between each submission, there is an interval XGSJOB_SUBMISSION_INTERVAL
//	- while state == Connection, the job can still be in one of these 2 'substates':
//		- waiting for an XGActionMonitor outcome
//		- waiting for a timer to fire and try another submission (it could not even connect to the server or the action monitor failed)
//In any case, the delegate will be notified asynchronously that 'jobDidStart' or 'jobDidNotStart'
- (void)submitWithJobSpecification:(NSDictionary *)specification
{
	NSString *name;

	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);

	//return if current state is anything other than Uninitialized
	if ( [self state]!=XGSJobStateUninitialized )
		return;
	
	//set up the job to be ready to respond to 'submit'
	[self setState:XGSJobStateSubmitting];
	jobSpecification = [specification retain];
	
	//get the name of the job from the specification
	name = [jobSpecification objectForKey:XGJobSpecificationNameKey];
	if ( name == nil )
		name = @"Unnamed Job";
	[self setValue:name forKey:@"name"];

	//now, start the submission process
	[self submitWithTimer:nil];
}

/*
- (void)restart
{
	XGActionMonitor *monitor;
	if ( submissionMonitor != nil || deletionMonitor != nil )
		return;
	monitor = [[self xgridJob] performRestartAction];
}

- (void)suspend
{
	XGActionMonitor *monitor;
	if ( submissionMonitor != nil || deletionMonitor != nil )
		return;
	monitor = [[self xgridJob] performSuspendAction];
}

- (void)resume
{
	XGActionMonitor *monitor;
	if ( submissionMonitor != nil || deletionMonitor != nil )
		return;
	monitor = [[self xgridJob] performResumeAction];
}
*/


#pragma mark *** deletion ***

/*
Deletion is a bit tricky if one wants to be careful. The XGJob could be deleted from
another application. So, even if it was not delted yet, it could be already gone.
Conversely, if there is a connection problem or if the local information is not in
sync with the controller, the XGJob may not be availableAlso, it may seem that it is not there,
when in fact, it is. This is particularly a problem when an XGGrid just comes to life.
The 'jobs' method returns an empty array and then is initialized several times before the 'final'
jobs array is correct.
So the bottom line:
 * do not assume a XGJob is already deleted until a reasonable number of attempts have been done
 * at some point, give up if connection was not possible or the XGJob never showed up
*/

//private method
- (void)deleteFromStore
{
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	[[self managedObjectContext] deleteObject:self];
}

- (void)deleteLater
{
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	[NSTimer scheduledTimerWithTimeInterval:XGSJOB_DELETION_ATTEMPT_INTERVAL target:self selector:@selector(deleteWithTimer:) userInfo:nil repeats:NO];
}

//private method
- (void)deleteWithTimer:(NSTimer *)aTimer
{
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	[self delete];
}

//public method
- (void)delete
{
	XGJob *myJob;

	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);

	//if the XGJob is already deleted from the server, then just delete from the store now
	if ( [self state] == XGSJobStateDeleted || [self grid] == nil || [[self jobID] intValue] < 0 ) {
		[self deleteFromStore];
		return;
	}
	
	//mark the job for deletion in case it still needs to be done later
	[self setState:XGSJobStateDeleting];

	//if pending submission or deletion, do not delete now
	if ( submissionMonitor != nil || deletionMonitor != nil )
		return;
	
	//if the XGJob is available, start the deletion process
	if ( myJob = [self xgridJob] ) {
		//delete from server, it will be deleted from the store when the action monitor returns
		[self cancelLoadResults];
		deletionMonitor = [myJob performDeleteAction];
		[deletionMonitor retain];
		[deletionMonitor addObserver:self forKeyPath:@"outcome" options:NSKeyValueObservingOptionNew context:NULL];
		return;
	}
		 
	//if disconnected, we have to do it later, when the grid is finally available
	if ( [[self grid] isConnected] == NO ) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gridDidBecomeAvailableNotification:) name:XGSGridDidBecomeAvailableNotification object:[self grid]];
		return;
	} else {
		//the grid is loaded, and the job is not showing there...
		//the job might have been deleted externally or might not be showing up yet
		//so we give the grid 3 chances to load it each time the program is run and the job loaded from persistent store
		//try deleting again later if not already max allowed
		countDeletionAttempts++;
		if ( countDeletionAttempts > XGSJOB_MAX_DELETION_ATTEMPTS ) {
			[self setState:XGSJobStateDeleted];
			[self deleteFromStore];
		} else
			[self deleteLater];
	}

}

- (void)gridDidBecomeAvailableNotification:(NSNotification *)notification
{
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	if ( [self state] == XGSJobStateDeleting )
		[self delete];
}

#pragma mark *** getting the results ***

/* 
The results can be loaded manually at any time, even if the job is not finished.
Result loading can also be triggered automatically when it becomes available and is finished
*/

- (void)loadResultsWhenFinished
{
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	shouldLoadResultsWhenFinished = YES;
	if ( [self state] == XGSJobStateFinished && [self xgridJob] != nil )
		[self loadResults];
}

- (void)loadResults
{
	XGJob *theJob;
	BOOL goForIt;

	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);

	//will not load the results if not running, not finished or if previous result retrieval not finished
	goForIt = ( ( [self state]== XGSJobStateFinished || [self state]!= XGSJobStateRunning ) && [self resultsAreLoading] == NO );
	if ( goForIt == NO )
		return;

	//get the XGJob, if accessible
	theJob= [self xgridJob];
	if ( theJob==nil )
		return;
	
	//cancel automatic load
	shouldLoadResultsWhenFinished = NO;
	
	//prepare the result dictionary that will hold the results
	[results release];
	results = [[NSMutableDictionary alloc] initWithCapacity:[theJob taskCount]];
	
	//prepare the downloads mutable set that will hold the pending XGFileDownload
	[downloads release];
	downloads = [[NSMutableSet alloc] init];
	
	//start the result retrieval process
	streamsMonitor = [[theJob performGetOutputStreamsAction] retain];
	filesMonitor   = [[theJob performGetOutputFilesAction]   retain];
	[streamsMonitor addObserver:self forKeyPath:@"outcome" options:NSKeyValueObservingOptionNew context:NULL];
	[filesMonitor   addObserver:self forKeyPath:@"outcome" options:NSKeyValueObservingOptionNew context:NULL];
	
}

- (void)cancelLoadResults
{
	NSEnumerator *e;
	XGFileDownload *aFileDownload;

	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);

	//stop the action monitors
	[streamsMonitor removeObserver:self forKeyPath:@"outcome"];
	[streamsMonitor release];
	streamsMonitor = nil;
	[filesMonitor removeObserver:self forKeyPath:@"outcome"];
	[filesMonitor release];
	filesMonitor = nil;	
	
	//stop the file downloads
	e = [downloads objectEnumerator];
	while ( aFileDownload = [e nextObject] )
		[aFileDownload cancel];
	[downloads release];
	downloads = nil;
	
	//empty the results
	[results release];
	results = nil;
}


- (BOOL)resultsAreLoading
{
	return ( streamsMonitor!=nil || filesMonitor!=nil || results!=nil );
}

#pragma mark *** watching the XGJob wrapped object ***


//the XGJob object is set only once during the lifetime of self
//this is also where the KVO is set
- (void)initializeXgridJobObject
{
	NSString *jobID;
	
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);

	if ( xgridJob !=nil )
		return;
	
	//first try to get the job using its jobID
	jobID = [self valueForKey:@"jobID"];
	xgridJob = [[[self grid] xgridGrid] jobForIdentifier:jobID];
	
	if ( xgridJob != nil ) {
		[xgridJob retain];
		[self xgridJobStateDidChange];
		[self xgridJobCompletedTaskCountDidChange];
		[xgridJob addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionOld context:NULL];
		[xgridJob addObserver:self forKeyPath:@"completedTaskCount" options:NSKeyValueObservingOptionOld context:NULL];
		if ( [self state] == XGSJobStateDeleting )
			[self delete];
		if ( shouldLoadResultsWhenFinished )
			[self loadResultsWhenFinished];
		DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] (job '%@') : created XGJob %@ ",[self class],self,_cmd,[self name],xgridJob);
	}
}

/*
- (void)syncStateWithXgridJob
{
	[self setState:[[self xgridJob] state]];
}
*/

/* 
//convenience method to check changes in job status while it is running
- (void)checkEndJob
{
	XGResourceState currentState;
	currentState = [[self xgridJob] state];
	
	//is it finished?? --> if yes, start loading the results
	if ( currentState==XGResourceStateFinished && [delegate respondsToSelector:@selector(jobDidFinish:)] ) {
		[self syncStateWithXgridJob];
		[delegate jobDidFinish:self];
		[self loadResults];
	}
	
	//did it fail??
	if ( currentState==XGResourceStateFailed && [delegate respondsToSelector:@selector(jobDidFail:)] ) {
		[self syncStateWithXgridJob];
		[delegate jobDidFail:self];
	}
}
*/

//private method used to handle outcome of streamsMonitor and filesMonitor
//results = dictionary of dictionaries, one dictionary per taskIdentifier
- (void)downloadFiles:(NSArray *)files
{
	XGFile *aFile;
	XGFileDownload *aFileDownload;
	NSString *taskIdentifier;
	NSMutableDictionary *resultDictionary;
	NSMutableData *fileData;
	NSEnumerator *e;

	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	DLog(NSStringFromClass([self class]),10,@"\nFiles:\n%@",[files description]);

	e = [files objectEnumerator];
	while ( aFile = [e nextObject] ) {
		
		//the taskIdentifier is the key to a resultDictionary
		taskIdentifier = [aFile taskIdentifier];
		
		//retrieve the resultDictionary from the results dictionary, creating it if necessary
		resultDictionary = [results objectForKey:taskIdentifier];
		if ( resultDictionary == nil ) {
			resultDictionary = [[NSMutableDictionary alloc] init];
			[results setObject:resultDictionary forKey:taskIdentifier];
		}
		
		//create the data object that will hold the data
		fileData = [NSMutableData data];
		[resultDictionary setObject:fileData forKey:[aFile path]];
		
		//start the download
		aFileDownload = [[XGFileDownload alloc] initWithFile:aFile delegate:self];
		[downloads addObject:aFileDownload];
		[aFileDownload release];
		
	}
}

- (void)xgridJobStateDidChange
{
	//XGResourceState oldState,newState;
	XGResourceState currentXgridState;
	
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);

	//get the XGJob state
	currentXgridState = [[self xgridJob] state];	
	
	/*** MAYBE DO SOMETHING IF IT BECAME UNAVAILABLE ***/
	
	//if the job is running, check if it is finished
	if ( [self state] == XGSJobStateRunning ) {
		
		//is it finished?? --> if yes, start loading the results
		if ( currentXgridState == XGResourceStateFinished ) {
			[self setState:XGSJobStateFinished];
			if ( [delegate respondsToSelector:@selector(jobDidFinish:)] )
				[delegate jobDidFinish:self];
			if ( shouldLoadResultsWhenFinished )
				[self loadResultsWhenFinished];
		}
		
		//did it fail??
		if ( currentXgridState == XGResourceStateFailed ) {
			[self setState:XGSJobStateFailed];
			if ( [delegate respondsToSelector:@selector(jobDidFail:)] )
				[delegate jobDidFail:self];
		}
	}
	
	
}

- (void)xgridJobCompletedTaskCountDidChange
{
	DLog(NSStringFromClass([self class]),12,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	if ( [delegate respondsToSelector:@selector(jobWasNotDeleted:)] )
		[delegate jobWasNotDeleted:self];
}

//KVO for:
//	- the wrapped XGJob object
//	- the XGActionMonitor for submission
//	- the XGActionMonitor for deletion

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	NSString *jobID;
	XGActionMonitorOutcome outcome;
	
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@\nObject = <%@:%p>\nKey Path = %@\nChange = %@",[self class],self,_cmd, [self shortDescription], [object class], object, keyPath, [change description]);

	if ( object == xgridJob ) {
		DLog(NSStringFromClass([self class]),10,@"Object = XGJob");
		if ( [keyPath isEqualToString:@"state"] )
			[self xgridJobStateDidChange];
		else if ( [keyPath isEqualToString:@"completedTaskCount"] )
			[self xgridJobCompletedTaskCountDidChange];
	}
	
	else if ( object == submissionMonitor ) {
		DLog(NSStringFromClass([self class]),10,@"Object = Submission Monitor");
		outcome = [submissionMonitor outcome];
		if ( outcome == XGActionMonitorOutcomeSuccess) {
			jobID = [[submissionMonitor results] objectForKey:@"jobIdentifier"];
			[self setValue:jobID forKey:@"jobID"];
			[jobSpecification release];
			jobSpecification = nil;
			[self setState:XGSJobStateRunning];
			if ( [delegate respondsToSelector:@selector(jobDidStart:)] )
				[delegate jobDidStart:self];
			[self xgridJobStateDidChange];
		}
		[submissionMonitor removeObserver:self forKeyPath:@"outcome"];
		[submissionMonitor release];
		submissionMonitor = nil;
		if ( outcome != XGActionMonitorOutcomeSuccess )
			[NSTimer scheduledTimerWithTimeInterval:XGSJOB_SUBMISSION_INTERVAL target:self selector:@selector(submitWithTimer:) userInfo:nil repeats:NO];
		return;
	}

	else if ( object == deletionMonitor ) {
		DLog(NSStringFromClass([self class]),10,@"Object = Deletion Monitor");
		XGActionMonitorOutcome outcome = [deletionMonitor outcome];
		[deletionMonitor removeObserver:self forKeyPath:@"outcome"];
		[deletionMonitor release];
		deletionMonitor = nil;
		if ( outcome == XGActionMonitorOutcomeSuccess) {
			[self setState:XGSJobStateDeleted];
			[xgridJob removeObserver:self forKeyPath:@"state"];
			[xgridJob removeObserver:self forKeyPath:@"completedTaskCount"];
			[xgridJob release];
			xgridJob = nil;
			[self setGrid:nil];
			if ( [delegate respondsToSelector:@selector(jobWasDeleted:fromGrid:)] )
				[delegate jobWasDeleted:self fromGrid:[self grid]];
			[self setValue:@"-1" forKey:@"jobID"];
			[self deleteFromStore];
		} else
			[self deleteLater];
		return;
	}
	
	else if ( object==streamsMonitor && [keyPath isEqualToString:@"outcome"]==YES ) {
		DLog(NSStringFromClass([self class]),10,@"Object = Streams Monitor");
		[self downloadFiles:[[streamsMonitor results] objectForKey:XGActionMonitorResultsOutputStreamsKey]];
		[streamsMonitor removeObserver:self forKeyPath:@"outcome"];
		[streamsMonitor release];
		streamsMonitor = nil;
		[self checkDidLoadResults];
	}

	else if ( object==filesMonitor && [keyPath isEqualToString:@"outcome"]==YES ) {
		DLog(NSStringFromClass([self class]),10,@"Object = Files Monitor");
		[self downloadFiles:[[filesMonitor results] objectForKey:XGActionMonitorResultsOutputFilesKey]];
		[filesMonitor removeObserver:self forKeyPath:@"outcome"];
		[filesMonitor release];
		filesMonitor = nil;
		[self checkDidLoadResults];
	}

}


#pragma mark *** Handling XGFileDownload delegate methods ***

- (BOOL)resultsDidLoad
{
	if ( results == nil )
		return NO;
	if ( [downloads count]==0 && streamsMonitor==nil && filesMonitor==nil )
		return YES;
	else
		return NO;
}

//this methods checks if the results are all loaded and ready
- (void)checkDidLoadResults
{
	if ( [self resultsDidLoad] && [delegate respondsToSelector:@selector(job:didLoadResults:)] ) {
		[delegate job:self didLoadResults:results];
		[results autorelease];
		results = nil;
		[downloads release];
		downloads = nil;
	}
}

/*
- (void)fileDownloadDidBegin:(XGFileDownload *)fileDownload
{
	
}
*/

//This method is called when the download has loaded data
- (void)fileDownload:(XGFileDownload *)fileDownload didReceiveData:(NSData *)data
{
	NSString *taskIdentifier;
	NSDictionary *resultDictionary;
	NSMutableData *fileData;

	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	taskIdentifier = [[fileDownload file] taskIdentifier];
	resultDictionary =  [results objectForKey:taskIdentifier];
	fileData = [resultDictionary objectForKey:[[fileDownload file] path]];
	[fileData appendData:data];
}

//This method is called when the download has failed
- (void)fileDownload:(XGFileDownload *)fileDownload didFailWithError:(NSError *)error
{
	NSString *taskIdentifier;
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	taskIdentifier = [[fileDownload file] taskIdentifier];
	[[results objectForKey:taskIdentifier] removeObjectForKey:[[fileDownload file] path]];
	//[fileDownload cancel];
	[downloads removeObject:fileDownload];
	[self checkDidLoadResults];
}

//This method is called when the download has finished downloading
- (void)fileDownloadDidFinish:(XGFileDownload *)fileDownload
{
	//[fileDownload cancel];
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	[downloads removeObject:fileDownload];
	[self checkDidLoadResults];
}

@end
