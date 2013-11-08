/*********************************************************************
KCReportParent.mm - acts as Parent with the Report.app

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#include "KCReportParent.h"


@interface KCReportParent (Private)
@end

@implementation KCReportParent

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

-(oneway void)parentWeHaveData:(in bycopy NSData*)data forPath:(in bycopy NSString*)path {
	if([m_delegate respondsToSelector:@selector(parentWeHaveData:forPath:)]) {
		[m_delegate parentWeHaveData:data forPath:path];
	}
}

@end
