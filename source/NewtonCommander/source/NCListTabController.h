//
//  NCListTabController.h
//  Newton Commander
//

#import <Cocoa/Cocoa.h>
#import "NCPanelControllerDelegate.h"

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
	NCLister* __weak m_lister;
	NCListerCounter* __weak m_lister_counter;
	// NCBackground* m_background;
	NCPathControl* __weak m_path_control;
	NCVolumeStatus* __weak m_volume_status;

	BOOL m_is_left_panel;
	NCListPanelTabModel* m_tab_model;

	NCListerDataSourceAdvanced* m_data_source;
}
@property (weak) NSObject <NCPanelControllerDelegate> *delegate;
@property (weak) IBOutlet NCLister* lister;
@property (weak) IBOutlet NCListerCounter* listerCounter;
// @property (assign) IBOutlet NCBackground* background;
@property (weak) IBOutlet NCPathControl* pathControl;
@property (weak) IBOutlet NCVolumeStatus* volumeStatus;
@property (nonatomic, strong) NCListerDataSourceAdvanced* dataSource;
@property (nonatomic, strong) NCListPanelTabModel* tabModel;

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
