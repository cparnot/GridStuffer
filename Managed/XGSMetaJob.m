//
//  XGSMetaJob.m
//  GridStuffer
//
//  Created by Charles Parnot on 5/12/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//

#import "XGSMetaJob.h"
#import "XGSMetaJobPrivateAccessors.h"
#import "XGSServer.h"
#import "XGSJob.h"
#import "XGSIntegerArray.h";
#import "XGSOutputInterface.h"

@class XGSTaskSource;

@implementation XGSMetaJob

#pragma mark *** Initializations ***

- (NSString *)shortDescription
{
	return [NSString stringWithFormat:@"MetaJob '%@'",[self primitiveValueForKey:@"name"]];
	//return [NSString stringWithFormat:@"MetaJob '%@' (%d MetaTasks)",[self name],[self countTotalTasks]];
}

//we need to register to keep track of percentDone etc... in jobs
+ (void)initialize
{
	NSArray *keys;
	if ( self == [XGSMetaJob class] ) {
		keys=[NSArray arrayWithObjects:@"countCompletedTasks",@"countDismissedTasks",nil];
		[self setKeys:keys triggerChangeNotificationsForDependentKey:@"countDone"];
		[self setKeys:keys triggerChangeNotificationsForDependentKey:@"percentDone"];
		[self setKeys:keys triggerChangeNotificationsForDependentKey:@"countPending"];
		[self setKeys:keys triggerChangeNotificationsForDependentKey:@"percentPending"];
		keys=[NSArray arrayWithObjects:@"countDismissedTasks",nil];
		[self setKeys:keys triggerChangeNotificationsForDependentKey:@"percentDismissed"];
		keys=[NSArray arrayWithObjects:@"countCompletedTasks",nil];
		[self setKeys:keys triggerChangeNotificationsForDependentKey:@"percentCompleted"];
		keys=[NSArray arrayWithObjects:@"countSubmittedTasks",nil];
		[self setKeys:keys triggerChangeNotificationsForDependentKey:@"percentSubmitted"];
	}
}

- (void)awakeFromFetch
{
	[super awakeFromFetch];
	
	availableTasks = [[NSMutableIndexSet alloc] init];
	if ( [self isRunning] ) {
		[self suspend];
		[self start];
	}
	//[self resetavailableTasks];
}

- (void)dealloc
{
	[submissionTimer invalidate];
	submissionTimer = nil;
	delegate = nil;
	[availableTasks release];
	[super dealloc];
}


#pragma mark *** accessors ***

- (id)dataSource
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
    [self willAccessValueForKey:@"dataSource"];
    id dataSource = [self primitiveValueForKey:@"dataSource"];
    [self didAccessValueForKey:@"dataSource"];
    return dataSource;
}

- (void)setDataSource:(id)newDataSource
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	
	//is the data source even responding to the appropriate messages?
	if ( newDataSource!=nil ) {
		if ( ![newDataSource respondsToSelector:@selector(numberOfTasksForMetaJob:)] )
			[NSException raise:@"XGSMetaJobError" format:@"Data Source of XGSMetaJob must responds to selector numberOfTasksForMetaJob:"];
		if ( ![newDataSource respondsToSelector:@selector(metaJob:taskAtIndex:)] )
			[NSException raise:@"XGSMetaJobError" format:@"Data Source of XGSMetaJob must responds to selector metaJob:taskAtIndex:"];
	}
	
	//OK, we can use that object
	[self willChangeValueForKey:@"dataSource"];
	[self setPrimitiveValue:newDataSource forKey:@"dataSource"];
	[self didChangeValueForKey:@"dataSource"];
	
	//the value of countTotalTasks is potentially changed too
	unsigned int n=[[self dataSource] numberOfTasksForMetaJob:self];
	[self setValue:[NSNumber numberWithInt:n] forKey:@"countTotalTasks"];
}

- (id)delegate
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	return delegate;
}

//do not retain to avoid retain cycles
- (void)setDelegate:(id)newDelegate
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	delegate = newDelegate;
}

- (NSString *)name
{
	NSString *nameLocal;
	[self willAccessValueForKey:@"name"];
	nameLocal = [self primitiveValueForKey:@"name"];
	[self didAccessValueForKey:@"name"];
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	return nameLocal;
}

- (void)setName:(NSString *)nameNew
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	[self willChangeValueForKey:@"name"];
	[self setPrimitiveValue:nameNew forKey:@"name"];
	[self didChangeValueForKey:@"name"];
}

NSNumber *IntNumberWithAdditionOfIntNumbers(NSNumber *number1,NSNumber *number2)
{
	int a1=[number1 intValue];
	int a2=[number2 intValue];
	return [NSNumber numberWithInt:a1+a2];
}

