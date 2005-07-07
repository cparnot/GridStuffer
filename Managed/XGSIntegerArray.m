//
//  XGSIntegerArray.m
//  GridStuffer
//
//  Created by Charles Parnot on 5/12/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//

#import "XGSIntegerArray.h"

#define SIZE_INCREMENT 100

@implementation XGSIntegerArray

#pragma mark *** Initializations ***

- (NSString *)shortDescription
{
	return [NSString stringWithFormat:@"<%@:%p> (size: %d)",[self class],self,(long)([integerArrayMutableData length]/sizeof(int))];
}

- (void)awakeFromInsert
{
	[super awakeFromInsert];
	[self setValue:[NSData data] forKey:@"data"];
	integerArrayMutableData = [[NSMutableData alloc] initWithLength:SIZE_INCREMENT*sizeof(int)];
}

- (void)awakeFromFetch
{
	[super awakeFromFetch];
	NSLog (@"IntegerArray:\n%@",[self stringRepresentation]);
}


- (void)willSave
{
	if (integerArrayMutableData != nil)
		[self setPrimitiveValue:[NSData dataWithData:integerArrayMutableData] forKey:@"data"];
	NSLog (@"IntegerArray:\n%@",[self stringRepresentation]);
    [super willSave];
} 

- (void)dealloc
{
	[self willSave];
	[integerArrayMutableData release];
	[super dealloc];
}

#pragma mark *** integer array manipulations ***

- (NSMutableData *)integerArrayMutableData
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	if ( integerArrayMutableData == nil ) {
		NSData *data = [self valueForKey:@"data"];
		if ( [data length] != 0)
			integerArrayMutableData = [[NSMutableData alloc] initWithData:data];
		else
			integerArrayMutableData = [[NSMutableData alloc] initWithLength:SIZE_INCREMENT*sizeof(int)];
	}
	return integerArrayMutableData;
}

- (unsigned int)size
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	return ( [[self integerArrayMutableData] length] / sizeof(int) );
}

- (void)setSize:(unsigned int)newSize
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	unsigned int oldSize,count;
	
	oldSize=[self size];
	if ( newSize > oldSize ) {
		count= (newSize-oldSize) * sizeof(int) + SIZE_INCREMENT;
		[[self integerArrayMutableData] increaseLengthBy:count];
	}
}

- (int *)arrayOfInt
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	return (int *)[[self integerArrayMutableData] mutableBytes];
}

- (int)intValueAtIndex:(unsigned int)index
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	if ( index >= [self size] )
		return 0;
	else
		return [self arrayOfInt][index];
}

- (void)setIntValue:(int)newInt AtIndex:(unsigned int)index
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	[self willChangeValueForKey:@"data"];
	[self setSize:index+1];
	[self arrayOfInt][index]=newInt;
	[self didChangeValueForKey:@"data"];
}

- (int)incrementIntValueAtIndex:(unsigned int)index
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	int *intArray;
	[self willChangeValueForKey:@"data"];
	[self setSize:index+1];
	intArray=[self arrayOfInt];
	intArray[index]++;
	[self didChangeValueForKey:@"data"];
	return intArray[index];
}

- (int)decrementIntValueAtIndex:(unsigned int)index
{
	DLog(NSStringFromClass([self class]),15,@"[%@:%p %s] - %@",[self class],self,_cmd,[self shortDescription]);
	int *intArray;
	[self willChangeValueForKey:@"data"];
	[self setSize:index+1];
	intArray=[self arrayOfInt];
	intArray[index]--;
	[self didChangeValueForKey:@"data"];
	return intArray[index];
}

- (NSString *)stringRepresentation
{
	int i,n;
	NSMutableString *result;
	int *intArray;

	n=[self size];
	intArray=[self arrayOfInt];
	result=[NSMutableString stringWithCapacity:n*10];
	for (i=0;i<n-1;i++)
		[result appendFormat:@"%d\t",intArray[i]];
	[result appendFormat:@"%d",intArray[n-1]];
	
	return result;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@:@p> (size:%d)",[self class],self,[self size]];
}


@end
