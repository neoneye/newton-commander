/*********************************************************************
KCReportStatistics.h - Statistics for the ReportApp

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#ifndef __OPCODERS_KEYBOARDCOMMANDER_REPORT_STATISTICS_H__
#define __OPCODERS_KEYBOARDCOMMANDER_REPORT_STATISTICS_H__

@interface KCReportStatItem : NSObject {
	NSString* timestamp;
	NSString* path;
	NSString* message;
	float time0;     
	float time1;
	float time2;
}
-(void)setTimestamp:(NSString*)v;
-(NSString*)timestamp;
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
@end

#endif // __OPCODERS_KEYBOARDCOMMANDER_REPORT_STATISTICS_H__