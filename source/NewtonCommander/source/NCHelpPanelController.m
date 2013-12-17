//
//  NCHelpPanelController.m
//  NewtonCommander
//
//  Created by Simon Strandgaard on 02/08/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NCLog.h"
#import "NCHelpPanelController.h"                  
#import "NCHelpView.h"
#import "NCListPanelController.h"


@implementation NCHelpPanelController

- (void)awakeFromNib
{
	// LOG_DEBUG(@"info: %@", m_info_view);

}

-(void)showInfo {
	/*
	[m_info_view bind: @"path" toObject: m_opposite_side_controller
		   withKeyPath:@"selection.path" options:nil];
		
	*/
}

-(void)hideInfo {
	/*
	[m_info_view unbind: @"path"];
	*/
}

-(void)gatherInfo:(NCListPanelController*)listPanel {
	NSString* name = [listPanel currentName];
	LOG_DEBUG(@"gatherInfo for name: %@", name);

	NSArray* keys = [NSArray arrayWithObjects:@"name", nil];
	NSArray* objects = [NSArray arrayWithObjects:name, nil];
	NSDictionary* dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];	
	
	[self.infoView setDict:dict];
}

@end
