/*********************************************************************
KCDiscoverStatistics.h - Statistics for the DiscoverApp

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#ifndef __OPCODERS_KEYBOARDCOMMANDER_DISCOVER_STATISTICS_H__
#define __OPCODERS_KEYBOARDCOMMANDER_DISCOVER_STATISTICS_H__

@interface KCDiscoverStatItem : NSObject {
	int transaction_id;
	NSString* timestamp;
	NSString* module;
	NSString* path;
	NSString* message;
	float time0;     
	float time1;
	float time2;
	float time3;
	int count;
}
-(void)setTransactionId:(int)tid;
-(int)transactionId;
-(void)setTimestamp:(NSString*)v;
-(NSString*)timestamp;
-(void)setModule:(NSString*)v;
-(NSString*)module;
-(void)setPath:(NSString*)v;
-(NSString*)path;
-(void)setMessage:(NSString*)v;
-(NSString*)message;
-(void)setTime0:(float)v;
-(float)time0;
-(void)setTime1:(float)v;
-(float)time1;
-(void)setTime2:(float)v;
-(float)time2;
-(void)setTime3:(float)v;
-(float)time3;
-(void)setCount:(int)v;
-(int)count;
@end

#endif // __OPCODERS_KEYBOARDCOMMANDER_DISCOVER_STATISTICS_H__