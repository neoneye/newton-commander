//
//  CMPrintHierarchy.m
//  worker
//
//  Created by Simon Strandgaard on 22/05/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import "CMPrintHierarchy.h"


@implementation CMPrintHierarchy

@synthesize result = m_result;
@synthesize indent = m_indent;

-(id)init {
	self = [super init];
    if(self) {
		self.result = [NSMutableString stringWithCapacity:10000];
		self.indent = @"    ";
    }
    return self;
}

/*
TODO: dealloc
*/

-(void)visitDir:(CMTraversalObjectDir*)obj {
	[m_result appendFormat:@"[DIR     ] %@%@\n", self.indent, obj.path];
	NSString* orig_indent = self.indent;
	self.indent = [self.indent stringByAppendingString:@"  "];
	for(CMTraversalObject* child_obj in obj.childTraversalObjects) {
		[child_obj accept:self];
	}
	self.indent = orig_indent;
}

-(void)visitFile:(CMTraversalObjectFile*)obj {
	[m_result appendFormat:@"[FILE    ] %@%@\n", self.indent, obj.path];
}
-(void)visitHardlink:(CMTraversalObjectHardlink*)obj {
	[m_result appendFormat:@"[HARDLINK] %@%@\n", self.indent, obj.path];
}
-(void)visitSymlink:(CMTraversalObjectSymlink*)obj {
	[m_result appendFormat:@"[SYMLINK ] %@%@\n", self.indent, obj.path];
}
-(void)visitFifo:(CMTraversalObjectFifo*)obj {
	[m_result appendFormat:@"[FIFO    ] %@%@\n", self.indent, obj.path];
}
-(void)visitChar:(CMTraversalObjectChar*)obj {
	[m_result appendFormat:@"[CHAR    ] %@%@\n", self.indent, obj.path];
}
-(void)visitBlock:(CMTraversalObjectBlock*)obj {
	[m_result appendFormat:@"[BLOCK   ] %@%@\n", self.indent, obj.path];
}
-(void)visitOther:(CMTraversalObjectOther*)obj {
	[m_result appendFormat:@"[OTHER   ] %@%@\n", self.indent, obj.path];
}

@end
