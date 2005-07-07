//
//  XGSIntegerArray.h
//  GridStuffer
//
//  Created by Charles Parnot on 5/12/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//



@interface XGSIntegerArray : XGSManagedObject
{
	NSMutableData *integerArrayMutableData;
}

- (int)intValueAtIndex:(unsigned int)index;
- (void)setIntValue:(int)newInt AtIndex:(unsigned int)index;
- (int)incrementIntValueAtIndex:(unsigned int)index;
- (int)decrementIntValueAtIndex:(unsigned int)index;
- (NSString *)stringRepresentation;

@end
