//
//  XGSToolbarController.m
//  GridStuffer
//
//  Created by Charles Parnot on 7/3/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

/*
 This file is part of GridStuffer.
 GridStuffer is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
 GridStuffer is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with GridStuffer; if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

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
