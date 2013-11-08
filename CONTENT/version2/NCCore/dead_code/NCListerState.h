/*
TODO: remove the NCListerState class it's no longer used
*/
//
//  NCListerState.h
//  NCCore
//
//  Created by Simon Strandgaard on 29/03/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NCListerState : NSObject <NSCoding> {
	NSString* m_working_dir;

}
@property (copy) NSString* workingDir;

@end
