//
//  XGSToolbarController.m
//  GridStuffer
//
//  Created by Charles Parnot on 7/3/05.
//  Copyright 2005, 2006, 2007, 2008 _Charles Parnot_. All rights reserved.
//

/* GRIDSTUFFER_LICENSE_START */
/* This file is part of GridStuffer. GridStuffer is free software; you can redistribute it and/or modify it under the terms of the Berkeley Software Distribution (BSD) Modified License.*/
/* Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the owner Charles Parnot nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */
/* GRIDSTUFFER_LICENSE_END */

#import "XGSToolbarController.h"

@implementation XGSToolbarController

- (id)initWithToolbarDescriptionFile:(NSString *)plistFileNameInBundle
{
	self = [super init];
	
	if (self != nil) {
		
		toolbarDescriptionFile = [plistFileNameInBundle retain];
		
		NSString *identifier = [NSString stringWithFormat:@"parnot.charles.gridstuffer.toolbar.%@",plistFileNameInBundle];
		toolbar = [(NSToolbar *)[NSToolbar alloc] initWithIdentifier:identifier];
		
		[toolbar setAllowsUserCustomization:YES];
		[toolbar setAutosavesConfiguration:YES];
		[toolbar setSizeMode:NSToolbarSizeModeSmall];
		[toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
		[toolbar setDelegate:self];
	}
	
	return self;
}

- (void)dealloc
{
	[toolbarDescriptionFile release];
	[toolbar release];
	[super dealloc];
}

- (NSToolbar *)toolbar
{
	return toolbar;
}

#pragma mark *** NSToolbar delegate methods ***

static NSDictionary *toolbarDescription = nil;

- (NSDictionary *)toolbarDescription
{
	if ( toolbarDescription == nil ) {
		NSBundle *myBundle = [NSBundle mainBundle];
		NSString *path = [myBundle pathForResource:toolbarDescriptionFile ofType:@"plist"];
		toolbarDescription = [[NSDictionary alloc] initWithContentsOfFile:path];
	}
	return toolbarDescription;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	NSArray *myItems = [[self toolbarDescription] allKeys];
	myItems = [myItems sortedArrayUsingSelector:@selector(compare:)];
	NSMutableArray *defaultItems = [NSMutableArray array];
	//[defaultItems addObject:NSToolbarFlexibleSpaceItemIdentifier];
	[defaultItems addObjectsFromArray:myItems];
	//[defaultItems addObject:NSToolbarFlexibleSpaceItemIdentifier];
	return [NSArray arrayWithArray:defaultItems];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	NSMutableArray *allowedItems = [NSMutableArray arrayWithObjects:
		NSToolbarSeparatorItemIdentifier,
		NSToolbarSpaceItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier,
        NSToolbarCustomizeToolbarItemIdentifier,
        nil];
	[allowedItems addObjectsFromArray:[[self toolbarDescription] allKeys]];
	return [NSArray arrayWithArray:allowedItems];
}

- (NSToolbarItem*)toolbar:(NSToolbar*)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)willBeInsertedIntoToolbar
{
	//retrieve the dictionary for the item
	NSDictionary *allItems = [self toolbarDescription];
	NSDictionary *toolbarItemInfo = [allItems objectForKey:itemIdentifier];
	if ( toolbarItemInfo == nil )
		return nil;
	
	//prepare the NSToolbarItem
	NSToolbarItem *item;
	item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	[item setPaletteLabel:[toolbarItemInfo objectForKey:@"Label"]];
	[item setLabel:[toolbarItemInfo objectForKey:@"Label"]];
	[item setImage:[NSImage imageNamed:[toolbarItemInfo objectForKey:@"ImageName"]]];
	[item setAction:NSSelectorFromString([toolbarItemInfo objectForKey:@"Action"])];
	[item setToolTip:[toolbarItemInfo objectForKey:@"ToolTip"]];
	
    return [item autorelease];
}

@end
