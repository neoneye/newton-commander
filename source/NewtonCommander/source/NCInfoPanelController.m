//
//  NCInfoPanelController.m
//  Newton Commander
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NCLog.h"
#import "NCInfoPanelController.h"
#import "NCInfoView.h"


@implementation NCInfoPanelController

- (void)awakeFromNib
{
	LOG_DEBUG(@"info: %@", self.infoView);

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