NSNumber *IntNumberWithSubstractionOfIntNumbers(NSNumber *number1,NSNumber *number2)
{
	int a1=[number1 intValue];
	int a2=[number2 intValue];
	return [NSNumber numberWithInt:a1-a2];
}

NSNumber *FloatNumberWithPercentRatioOfNumbers(NSNumber *number1,NSNumber *number2)
{
	float a1=[number1 floatValue];
	float a2=[number2 floatValue];
	return [NSNumber numberWithFloat:100.0*a1/a2];
}

- (NSNumber *)countTotalTasks
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s]",[self class],self,_cmd);
	NSNumber *countTotalTasksLocal;
	[self willAccessValueForKey:@"countTotalTasks"];
	countTotalTasksLocal = [self primitiveValueForKey:@"countTotalTasks"];
	[self didAccessValueForKey:@"countTotalTasks"];
	return countTotalTasksLocal;
}

- (NSNumber *)countDoneTasks
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	return IntNumberWithAdditionOfIntNumbers([self valueForKey:@"countCompletedTasks"],
											 [self valueForKey:@"countDismissedTasks"]);
}

- (NSNumber *)countPendingTasks
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	return IntNumberWithSubstractionOfIntNumbers([self countTotalTasks],
												 [self countDoneTasks]);
}

- (NSNumber *)percentDone
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	return FloatNumberWithPercentRatioOfNumbers([self countDoneTasks],
												[self countTotalTasks]);
}

- (NSNumber *)percentPending
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	return FloatNumberWithPercentRatioOfNumbers([self countPendingTasks],
												[self countTotalTasks]);
}

- (NSNumber *)percentCompleted
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	return FloatNumberWithPercentRatioOfNumbers([self valueForKey:@"countCompletedTasks"],
												[self countTotalTasks]);
}

- (NSNumber *)percentDismissed
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	return FloatNumberWithPercentRatioOfNumbers([self valueForKey:@"countDismissedTasks"],
												[self countTotalTasks]);
}

- (NSNumber *)percentSubmitted
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	return FloatNumberWithPercentRatioOfNumbers([self valueForKey:@"countSubmittedTasks"],
												[self countTotalTasks]);
}

#pragma mark *** tracking tasks ***

//when reset, the available commands contains indexes that follow these rules
//	* index < [dataSource numberOfTasks]
//	* number of successes < successCountsThreshold
//	* number of failures < failureCountsThreshold (if failureCountsThreshold>0)
//	* number of submissions < maxSubmissionsPerTask
//Then, we get the following values for each of the commands left:
//	* number of successes
//	* number of submissions
//	* --> sum of the two = countTotalSubmissions
//... and then the max of that number for all these commands = N
//if all the commands have the same value N, keep them all in availableTasks
//Otherwise, this last condition ensures that all commands are at the same level:
//	* keep only commands for which successes + submissions < N
//Each time availableTasks is reset, it may thus include commands that are already submitted and pending,
//even though the results may not be needed. But this way, the last commands still pending may be
//done faster by being submitted to several agents in parallel
- (void)resetAvailableTasks
{
	unsigned int i,n;
	int totalSub, max, countCompletedTasks, countDismissedTasks;
	XGSIntegerArray *suc,*fai,*sub;
	BOOL allTheSame;

	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);

	//max index to use
	n=[[self dataSource] numberOfTasksForMetaJob:self];
	if ( n != [[self countTotalTasks] intValue] )
		[self setValue:[NSNumber numberWithInt:n] forKey:@"countTotalTasks"];
	
	//get pointers to the array for success, failures and submissions count
	suc=[self successCounts];
	fai=[self failureCounts];
	sub=[self submissionCounts];
	DLog(NSStringFromClass([self class]),10,@"successes: %@\nfailures: %@\nsubmissions: %@\n",[suc stringRepresentation],[fai stringRepresentation], [sub stringRepresentation]);
	
	//set up a first version of availableTasks
	//	* number of successes < successCountsThreshold
	//	* number of failures < failureCountsThreshold (if failureCountsThreshold>0)
	//	* number of submissions < maxSubmissionsPerTask
	//At the same time, count completed tasks and dismissed tasks
	countCompletedTasks = 0;
	countDismissedTasks = 0;
	int threshold1, threshold2;
	if ( availableTasks == nil )
		availableTasks = [[NSMutableIndexSet alloc] init];
	[availableTasks removeAllIndexes];
	threshold1 = [self successCountsThreshold];
	threshold2 = [self failureCountsThreshold];
	for (i=0;i<n;i++) {
		if ( [suc intValueAtIndex:i] < threshold1 ) {
			if ( ( threshold2 > 0 ) && ( [fai intValueAtIndex:i] >= threshold2 ) )
				countDismissedTasks++;
			else
				[availableTasks addIndex:i];
		}
		else
			countCompletedTasks++;
	}
	/*
	threshold = [self failureCountsThreshold];
	if ( threshold > 0 ) {
		for (i=0;i<n;i++) {
			if ( [fai intValueAtIndex:i] >= threshold ) {
				[availableTasks removeIndex:i];
				countDismissedTasks++:
			}
		}
	}
	 */
	int threshold = [self maxSubmissionsPerTask];
	for (i=0;i<n;i++) {
		if ( [sub intValueAtIndex:i] >= threshold )
			[availableTasks removeIndex:i];
	}
	
	//now we can update the value for countCompletedTasks and countDismissedTasks in the store
	[self setValue:[NSNumber numberWithInt:countCompletedTasks] forKey:@"countCompletedTasks"];
	[self setValue:[NSNumber numberWithInt:countDismissedTasks] forKey:@"countDismissedTasks"];
	
	//get the first index
	i=[availableTasks firstIndex];
	if (i==NSNotFound)
		return;
	
	//get the max of number of successes + number of submissions
	//note that i = first available command
	max = [suc intValueAtIndex:i] + [sub intValueAtIndex:i];
	allTheSame=YES;
	for (i++;i<n;i++) {
		if ([availableTasks containsIndex:i]) {
			totalSub = [suc intValueAtIndex:i] + [sub intValueAtIndex:i];
			if ( totalSub > max ) {
				max=totalSub;
				allTheSame=NO;
			}
		}
	}
	if (allTheSame)
		return;
	
	//now remove availableTasks for which totalSub>=max
	for (i=0;i<n;i++) {
		totalSub = [suc intValueAtIndex:i] + [sub intValueAtIndex:i];
		if (totalSub>=max)
			[availableTasks removeIndex:i];
	}
}

