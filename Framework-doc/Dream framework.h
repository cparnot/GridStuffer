/* 

Plan for an ideal  framework

CLASS LIST

Major classes:
	* XGSServer
	* XGSJob

Classes for advanced users
	* XGSGrid
	* XGSTask (?)
	* XGSFrameworkSettings

*/

#import <Cocoa/Cocoa.h>

/* XGSServer.h */

//Constants to use to subscribe to notifications received in response to the connect call
//no delegate as there is only one instance of server per address; thus, several client objects trying to be delegate could overwrite each other in unpredictable ways
APPKIT_EXTERN NSString *XGSServerDidConnectNotification;
APPKIT_EXTERN NSString *XGSServerDidNotConnectNotification;
APPKIT_EXTERN NSString *XGSServerDidDisconnectNotification;

//after connection, it might take a while before the object loads all the information from the server: how many grids,...
APPKIT_EXTERN NSString *XGSServerDidLoadNotification;

@interface XGSServer : XGSManagedObject
{}

//Creating server instances
//Server instances are added to the default persistent store (see XGSFrameworkSettings), that can be used with bindings to display an automatically updated list of all the servers in the GUI
+ (void)startBrowsing;
+ (void)stopBrowsing;
+ (NSArray *)allServers;
+ (XGSServer *)serverWithAddress:(NSString *)address;


//New instances are always added to the default persistent store (see XGSFrameworkSettings), but using this method, a server can in addition be attached to a custom context (e.g. for document-based app)
//Instances are guaranteed to be unique for a given address and a given managed object context, but you will get two different instances for servers with the same addresses on 2 separate contexts 
+ (XGSServer *)serverWithAddress:(NSString *)address inManagedObjectContext:(NSManagedObjectContext *)context;

//Connecting (either automatically or using a specific protocol)
- (void)connect;
- (void)disconnect;
- (void)connectWithoutAuthentication;
- (void)connectWithSingleSignOnCredentials;
- (void)connectWithPassword:(NSString *)password;

//Submitting jobs using the default grid (notifications received by the XGSJob object, see header for that class)
//The XGSJob is added to the same managed object context as the server
//To submit jobs to different grids, use XGSGrid class instead
- (XGSJob *)submitJobWithSpecifications:(NSDictionary *)specs;

//KVO/KVC-compliant accessors
- (NSString *)address;
- (XGSGrid *)defaultGrid;
- (NSSet *)grids; //XGSGrid objects, not XGGrid
- (NSSet *)jobs; //XGSJob objects, not XGJob
- (BOOL)isAvailable;
- (BOOL)isConnecting;
- (BOOL)isConnected;
- (BOOL)isLoaded;
- (NSString *)statusString;
- (BOOL)shouldRememberPassword;
- (void)setShouldRememberPassword:(BOOL)flag;
- (void)setPassword:(NSString *)aString;

//low-level accessors
- (XGController *)xgridController;
- (XGConnection *)xgridConnection;
- (NSArray *)xgridGrids; //array of XGGrid
- (NSArray *)xgridJobs;  //array of XGJob

@end




/* XGSJob.h */

//To follow a job status, you can use a delegate (see further below) or notifications

//Constants to use to subscribe to notifications received after submitting a job
APPKIT_EXTERN NSString *XGSJobDidStartNotification;
APPKIT_EXTERN NSString *XGSJobDidNotStartNotification;
APPKIT_EXTERN NSString *XGSJobDidFinishNotification;
APPKIT_EXTERN NSString *XGSJobDidFailNotification;
APPKIT_EXTERN NSString *XGSJobDidRetrieveResultsNotification;
APPKIT_EXTERN NSString *XGSJobWasDeletedNotification;

//if a job was submitted in a previous session, and you are reconnecting to the grid server and trying to get some info about the job, this notification will tell you when its attributes have been loaded from the server (name, status,...)
APPKIT_EXTERN NSString *XGSJobDidLoadNotification;


@interface XGSJob : XGSManagedObject
{}

//Creating XGSJob objects
//The managed object will be attached to the context of the server (or grid) to which it is submitted, or to a custom context
- (id)init;
- (id)initWithServer:(XGSServer *)server;
- (id)initWithGrid:(XGSGrid *)grid;
- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context;

//the server (or a specific grid) is the one to which the job is submitted
//	- if set before submission, the job will try to use it and will fail to start if the grid is diconnected
//	- if not set, or set to nil, the job will use the first available server connected
//	- after submission and even after the submission succeded or failed, the grid cannot be modified
//	- during submission, the grid may change several times, but will be fixed once the submission has successed or failed
//if the server (or grid) and the job objects are in different managed contexts, the equivalent server (and grid) in the correct managed object context will be used instead 
- (XGSServer *)server;
- (void)setServer:(XGSServer *)newServer;
- (XGSGrid *)grid;
- (void)setGrid:(XGSGrid *)newGrid;

