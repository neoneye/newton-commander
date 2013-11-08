/*********************************************************************
KCReportStatistics.mm - Statistics for the ReportApp

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#include "KCReportStatistics.h"


@implementation KCReportStatItem

- (id)init {
    self = [super init];
	if(self) {
		timestamp = nil;
		path = nil;
		message = nil;
		time0 = 0;
		time1 = 0;
		time2 = 0;
	}
    return self;
}

-(void)setTimestamp:(NSString*)v { v = [v copy]; [timestamp release]; timestamp = v; }
-(NSString*)timestamp { return timestamp; }

-(void)setPath:(NSString*)v { v = [v copy]; [path release]; path = v; }
-(NSString*)path { return path; }

-(void)setMessage:(NSString*)v { v = [v copy]; [message release]; message = v; }
-(NSString*)message { return message; }

-(void)setTime0:(float)v { time0 = v; }
-(float)time0 { return time0; }

-(void)setTime1:(float)v { time1 = v; }
-(float)time1 { return time1; }

-(void)setTime2:(float)v { time2 = v; }
-(float)time2 { return time2; }

-(void)dealloc {
	[timestamp release];
	[path release];
	[message release];
    [super dealloc];
}

@end
