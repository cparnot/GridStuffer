//
//  XGSOutputInterface.h
//  GridStuffer
//
//  Created by Charles Parnot on 5/14/05.
//  Copyright 2005, 2006, 2007, 2008 Charles Parnot. All rights reserved.
//

/* GRIDSTUFFER_LICENSE_START */
/* This file is part of GridStuffer. GridStuffer is free software; you can redistribute it and/or modify it under the terms of the Berkeley Software Distribution (BSD) Modified License.*/
/* Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the owner Charles Parnot nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */
/* GRIDSTUFFER_LICENSE_END */


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

@interface XGSOutputInterface : NSManagedObject
{

}

//accessors
- (NSString *)folderPath;
- (NSString *)logFileName;
- (void)setFolderPath:(NSString *)folderPathNew;
- (void)setLogFileName:(NSString *)logFileNameNew;

//save files using the 'folderPath' as root if 'path' is relative
//the dictionaryRepresentation uses the keys as paths and the values as data
//if ONE of the file already exists at the path, ALL have the SAME number appended to their name, e.g. thefile_1, theotherfile_1.txt,... this way, files that go 'together' have the same suffix
- (BOOL)saveFiles:(NSDictionary *)dictionaryRepresentation inFolder:(NSString *)path;

//same as above, except that
//if ONE of the files already exists at the path, a subfolder will be created with a number (e.g. 'results_1') inside which ALL the files will be saved; this way, files stay "together"
//if the last argument is nil, then it behaves as '-saveFiles:inFolder:'
- (BOOL)saveFiles:(NSDictionary *)dictionaryRepresentation inFolder:(NSString *)path duplicatesInSubfolder:(NSString *)duplicatesPath;


//if the file already exists, a number is appended to it, e.g. thefile.txt, thefile_1.txt, thefile_2.txt,...
- (BOOL)saveData:(NSData *)someData withPath:(NSString *)path;


//saving and appending data at the root level
//- (BOOL)saveData:(NSData *)someData fileName:(NSString *)fileName;
//- (BOOL)appendData:(NSData *)someData fileName:(NSString *)fileName;
//- (BOOL)saveString:(NSString *)aString fileName:(NSString *)fileName;
//- (BOOL)appendString:(NSString *)aString fileName:(NSString *)fileName;


@end
