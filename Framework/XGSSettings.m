//
//  XGSFrameworkSettings.m
//  GridStuffer
//
//  Created by Charles Parnot on 8/14/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "XGSFrameworkSettings.h"


@implementation XGSFrameworkSettings

#pragma mark *** creating and retrieving the singleton instance ***


XGSFrameworkSettings *sharedFrameworkSettings = nil;

+ (XGSFrameworkSettings *)sharedFrameworkSettings
{
	if ( sharedFrameworkSettings == nil ) {
		sharedFrameworkSettings = [[XGSFrameworkSettings alloc] init];
	}
	return sharedFrameworkSettings;
}


#pragma mark *** Managed Object Context ***

- (NSManagedObjectModel *)managedObjectModel
{
    if (managedObjectModel)
		return managedObjectModel;
	
	NSMutableSet *allBundles = [[NSMutableSet alloc] init];
	[allBundles addObject: [NSBundle mainBundle]];
	[allBundles addObjectsFromArray: [NSBundle allFrameworks]];
    
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles: [allBundles allObjects]] retain];
    [allBundles release];
    
    return managedObjectModel;
}

- (NSString *)applicationSupportFolder
{
    NSString *applicationSupportFolder = nil;
	NSString *folderName,*version;
	
	//there might be several stores at the same time:
	//	- in use by different applications or by the same application
	//	- in addition, each version will use a different location because backward compatibility is not yet implemented
	//	- finally, the store is different in debug mode
	folderName = @"GridStuffer";
	version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	if ( [version isEqualToString:@"0.2.1"] )
		version = @"0.2.0"; //versions 0.2.1 and 0.2.0 have compatible managed object models
	folderName = [folderName stringByAppendingFormat:@"_version_%@",version];
#ifdef DEBUG
	folderName = [folderName stringByAppendingString:@"_DEBUG"];
#endif
	
    FSRef foundRef;
    OSErr err = FSFindFolder(kUserDomain, kApplicationSupportFolderType, kDontCreateFolder, &foundRef);
    if (err != noErr) {
        NSRunAlertPanel(@"Alert", @"Can't find application support folder", @"Quit", nil, nil);
        [[NSApplication sharedApplication] terminate:self];
    } else {
        unsigned char path[1024];
        FSRefMakePath(&foundRef, path, sizeof(path));
        applicationSupportFolder = [NSString stringWithUTF8String:(char *)path];
        applicationSupportFolder = [applicationSupportFolder stringByAppendingPathComponent:folderName];
    }
    return applicationSupportFolder;
}

- (NSManagedObjectContext *)managedObjectContext
{
    NSError *error;
    NSString *applicationSupportFolder = nil;
    NSURL *url;
    NSFileManager *fileManager;
    NSPersistentStoreCoordinator *coordinator;
    
    if (managedObjectContext) {
        return managedObjectContext;
    }
    
    fileManager = [NSFileManager defaultManager];
    applicationSupportFolder = [self applicationSupportFolder];
    if ( ![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL] ) {
        [fileManager createDirectoryAtPath:applicationSupportFolder attributes:nil];
    }
    
    url = [NSURL fileURLWithPath: [applicationSupportFolder stringByAppendingPathComponent: @"GridStuffer.db"]];
    coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if ([coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error]){
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    } else {
        [[NSApplication sharedApplication] presentError:error];
    }    
    [coordinator release];
    
    return managedObjectContext;
}


#pragma mark *** Public class methods ***
+ (NSManagedObjectContext *)sharedManagedObjectContext
{
	return [[self sharedFrameworkSettings] managedObjectContext];
}


@end