/*
//calculate the total number of tasks submitted so far for this metaJob
//by looking at the tasks of running and pending jobs
- (unsigned int)countSubmittedTasks
{
	NSSet *jobs;
	int total;
	XGSJob *aJob;
	XGJob *xgridJob;
	NSEnumerator *e;
	XGResourceState state;
	
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);

	total = 0;
	jobs = [self valueForKey:@"jobs"];
	e = [jobs objectEnumerator];
	while ( aJob = [e nextObject] ) {
		xgridJob = [aJob xgridJob];
		state = [xgridJob state];
		if ( state == XGResourceStateRunning || state == XGResourceStatePending )
			total += [xgridJob taskCount];
	}
	return total;
}
*/

//convenience method called by several other methods to decrement the submission count of a finished job
- (void)removeJob:(XGSJob *)aJob
{
	NSDictionary *taskMap;
	NSEnumerator *e;
	NSNumber *metaTaskIndex;

	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);

	taskMap = [[aJob jobInfo] objectForKey:@"TaskMap"];
	e = [taskMap objectEnumerator];
	while ( metaTaskIndex = [e nextObject] ) {
		int newSubmissionCounts = [[self submissionCounts] decrementIntValueAtIndex:[metaTaskIndex intValue]];
		if ( newSubmissionCounts == 0 ) {
			int old = [[self valueForKey:@"countSubmittedTasks"] intValue];
			[self setValue:[NSNumber numberWithInt:old-1] forKey:@"countSubmittedTasks"];
		}
	}
	[aJob setDelegate:nil];
	[[self mutableSetValueForKey:@"jobs"] removeObject:aJob];
	[aJob delete];
}


#pragma mark *** task specifications ***

// All these methods may later be updated to check that the data source implements the different selectors


- (NSString *)commandStringForTask:(id)taskItem
{
	return [[self dataSource] metaJob:self commandStringForTask:taskItem];	
}

- (NSArray *)argumentStringsForTask:(id)taskItem
{
	return [[self dataSource] metaJob:self argumentStringsForTask:taskItem];	
}

- (NSArray *)pathsToUploadForTask:(id)taskItem
{
	return [[self dataSource] metaJob:self pathsToUploadForTask:taskItem];	
}

- (NSData *)stdinDataForTask:(id)taskItem
{
	return [NSData data];	
}


#pragma mark *** submitting jobs ***

//this method is called by submitNextJobs (see below)
/*
taskList dictionary:
		key   = global task index
		value = taskItem (as returned by dataSource)
pathsToUpload have been already defined in the method 'submitNextJobs' :
	- they are all the same for the tasks (or some tasks may have no paths to upload)
	- they are alphabetically ordered
NOTE: I cannot have different sets of paths for different tasks, because the key XGJobSpecificationInputFileMapKey does not behave as expected; using this key in the task specifications cancel all uploads otherwise defined by the XGJobSpecificationInputFilesKey; this could be a bug in Xgrid or me not understanding the syntax ('man xgrid' for an example of batch format job submission, which apparently follows the same syntax as the dictionary used by the Cocoa APIs)
 */
