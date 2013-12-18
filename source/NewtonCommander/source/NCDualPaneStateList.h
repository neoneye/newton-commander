//
//  NCDualPaneStateList.h
//  Newton Commander
//
#import "NCDualPaneState.h"


@class NCListPanelController;

@interface NCDualPaneStateList : NCDualPaneState {
	NCSide m_side;
}
@property(readonly, assign) NCSide side;

- (id)initWithSide:(NCSide)side;

@end
