//
//  NCDualPaneState.m
//  Newton Commander
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NCDualPaneState.h"
#import "NCDualPane.h"
#import "NCLog.h"


@implementation NCDualPaneState

-(void)changeState:(NCDualPaneState*)newState {
	[self.dualPane changeState:newState];
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
