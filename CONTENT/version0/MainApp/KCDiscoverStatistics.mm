/*********************************************************************
KCDiscoverStatistics.mm - Statistics for the DiscoverApp

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#include "KCDiscoverStatistics.h"


@implementation KCDiscoverStatItem

- (id)init {
    self = [super init];
	if(self) {
		transaction_id = -1;
		timestamp = nil;
		module = nil;
		path = nil;
		message = nil;
		time0 = 0;
		time1 = 0;
		time2 = 0;
		time3 = 0;
		count = 0;
	}
    return self;
}

-(void)setTransactionId:(int)tid { transaction_id = tid; }
-(int)transactionId { return transaction_id; }

-(void)setTimestamp:(NSString*)v { v = [v copy]; [timestamp release]; timestamp = v; }
-(NSString*)timestamp { return timestamp; }

-(void)setModule:(NSString*)v { v = [v copy]; [module release]; module = v; }
-(NSString*)module { return module; }

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

-(void)setTime3:(float)v { time3 = v; }
-(float)time3 { return time3; }

-(void)setCount:(int)v { count = v; }
-(int)count { return count; }

-(void)dealloc {
	[timestamp release];
	[module release];
	[path release];
	[message release];
    [super dealloc];
}

@end