- (void)submitJobWithTaskList:(NSDictionary *)taskList paths:(NSArray *)pathsToUpload
{
	NSEnumerator *e;
	NSNumber *metaTaskIndex;
	id taskItem;
	NSArray *paths;
	NSDictionary *fileDictionary,*jobSpecification;
	NSMutableDictionary *taskSpecifications, *oneTaskDictionary, *inputFiles, *fileMap;
	NSString *currentPath,*currentDir, *subPath, *commandString, *temp1, *temp2;
	NSMutableString *jobName;
	NSArray *argumentStrings;
	NSMutableArray *args;
	NSFileManager *fileManager;
	BOOL exists,isDir,isSubPath;
	NSRange pathRange;
	NSData *stdinStream;
	XGSJob *newJob;
	int taskID;
	NSMutableDictionary *taskMap;
	
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	DLog(NSStringFromClass([self class]),12,@"\ntaskList:\n%@\npathsToUpload:\n%@",[taskList description],[pathsToUpload description]);

	//create the XGSJob object used to wrap the XGJob
	newJob = [NSEntityDescription insertNewObjectForEntityForName:@"Job" inManagedObjectContext:[self managedObjectContext]];
	[[self mutableSetValueForKey:@"jobs"] addObject:newJob];
	[newJob setDelegate:self];
	
	//create the taskMap = simple correspondance between taskID (index in the Job) and metaTaskIndex (index in the MetaJob) --> used in the jobInfo entry of the XGSJob
	taskMap = [NSMutableDictionary dictionaryWithCapacity:[taskList count]];
	taskID = 0;
	e = [taskList keyEnumerator];
	while ( metaTaskIndex = [e nextObject] ) {
		[taskMap setObject:metaTaskIndex forKey:[NSString stringWithFormat:@"%d",taskID]];
		taskID++;
	}
	[newJob setJobInfo:[NSDictionary dictionaryWithObjectsAndKeys:
		[[self objectID] URIRepresentation], @"MetaJobID",
		taskMap, @"TaskMap",
		nil] ];
	
	//fileMap dictionary will keep track of the correspondance between paths on the client and paths on the agent
	//	key   = path on the client (a full path)
	//	value = path on the agent  (a relative path in the working directory)
	fileMap = [NSMutableDictionary dictionaryWithCapacity:[pathsToUpload count]];
	
	/* definition of the inputFiles */
	/*	- a dir on the client ==> any subpath is also a subpath on the agent
		- a group of subpaths of a dir on the client ==> all uploaded inside one directory in the working directory of the agent
	As a result, the file tree is more 'flat' on the agent; for instance:
		Paths on the client							Files on the agent
		-------------------							------------------
		/Users/username/Documents/dir1				dir1
		/Users/username/Documents/dir1/file1		dir1/file1
		/Users/username/Documents/dir1/file2		dir1/file2
		/etc/myfiles/param1							param1
		/etc/mydir									mydir
		/etc/mydir/settings1.txt					mydir/settings1.txt
		/etc/mydir/settings2.txt					mydir/settings2.txt
	*/
	inputFiles = [NSMutableDictionary dictionaryWithCapacity:[pathsToUpload count]];
	fileManager = [NSFileManager defaultManager];
	currentDir = @"."; //that can't be the first character in a path!
	e = [pathsToUpload objectEnumerator];
	while ( currentPath = [e nextObject] ) {
		exists = [fileManager fileExistsAtPath:currentPath isDirectory:&isDir];
		if ( exists ) {
			
			//is the currentPath a subpath of the currentDir?
			if ( [currentDir length] > [currentPath length]-1 )
				isSubPath = NO;
			else {
				pathRange = NSMakeRange(0,[currentDir length]);
				subPath = [currentPath substringWithRange:pathRange];
				isSubPath = [subPath isEqualToString:currentDir];
			}

			//the subPath string is the relative path on the agent
			if ( isSubPath )
				subPath = [[currentDir lastPathComponent] stringByAppendingPathComponent:[currentPath substringFromIndex:[currentDir length]+1]];
			else
				subPath = [currentPath lastPathComponent];
			[fileMap setObject:subPath forKey:currentPath];
			
			//if it is a dir, we may need to redefine the currentDir
			//and we need to create a dummy file to make sure the dir is created
			if ( isDir ) {
				if ( isSubPath ==NO )
					currentDir = currentPath;
				subPath = [subPath stringByAppendingPathComponent:@".GridStuffer_dummy_file_to_force_dir_creation"];
				fileDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSData dataWithBytes:"hi" length:2], XGJobSpecificationFileDataKey,
					@"NO", XGJobSpecificationIsExecutableKey,
					nil];
			}
				
			//if it is a file, we add it to the inputFile, and we may need to reset the currentDir
			else {
				if ( isSubPath==NO )
					currentDir = @"//";
				fileDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSData dataWithContentsOfFile:currentPath], XGJobSpecificationFileDataKey,
					[fileManager isExecutableFileAtPath:currentPath]?@"YES":@"NO", XGJobSpecificationIsExecutableKey,
					nil];
			}
			
			//now add the file to the input files
			[inputFiles setObject:fileDictionary forKey:subPath];
		}
	}

	
	//define the task specifications by calling the appropriate methods on the dataSource
	taskID = 0;
	taskSpecifications = [NSMutableDictionary dictionaryWithCapacity:[taskList count]];
	e = [taskList keyEnumerator];
	while ( metaTaskIndex = [e nextObject] ) {
		
		//this is the task item, as it was returned by the datasource
		taskItem = [taskList objectForKey:metaTaskIndex];
		commandString = [self commandStringForTask:taskItem];
		argumentStrings = [self argumentStringsForTask:taskItem];

		//the dictionary for one task has at most 4 entries
		oneTaskDictionary = [NSMutableDictionary dictionaryWithCapacity:4];
		
		/* TO DO !!! */
		//the standard-in stream
		stdinStream = [self stdinDataForTask:taskItem];
		//if ( [stdin length] > 0)
		//	[oneTaskDictionary setObject:stdin forKey:XGJobSpecificationInputStreamKey];
		
		//if the task has no paths, we need to add an inputFileMap to prevent inputFiles addition to that task
		paths = [self pathsToUploadForTask:taskItem];
		if ( [paths count] == 0 )
			[oneTaskDictionary setObject:[NSDictionary dictionary] forKey:XGJobSpecificationInputFileMapKey];
		
		//otherwise the command and argument strings might need to be changed if corresponding to one of the uploaded paths
		else if ( [inputFiles count]>0 ) {
			if ( (commandString!=nil) && (temp1=[fileMap objectForKey:commandString]) )
				commandString = [@"../working" stringByAppendingPathComponent:temp1]; //trying to use the 'working' directory instead of the 'executable' directory
			args = [NSMutableArray arrayWithCapacity:[argumentStrings count]];
			NSEnumerator *e2 = [argumentStrings objectEnumerator];
			while ( temp2 = [e2 nextObject] ){
				temp1 = [fileMap objectForKey:temp2];
				[args addObject:temp1?temp1:temp2];
			}
			argumentStrings = [NSArray arrayWithArray:args];
		}
		
		//add final dictionary to tasksSpecification dictionary
		if ( commandString!=nil)
			[oneTaskDictionary setObject:commandString forKey:XGJobSpecificationCommandKey];
		if ( [argumentStrings count]>0 )
			[oneTaskDictionary setObject:argumentStrings forKey:XGJobSpecificationArgumentsKey];
		[taskSpecifications setObject:[NSDictionary dictionaryWithDictionary:oneTaskDictionary] forKey:[NSString stringWithFormat:@"%d",taskID]];
		taskID++;
	}

	//create a name for the job
	NSArray *indexes = [[taskList allKeys] sortedArrayUsingSelector:@selector(compare:)];
	jobName = [NSMutableString stringWithFormat:@"%@ [", [self valueForKey:@"name"]];
	int i,ii,j,n;
	if ( [indexes count]>0 ) {
		j = 0; //number of ranges already added
		e = [indexes objectEnumerator];
		i = [[e nextObject] intValue]; //current index
		n = i; //current start of range
		[jobName appendFormat:@" %d",n];
		while ( metaTaskIndex = [e nextObject] ) {
			ii = [metaTaskIndex intValue];
			if ( ii==i+1 )
				i = ii;
			else {
				if ( n<i )
					[jobName appendFormat:@"-%d",i];
				n=i=ii;
				j++;
				if ( j>20 ) {
					[jobName appendString:@",...  "];
					[e allObjects];
				} else
					[jobName appendFormat:@", %d",ii];
			}
		}
		if ( n<i && j<21 )
			[jobName appendFormat:@"-%d",i];
	}
	[jobName appendString:@" ]"];	
	
	//the final job specifications dictionary, ready to submit
	jobSpecification = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSString stringWithString:jobName], XGJobSpecificationNameKey,
		@"gridstuffer", XGJobSpecificationApplicationIdentifierKey,
		inputFiles, XGJobSpecificationInputFilesKey,
		taskSpecifications, XGJobSpecificationTaskSpecificationsKey,
		nil];
	
	//submit!!
	DLog(NSStringFromClass([self class]),12,@"\njobSpecification:\n%@",[jobSpecification description]);
	[newJob submitWithJobSpecification:jobSpecification];
	[newJob loadResultsWhenFinished];
}

