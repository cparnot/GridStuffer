//
//  XGSCategories.h
//  GridStuffer
//
//  Created by Charles Parnot on 5/13/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//

/*
	Category on NSScanner to just get the next character
	and move the scanner location one character.
	This is used by XGSParser when scanning command strings
 */
@interface NSScanner (XGS_NSScannerCategory)
- (unichar)XGS_scanNextCharacter;
@end


/*
 This category overwrites NSData description method
 to avoid having very long streams of data displayed during debug
 The category is only loaded #ifdef DEBUG
 */
#ifdef DEBUG
@interface NSData (CLICKNSDataCategory)
- (NSString *)description;
@end
#endif