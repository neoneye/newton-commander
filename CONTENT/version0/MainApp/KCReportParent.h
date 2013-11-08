/*********************************************************************
KCReportParent.h - acts as Parent with the Report.app

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#ifndef __OPCODERS_KEYBOARDCOMMANDER_REPORT_PARENT_H__
#define __OPCODERS_KEYBOARDCOMMANDER_REPORT_PARENT_H__

#include "../re_protocol.h"

@interface KCReportParent : NSObject <ReportParentProtocol> {
	id m_delegate;
}
-(void)setDelegate:(id)delegate;
-(id)delegate;

@end

@interface NSObject (KCReportParentDelegate)
-(void)parentWeAreRunning:(NSString*)name;
-(void)parentWeHaveData:(NSData*)data forPath:(NSString*)path;
@end


#endif // __OPCODERS_KEYBOARDCOMMANDER_REPORT_PARENT_H__