//this method decides how many tasks and jobs to create based on the MetaJob settings
//it create TaskLists to send to the above method 'submitJobWithTaskList:paths:'
- (void)submitNextJobs
{
	int a,b,minTasks,maxTasks,maxBytes;
	int byteCount,taskCount;
	int taskIndex;
	id taskItem;
	NSMutableDictionary *taskList;
	NSArray *paths,*newPaths;
	
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);

	//have we already reached the maxSubmittedTasks?
	if ( [[self valueForKey:@"countSubmittedTasks"] intValue] >= [[self valueForKey:@"maxSubmittedTasks"] intValue] )
		return;
	
	//initializations
	byteCount = taskCount = 0;
	a        = [[self valueForKey:@"availableAgentsMultiplication"] intValue];
	b        = [[self valueForKey:@"availableAgentsAddition"] intValue];
	minTasks = [[self valueForKey:@"minTasksPerSubmission"] intValue];
	maxTasks = [[self valueForKey:@"maxTasksPerSubmission"] intValue];
	maxBytes = [[self valueForKey:@"maxBytesPerSubmission"] intValue];
	taskList  = [NSMutableDictionary dictionaryWithCapacity:maxTasks];
	paths = [NSArray array];
	
	//the real value of maxTasks = the number we really want to submit 
	/* TO DO : count available agents + etc... */
	if ( b < maxTasks )
		maxTasks = b;
	if ( maxTasks < minTasks )
		maxTasks = minTasks;
	
	
	//retrieve tasks items from the data source until:
	//		- countTasks = maxTasks
	//  OR	- countBytes = maxBytes
	/*** TO DO : add code to REALLY take into account maxBytes !!! ***/
	while ( taskCount < maxTasks && byteCount < maxBytes ) {
		
		//get the next taskItem from the data source, if any
		taskIndex = [availableTasks firstIndex];
		if ( taskIndex == NSNotFound )
			break;
		taskItem = [[self dataSource] metaJob:self taskAtIndex:taskIndex];
		if ( taskItem == nil )
			break;
		
		//keep track of submissions
		[availableTasks removeIndex:taskIndex];
		int newSubmissionCounts = [[self submissionCounts] incrementIntValueAtIndex:taskIndex];
		if ( newSubmissionCounts == 1 ) {
			int old = [[self valueForKey:@"countSubmittedTasks"] intValue];
			[self setValue:[NSNumber numberWithInt:old+1] forKey:@"countSubmittedTasks"];
		}
		taskCount ++;
		
		//to be in the same jobs, tasks need to have the same uploaded paths
		//so I use that criteria to group tasks in jobs (sorting paths allows for more accurate comparison and is needed in the next steps anyway)
		/* TO DO : have a 'NSArray *StandardizedPaths (NSArray *paths)' function to make sure we get standardized paths */
		newPaths = [self pathsToUploadForTask:taskItem];
		newPaths = [newPaths sortedArrayUsingSelector:@selector(compare:)];
		if (	[paths count]    == 0				//paths not yet defined
			 || [newPaths count] == 0				//no paths on this task
			 || [newPaths isEqualToArray:paths]	)	//paths are exactly the same as previous tasks
		{
			//then we can simply add that task to the current job and maybe define paths
			[taskList setObject:taskItem forKey:[NSNumber numberWithInt:taskIndex]];
			if ( [paths count]==0 )
				paths = newPaths;
		} else {
			//otherwise, we are done with the current job and we can start a new taskList
			[self submitJobWithTaskList:taskList paths:paths];
			[taskList removeAllObjects];
			[taskList setObject:taskItem forKey:[NSNumber numberWithInt:taskIndex]];
			paths = newPaths;
		}
	}
	
	//now start the last taskList if not empty
	if ( [taskList count]>0 )
		[self submitJobWithTaskList:taskList paths:paths];
	
}

