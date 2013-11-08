/*********************************************************************
KCCopyParent.h - acts as Parent for the Copy.app

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#ifndef __OPCODERS_KEYBOARDCOMMANDER_COPY_PARENT_H__
#define __OPCODERS_KEYBOARDCOMMANDER_COPY_PARENT_H__

#include "../cp_protocol.h"

@interface KCCopyParent : NSObject <CopyParentProtocol> {
	id m_delegate;
}
-(void)setDelegate:(id)delegate;
-(id)delegate;

@end

@interface NSObject (KCCopyParentDelegate)
-(void)parentWeAreRunning:(NSString*)name;
-(void)parentResponse:(NSDictionary*)response;
-(void)parentError:(NSDictionary*)errorinfo;
@end


#endif // __OPCODERS_KEYBOARDCOMMANDER_COPY_PARENT_H__