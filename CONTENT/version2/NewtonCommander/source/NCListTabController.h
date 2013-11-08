//
//  NCListPanelTab.h
//  NewtonCommander
//
//  Created by Simon Strandgaard on 27/06/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "NCLister.h"

@class NCLister;
@class NCListerCounter;
// @class NCBackground;
@class NCTabArray;
@class NCListerDataSourceAdvanced;
@class NCPathControl;
@class NCVolumeStatus;
@class NCListPanelTabModel;
@protocol NCCopyOperationProtocol;
@protocol NCMoveOperationProtocol;

@interface NCListTabController : NSViewController <NCListerDelegate> {
	id m_delegate;
	NCLister* m_lister;                               
	NCListerCounter* m_lister_counter;
	// NCBackground* m_background;
	NCPathControl* m_path_control;
	NCVolumeStatus* m_volume_status;

	BOOL m_is_left_panel;
	NCListPanelTabModel* m_tab_model;

	NCListerDataSourceAdvanced* m_data_source;
}
@property (assign) IBOutlet id delegate;
@property (assign) IBOutlet NCLister* lister;
@property (assign) IBOutlet NCListerCounter* listerCounter;
// @property (assign) IBOutlet NCBackground* background;
@property (assign) IBOutlet NCPathControl* pathControl;
@property (assign) IBOutlet NCVolumeStatus* volumeStatus;
@property (nonatomic, retain) NCListerDataSourceAdvanced* dataSource;
@property (nonatomic, retain) NCListPanelTabModel* tabModel;

- (id)initAsLeftPanel:(BOOL)is_left_panel;

-(void)setIsLeftPanel:(BOOL)is_left_panel;

-(void)activate;
-(void)deactivate;

-(NSString*)workingDir;
-(void)setWorkingDir:(NSString*)s;

-(NSString*)currentName;
-(NSArray*)selectedNamesOrCurrentName;

-(void)reload;

-(void)saveColumnLayout;
-(void)loadColumnLayout;

-(void)enterRenameMode;

-(void)selectAllOrNone;

-(void)switchToUser:(int)user_id;

-(id<NCCopyOperationProtocol>)copyOperation;
-(id<NCMoveOperationProtocol>)moveOperation;

@end
