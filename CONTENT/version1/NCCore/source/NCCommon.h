//
//  NCCommon.h
//  NCCore
//
//  Created by Simon Strandgaard on 18/03/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/*
format bytes with 2 decimals and a suffix, e.g: "123.45 GB" or "42 bytes"
*/
NSString* NCSuffixStringForBytes( unsigned long long bytes );

/*
format bytes as "123 456 789" or "42 003"
*/
NSString* NCSpacedStringForBytes( unsigned long long bytes );


@interface NCCommon : NSObject {

}

@end
