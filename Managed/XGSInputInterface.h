//
//  XGSInputInterface.h
//  GridStuffer
//
//  Created by Charles Parnot on 5/14/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//

/*
 This file is part of GridStuffer.
 GridStuffer is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
 GridStuffer is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with GridStuffer; if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */


@interface XGSInputInterface : XGSManagedObject
{
	NSArray *lines;
}

//- (void)setInputFilePath:(NSString *)path;
- (NSString *)lineAtIndex:(unsigned int)index;
- (void)loadFile;

- (NSString *)filePath;
- (void)setFilePath:(NSString *)filePathNew;

@end