//called every 'submissionInterval' seconds to submit more jobs
- (void)submitNextJobsWithTimer:(NSTimer *)timer
{
	NSTimeInterval interval;
	
	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	
	//check consistency
	if (submissionTimer!=timer)
		[NSException raise:@"XGSMetaJobInconsistency"
					format:@"The ivar submissionTimer should be equal to the timer passed as argument to 'submitNextJobsWithTimer:'"];
	submissionTimer=nil;
	
	//Only submit more jobs if isRunning
	if ( [self isRunning]==NO )
		return;
	[self submitNextJobs];
	if ( [availableTasks count] < 1 )
		[self resetAvailableTasks];
	
	//fire a new timer
	interval = [[self valueForKey:@"submissionInterval"] intValue];
	submissionTimer=[NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(submitNextJobsWithTimer:) userInfo:nil repeats:NO];
}

- (BOOL)isRunning
{
	BOOL flag;

	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);

	[self willAccessValueForKey:@"isRunning"];
	flag = [[self primitiveValueForKey:@"isRunning"] boolValue];
	[self didAccessValueForKey:@"isRunning"];
	return flag;
}

- (void)start
{
	NSMutableSet *currentJobs;
	NSEnumerator *e;
	XGSJob *oneJob;
	
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	
	//update state
	if ( [self isRunning] )
		return;
	[self setValue:[NSNumber numberWithBool:YES] forKey:@"isRunning"];
	[self setValue:@"Running" forKey:@"statusString"];
	if ([delegate respondsToSelector:@selector(metaJobDidStart:)])
		[delegate metaJobDidStart:self];

	//clean-up and reset current pending jobs
	currentJobs = [self mutableSetValueForKey:@"jobs"];
	e = [currentJobs objectEnumerator];
	while ( oneJob = [e nextObject] ) {
		[oneJob setDelegate:self];
		[oneJob loadResultsWhenFinished];
	}
	
	//prepare for task submissions
	[self resetAvailableTasks];
	
	//start the "run loop"
	[self submitNextJobsWithTimer:nil];
}

