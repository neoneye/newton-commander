//
//  NCInfoPanelController.m
//  NewtonCommander
//
//  Created by Simon Strandgaard on 18/02/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "NCLog.h"
#import "NCInfoPanelController.h"
#import "NCInfoView.h"


@implementation NCInfoPanelController

@synthesize infoView = m_info_view;

- (void)awakeFromNib
{
	LOG_DEBUG(@"info: %@", m_info_view);

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

@end
