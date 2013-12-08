//
//  NCVolumeStatus.h
//  NCCore
//
//  Created by Simon Strandgaard on 04/08/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NCVolumeStatus : NSView {
	BOOL _active;
	unsigned long long _capacity;
	unsigned long long _available;
}
@property (nonatomic) unsigned long long capacity;
@property (nonatomic) unsigned long long available;

-(void)activate;
-(void)deactivate;

@end
