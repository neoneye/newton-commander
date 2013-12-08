//
//  NSArray+PrependPath.h
//  NCCore
//
//  Created by Simon Strandgaard on 17/05/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSArray (NCPrependPath)

-(NSArray*)prependPath:(NSString*)path;

@end
