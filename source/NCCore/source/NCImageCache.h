//
//  NCImageCache.h
//  NCCore
//
//  Created by Simon Strandgaard on 25/08/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NCImageCache : NSObject {
	NSMutableDictionary* m_dict;
}
@property (strong) NSMutableDictionary* dict;

-(NSImage*)imageForTag:(int)tag;
-(void)setImage:(NSImage*)image forTag:(int)tag;

@end