- (void)suspend
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);

	[self setValue:[NSNumber numberWithBool:NO] forKey:@"isRunning"];
	[self setValue:@"Suspended" forKey:@"statusString"];
	[submissionTimer invalidate];
	submissionTimer = nil;
	if ([delegate respondsToSelector:@selector(metaJobDidSuspend:)])
		[delegate metaJobDidSuspend:self];
}

- (void)deleteFromStore
{
	NSEnumerator *e;
	NSArray *jobs;
	XGSJob *aJob;

	DLog(NSStringFromClass([self class]),10,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);

	//no more notifications
	[self setDelegate:nil];
	[self suspend];
	
	//delete all the jobs
	jobs = [self valueForKey:@"jobs"];
	e = [jobs objectEnumerator];
	while ( aJob = [e nextObject] ) {
		[aJob setDelegate:nil];
		[aJob delete];
	}
	
	//now remove from the managed context
	[[self managedObjectContext] deleteObject:self];
}


#pragma mark *** XGSJob delegate methods ***

//MetaJob is a delegate of multiple XGSJob
//these are the XGSJob delegate methods

/*
 - (void)jobDidStart:(XGSJob *)aJob;
 - (void)jobDidNotStart:(XGSJob *)aJob;
 - (void)jobStatusDidChange:(XGSJob *)aJob;
 - (void)jobDidFinish:(XGSJob *)aJob;
 - (void)jobDidFail:(XGSJob *)aJob;
 - (void)jobWasDeleted:(XGSJob *)aJob fromGrid:(XGSGrid *)aGrid;
 - (void)jobWasNotDeleted:(XGSJob *)aJob;
 - (void)jobDidProgress:(XGSJob *)aJob completedTaskCount:(unsigned int)count;
 - (void)job:(XGSJob *) didReceiveResults:(NSDictionary *)results task:(XGSTask *)task;
*/ 


- (void)jobDidStart:(XGSJob *)aJob
{
	DLog(NSStringFromClass([self class]),10,@"[<%@:%p> %s %@]",[self class],self,_cmd,[aJob name]);
}

- (void)jobDidNotStart:(XGSJob *)aJob
{
	DLog(NSStringFromClass([self class]),10,@"[<%@:%p> %s %@]",[self class],self,_cmd,[aJob name]);
	[self removeJob:aJob];
}

- (void)jobDidFail:(XGSJob *)aJob
{
	DLog(NSStringFromClass([self class]),10,@"[<%@:%p> %s %@]",[self class],self,_cmd,[aJob name]);
	[self removeJob:aJob];
}

- (void)jobDidFinish:(XGSJob *)aJob
{
	DLog(NSStringFromClass([self class]),10,@"[<%@:%p> %s %@]",[self class],self,_cmd,[aJob name]);
}

