//
//  NCDualPaneState.m
//  NewtonCommander
//
//  Created by Simon Strandgaard on 18/02/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "NCDualPaneState.h"
#import "NCDualPane.h"
#import "NCLog.h"


@implementation NCDualPaneState

@synthesize dualPane = m_dualpane;

-(void)changeState:(NCDualPaneState*)newState {
	[m_dualpane changeState:newState];
}

-(void)tabKeyPressed:(id)sender {
	LOG_DEBUG(@"this method was called, but is not overloaded");
}

// YES if the left panel is a lister panel that is active
-(BOOL)leftActive {
	return NO;
}

// YES if the right panel is a lister panel that is active
-(BOOL)rightActive {
	return NO;
}

-(NSString*)identifier {
	return nil;
}

@end
