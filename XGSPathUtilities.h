//
//  XGSPathUtilities.h
//  GridStuffer
//
//  Created by Charles Parnot on 2/22/07.
//  Copyright 2005,2006,2007 Charles Parnot. All rights reserved.

/*
 This file is part of GridStuffer.
 GridStuffer is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
 GridStuffer is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with GridStuffer; if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */


#import <Cocoa/Cocoa.h>


/* Not really Objective C, but oh well*/


BOOL CreateDirectory(NSString *aPath);
NSString *UniqueNameWithPath(NSString *path, unsigned int *suffix);



/*
@interface XGSPathUtilities : NSObject {

}

@end
*/