- (void)job:(XGSJob *)aJob didLoadResults:(NSDictionary *)results
{
	NSEnumerator *e;
	NSString *taskIdentifier;
	NSNumber *metaTaskIndex;
	NSDictionary *taskMap,*resultDictionary,*taskItem;
	XGSIntegerArray *successCounts, *failureCounts, *submissionCounts;
	int index;
	id dataSource;

	DLog(NSStringFromClass([self class]),10,@"[<%@:%p> %s %@]",[self class],self,_cmd,[aJob name]);
	DLog(NSStringFromClass([self class]),10,@"\nResults:\n%@",[results description]);

	//the taskMap allows to convert taskID in metaTaskIndex
	taskMap = [[aJob jobInfo] objectForKey:@"TaskMap"];
	if ( taskMap == nil )
		[NSException raise:@"XGSMetaJobError" format:@"No task map stored in the job"];

	
	//get the integer arrays used to keep track of submissions and successes
	successCounts = [self successCounts];
	failureCounts = [self failureCounts];
	submissionCounts = [self submissionCounts];
	
	//loop over the dictionary keys to return individual task results
	dataSource = [self dataSource];
	e = [results keyEnumerator];
	while ( taskIdentifier = [e nextObject] ) {
		metaTaskIndex = [taskMap objectForKey:taskIdentifier];
		index = [metaTaskIndex intValue];
		taskItem = [dataSource metaJob:self taskAtIndex:index];
		resultDictionary = [results objectForKey:taskIdentifier];
		
		//the result dictionary can be divided in 3 pieces: the files, the sdout and the stderr
		NSMutableDictionary *resultFiles;
		resultFiles = [NSMutableDictionary dictionaryWithDictionary:resultDictionary];
		[resultFiles removeObjectForKey:XGSJobResultsStandardOutputKey];
		[resultFiles removeObjectForKey:XGSJobResultsStandardErrorKey];
		NSData *stdoutData, *stderrData;
		stdoutData = [resultDictionary objectForKey:XGSJobResultsStandardOutputKey];
		stderrData = [resultDictionary objectForKey:XGSJobResultsStandardErrorKey];

		//the data source may want to validate the results and decide if they are good or not
		BOOL flag;
		if ( [dataSource respondsToSelector:@selector(metaJob:validateResultsWithFiles:standardOutput:standardError:forTask:)] )
			flag = [dataSource metaJob:self validateResultsWithFiles:resultFiles standardOutput:stdoutData standardError:stderrData forTask:taskItem];
		else
			flag = YES;
		int newCount;
		if ( flag == YES ) {
			newCount = [successCounts incrementIntValueAtIndex:index];
			if ( newCount == [self successCountsThreshold] ) {
				int old = [[self valueForKey:@"countCompletedTasks"] intValue];
				[self setValue:[NSNumber numberWithInt:old+1] forKey:@"countCompletedTasks"];
			}
			
		}
		else {
			newCount = [failureCounts incrementIntValueAtIndex:index];
			if ( newCount == [self failureCountsThreshold] ) {
				int old = [[self valueForKey:@"countDismissedTasks"] intValue];
				[self setValue:[NSNumber numberWithInt:old+1] forKey:@"countDismissedTasks"];
			}
			
		}
		
		//some of the results may be handled by the data source, and if not they will be handled by the output interface
		NSMutableDictionary *resultsHandledByOutputInterface;
		resultsHandledByOutputInterface = [NSMutableDictionary dictionary];
		
		//the data source of the output interface saves the STDOUT
		if ( [dataSource respondsToSelector:@selector(metaJob:saveStandardOutput:forTask:)] )
			flag = [dataSource metaJob:self saveStandardOutput:stdoutData forTask:taskItem];
		else
			flag = NO;
		if ( ( flag == NO)  && ( stdoutData !=nil ) )
			[resultsHandledByOutputInterface setObject:stdoutData forKey:XGSJobResultsStandardOutputKey];

		//the data source of the output interface saves the STDERR
		if ( [dataSource respondsToSelector:@selector(metaJob:saveStandardError:forTask:)] )
			flag = [dataSource metaJob:self saveStandardError:stderrData forTask:taskItem];
		else
			flag = NO;
		if ( ( flag == NO ) && ( stderrData !=nil ) )
			[resultsHandledByOutputInterface setObject:stderrData forKey:XGSJobResultsStandardErrorKey];

		//the data source of the output interface saves the other files
		if ( [dataSource respondsToSelector:@selector(metaJob:saveFiles:forTask:)] )
			flag = [dataSource metaJob:self saveFiles:resultFiles forTask:taskItem];
		else
			flag = NO;
		if ( flag == NO )
			[resultsHandledByOutputInterface addEntriesFromDictionary:resultFiles];
		
		//whatever is left is for the OutputInterface
		[[self outputInterface] saveFiles:resultsHandledByOutputInterface inFolder:[metaTaskIndex stringValue]];
		
	}
	
	//we are done with the job - delete it...
	[self removeJob:aJob];
}

@end
