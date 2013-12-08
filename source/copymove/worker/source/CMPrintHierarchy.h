//
//  CMPrintHierarchy.h
//  worker
//
//  Created by Simon Strandgaard on 22/05/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CMTraversalObject.h"


@interface CMPrintHierarchy : NSObject <CMTraversalObjectVisitor> {
	NSMutableString* m_result;
	NSString* m_indent;
}
@property (nonatomic, retain) NSMutableString* result;
@property (nonatomic, retain) NSString* indent;

@end
