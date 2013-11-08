/*********************************************************************
KCReport.h - encapsulates the background ReportApp in a thread

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#ifndef __OPCODERS_KEYBOARDCOMMANDER_REPORTAPP_WRAPPER_H__
#define __OPCODERS_KEYBOARDCOMMANDER_REPORTAPP_WRAPPER_H__

@class KCReportThread;

@interface KCReport : NSObject {
	NSString* m_name;
	NSString* m_path_to_child_executable;
	id m_delegate;
	
	NSThread* m_thread;
	
	/*
	all method calls for m_report_thread must be made with
	performSelector:onThread:withObject:waitUntilDone:modes:
	*/
	KCReportThread* m_report_thread;
}
-(id)initWithName:(NSString*)name path:(NSString*)path;

-(void)setDelegate:(id)delegate;                    
-(id)delegate;

-(void)start;

-(void)requestPath:(NSString*)path;


@end

@interface NSObject (KCReportDelegate)
-(void)reportDidLaunch;
-(void)reportIsNowProcessingTheRequest;
-(void)reportHasData:(NSData*)data;
@end


#endif // __OPCODERS_KEYBOARDCOMMANDER_REPORTAPP_WRAPPER_H__