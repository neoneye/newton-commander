//
//  NCInfoPanelController.h
//  NewtonCommander
//
//  Created by Simon Strandgaard on 18/02/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NCInfoView;

@interface NCInfoPanelController : NSViewController {
	NCInfoView* m_info_view;
}
@property (assign) IBOutlet NCInfoView* infoView;

@end
