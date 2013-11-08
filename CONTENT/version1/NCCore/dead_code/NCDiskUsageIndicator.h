//
//  NCDiskUsageIndicator.h
//  NCCore
//
//  Created by Simon Strandgaard on 03/05/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NCDiskUsageIndicator : NSView {
	unsigned long long m_capacity;
	unsigned long long m_available;
}
@property unsigned long long capacity;
@property unsigned long long available;

@end
