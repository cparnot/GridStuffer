//
//  XGSInputInterface.h
//  GridStuffer
//
//  Created by Charles Parnot on 5/14/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//




@interface XGSInputInterface : XGSManagedObject
{
	NSArray *lines;
}

//- (void)setInputFilePath:(NSString *)path;
- (NSString *)lineAtIndex:(unsigned int)index;
- (void)loadFile;

@end
