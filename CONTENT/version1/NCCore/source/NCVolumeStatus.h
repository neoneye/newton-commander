//
//  NCVolumeStatus.h
//  NCCore
//
//  Created by Simon Strandgaard on 04/08/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NCVolumeStatus : NSView {
	unsigned long long m_capacity;
	unsigned long long m_available;
	BOOL m_active;
}
@property unsigned long long capacity;
@property unsigned long long available;

-(void)activate;
-(void)deactivate;

@end
