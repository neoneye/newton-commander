//
//  NCHelpPanelController.h
//  Newton Commander
//
#import <Cocoa/Cocoa.h>

@class NCHelpView;
@class NCListPanelController;

@interface NCHelpPanelController : NSViewController
@property (weak) IBOutlet NCHelpView* infoView;

-(void)gatherInfo:(NCListPanelController*)listPanel;

@end
