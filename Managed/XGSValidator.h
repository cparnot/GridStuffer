//
//  XGSValidator.h
//  GridStuffer
//
//  Created by Charles Parnot on 6/27/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//


@interface XGSValidator : NSManagedObject
{
	/*
	 BOOL failureIfAllFilesEmpty;
	 BOOL failureIfNoFile;
	 BOOL failureIfNothing;
	 BOOL failureIfOneFileEmpty;
	 BOOL failureIfStderrEmpty;
	 BOOL failureIfStderrNonEmpty;
	 BOOL failureIfStdoutEmpty;
	 BOOL failureIfStdoutNonEmpty;
	 */
}

- (BOOL)validateFiles:(NSDictionary *)dictionaryRepresentation standardOutput:(NSData *)stdoutData standardError:(NSData *)stderrData;

- (BOOL)failureIfAllFilesEmpty;
- (BOOL)failureIfNoFile;
- (BOOL)failureIfNothing;
- (BOOL)failureIfOneFileEmpty;
- (BOOL)failureIfStderrEmpty;
- (BOOL)failureIfStderrNonEmpty;
- (BOOL)failureIfStdoutEmpty;
- (BOOL)failureIfStdoutNonEmpty;

@end
