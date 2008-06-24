//
//  XGSPathUtilities.h
//  GridStuffer
//
//  Created by Charles Parnot on 2/22/07.
//  Copyright 2005, 2006, 2007, 2008 Charles Parnot. All rights reserved.

/* GRIDSTUFFER_LICENSE_START */
/* This file is part of GridStuffer. GridStuffer is free software; you can redistribute it and/or modify it under the terms of the Berkeley Software Distribution (BSD) Modified License.*/
/* Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the owner Charles Parnot nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */
/* GRIDSTUFFER_LICENSE_END */


#import <Cocoa/Cocoa.h>


/* Not really Objective C, but oh well*/


BOOL CreateDirectory(NSString *aPath);
NSString *UniqueNameWithPath(NSString *path, unsigned int *suffix);



/*
@interface XGSPathUtilities : NSObject {

}

@end
*/