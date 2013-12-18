//
//  NCDualPaneState.h
//  NewtonCommander
//
//  Created by Simon Strandgaard on 18/02/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


typedef NSUInteger NCSide;
enum {
	NCSideLeft=0,
	NCSideRight,
};


@class NCDualPane;

@interface NCDualPaneState : NSResponder

@property(nonatomic, weak) NCDualPane* dualPane;

-(void)changeState:(NCDualPaneState*)newState;

-(void)tabKeyPressed:(id)sender;

// YES if the left panel is a lister panel that is active
-(BOOL)leftActive;

// YES if the right panel is a lister panel that is active
-(BOOL)rightActive;

-(NSString*)identifier;

@end
