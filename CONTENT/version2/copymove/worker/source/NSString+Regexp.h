//
//  NSString+Regexp.h
//  worker
//
//  Created by Simon Strandgaard on 02/06/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (Regexp)

-(BOOL)compareToRegexpArray:(NSArray*)anArray;

@end
