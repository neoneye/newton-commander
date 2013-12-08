//
//  NSFileManager+FinderInfo.h
//  worker
//
//  Created by Simon Strandgaard on 22/05/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (FinderInfo)

-(void)copyFinderInfoFrom:(NSString*)fromPath to:(NSString*)toPath;

@end
