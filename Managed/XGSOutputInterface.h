//
//  XGSOutputInterface.h
//  GridStuffer
//
//  Created by Charles Parnot on 5/14/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//



/* COMMENTS NEED SOME UPDATE
 This class takes care of writing and retrieving files in the output folder.
 The 'outputFolder' ivar is a path to a folder on disk where files can be saved 
 at the 'root level', or within subfolders that represent individual tasks.
 Files saved at the root level can be appended. Files saved in subfolders
 are passed as dictionary, so that one can save a bunch of them at once.
 Subfolders representing tasks are accessed by their id, which is also
 their names in the filesystem. For each dictionary passed for a given 
 subfolder/id, this class creates a different subsubfolder each time,
 so that several results can be saved for each task without overwriting
 each other.
 */



@interface XGSOutputInterface : XGSManagedObject
{

}

//accessors
- (NSString *)folderPath;
- (NSString *)logFileName;
- (void)setFolderPath:(NSString *)folderPathNew;
- (void)setLogFileName:(NSString *)logFileNameNew;

//save files using the 'folderPath' as root if 'path' is relative
//the dictionaryRepresentation uses the keys as paths and the values as data
//if the one of the files already exists at the path, a 'results' folder will be created with a number (e.g. 'results_1') inside which ALL the files will be saved, even if some of them are NOT already present; this way, files stay "together"
- (BOOL)saveFiles:(NSDictionary *)dictionaryRepresentation inFolder:(NSString *)path;

//if the file already exists, a number is appended to it, e.g. thefile.txt, thefile_1.txt, thefile_2.txt,...
- (BOOL)saveData:(NSData *)someData withPath:(NSString *)path;


//saving and appending data at the root level
//- (BOOL)saveData:(NSData *)someData fileName:(NSString *)fileName;
//- (BOOL)appendData:(NSData *)someData fileName:(NSString *)fileName;
//- (BOOL)saveString:(NSString *)aString fileName:(NSString *)fileName;
//- (BOOL)appendString:(NSString *)aString fileName:(NSString *)fileName;

/*
 Log levels:
 * 0 = normally not used
 * 1 = timestamps on job submissions, results and failures
 * 2 = syntax errors in the input files, paths mising,..
 * 3 = timestamps on low level operations (start/end parse, ...)
 * 4 = full description of all parsing steps and results
*/

//logging
- (void)logString:(NSString *)message;
- (void)logLevel:(unsigned int)level string:(NSString *)message;
- (void)logLevel:(unsigned int)level format:(NSString *)format, ...;

@end