//job actions
//the 'submit' method can only be used once on a given job
//the job specification is only cached during submission, and is discarded if submission succedeed or failed (this is because it can be big)
- (void)submitWithJobSpecification:(NSDictionary *)jobSpecification;

//the job will be stopped and then deleted from the Xgrid server and then from the managed object context
- (void)delete;

//the job can be set to automatically load the results when it is finished (which may be immediately triggered if already finished)
//manual loading of the results with '-loadResults' can be called anytime, even before the job finishes for intermediary results, which will also cancel the automatic download (if not already started)
//the delegate will receive the results asynchronouly when all the task results have been loaded
//you need to wait until the results are loaded before calling '-loadResults' again (or else cancel the load first)
- (void)retrieveResultsWhenFinished;
- (void)retrieveResults;
- (BOOL)isRetrievingResults;
- (void)cancelResultRetrieval;

//jobInfo can be used to store persistent information about the job (can be retrieved or modified even after submission, as opposed to the job specification)
//for persistent storage, the jobInfo object has to follow the NSCoding protocol
- (void)setJobInfo:(id)newJobInfo;
- (id)jobInfo;

//see below, the informal protocol for the delegate
- (id)delegate;
- (void)setDelegate:(id)newDelegate;

//KVO/KVC-compliant accessors
- (NSString *)name;
- (unsigned int)completedTaskCount;
- (NSString *)statusString;
- (BOOL)isLoaded;
- (BOOL)isSubmitted;
- (BOOL)isRunning;
- (BOOL)isFinished;
- (BOOL)isFailed;
- (BOOL)isDeleted;

//Low level accessor
- (XGJob *)xgridJob;

@end

//methods that can be implemented by the XGSJob delegate
@interface NSObject (XGSJobDelegate)
- (void)jobDidStart:(XGSJob *)aJob;
- (void)jobDidNotStart:(XGSJob *)aJob;
- (void)jobDidFinish:(XGSJob *)aJob;
- (void)jobDidFail:(XGSJob *)aJob;
- (void)jobWasDeleted:(XGSJob *)aJob fromGrid:(XGSGrid *)aGrid;
- (void)jobWasNotDeleted:(XGSJob *)aJob;
- (void)jobDidProgress:(XGSJob *)aJob completedTaskCount:(unsigned int)count;
- (void)job:(XGSJob *)aJob didRetrieveResults:(NSDictionary *)results;
@end




/* XGSGrid.h */

//a grid is considered loaded after all its attributes (name, jobs,...) have been uploaded from the server
APPKIT_EXTERN NSString *XGSServerDidLoadNotification;

@interface XGSGrid : XGSManagedObject
{}

//Grid instances are automatically created by XGSServer objects, and should not be created in any other ways
//Retrieve grid methods using the following methods
- (NSArray *)gridsForServer:(XGSServer *)server;
- (XGSGrid *)defaultGridForServer:(XGSServer *)server;
- (XGSGrid *)gridWithName:(NSString *)gridName server:(XGSServer *)server;
- (XGSGrid *)gridWithIdentifier:(NSString *)gridID server:(XGSServer *)server;

//The XGSJob is added to the same managed object context as the grid
- (XGSJob *)submitJobWithSpecifications:(NSDictionary *)specs;

//KVO/KVC-compliant accessors
- (NSString *)name;
- (NSSet *)jobs; //XGSJob objects, not XGJob
- (BOOL)isAvailable;
- (BOOL)isConnecting;
- (BOOL)isConnected;
- (BOOL)isLoaded;
- (NSString *)statusString;

//low-level accessors
- (XGGrid *)xgridGrid;
- (XGController *)xgridController;
- (XGConnection *)xgridConnection;
- (NSArray *)xgridJobs;  //array of XGJob

//Loading more XGSJob in the managed object context
//By default, only job submitted in the context are added, and the XGSJob objects can be only a subset of the actual underlying XGJob objects; in a way, XGSJob are client-specific; these methods will create (if necessary) more XGSJob objects in the managed object context even if not initially submitted by the XGSServer
- (XGSJob *)jobWithIdentifier:(NSString *)identifier;
- (NSArray *)allJobs; //return XGSJob objects, not XGJob 

//using this flag, a grid can be set to automatically create more XGSJob objects as more XGJob objects are created by other apps
- (BOOL)shouldLoadAllJobs;
- (void)setShouldLoadAllJobs:(BOOL)flag;

@end
