//
//  NSFileManager+ResourceFork.h
//  worker
//
//  Created by Simon Strandgaard on 22/05/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSFileManager (ResourceFork)

-(NSData*)getResourceForkFromFile:(NSString*)path;
-(void)setResourceFork:(NSData*)data onFile:(NSString*)path;

-(void)copyResourceForkFrom:(NSString*)fromPath to:(NSString*)toPath;

@end
