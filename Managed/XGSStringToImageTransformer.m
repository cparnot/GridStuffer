//
//  XGSStringToImageTransformer.m
//  GridStuffer
//
//  Created by Charles Parnot on 5/19/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//

#import "XGSStringToImageTransformer.h"


@implementation XGSStringToImageTransformer

+ (Class)transformedValueClass;
{
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation;
{
    return YES;   
}

- (id)transformedValue:(id)value;
{
	NSBundle *myBundle;
	NSImage *result;
	NSString *path;
	result = [NSImage imageNamed:value];
	if (result == nil) {
		myBundle = [NSBundle bundleForClass:[XGSStringToImageTransformer class]];
		path = [myBundle pathForImageResource:value];
		result = [[NSImage alloc] initWithContentsOfFile:path];
		[result setName:value];
	}
	return result;
}

@end
