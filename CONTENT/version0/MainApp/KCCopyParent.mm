/*********************************************************************
KCCopyParent.mm - acts as Parent for the Copy.app

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#include "KCCopyParent.h"

@implementation KCCopyParent

-(id)init {
	self = [super init];
    if(self) {
		m_delegate = nil;
    }
    return self;
}

-(void)setDelegate:(id)delegate { m_delegate = delegate; }
-(id)delegate { return m_delegate; }

-(oneway void)parentWeAreRunning:(in bycopy NSString*)name {
	if([m_delegate respondsToSelector:@selector(parentWeAreRunning:)]) {
		[m_delegate parentWeAreRunning:name];
	}
}

-(oneway void)parentResponse:(in bycopy NSDictionary*)response {
	// NSLog(@"KCCopyParent %s %@", _cmd, response);
	if([m_delegate respondsToSelector:@selector(parentResponse:)]) {
		[m_delegate parentResponse:response];
	}
}

-(oneway void)parentError:(in bycopy NSDictionary*)errorinfo {
	if([m_delegate respondsToSelector:@selector(parentError:)]) {
		[m_delegate parentError:errorinfo];
	}
}

@end
