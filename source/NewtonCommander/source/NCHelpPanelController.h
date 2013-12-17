//
//  NCHelpPanelController.h
//  NewtonCommander
//
//  Created by Simon Strandgaard on 02/08/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NCHelpView;
@class NCListPanelController;

@interface NCHelpPanelController : NSViewController
@property (weak) IBOutlet NCHelpView* infoView;

-(void)gatherInfo:(NCListPanelController*)listPanel;

@end
