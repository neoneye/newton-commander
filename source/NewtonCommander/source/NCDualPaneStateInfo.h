//
//  NCDualPaneStateInfo.h
//  Newton Commander
//
#import "NCDualPaneState.h"


@interface NCDualPaneStateInfo : NCDualPaneState {
	NCSide m_side;
}
@property (readonly, assign) NCSide side;

- (id)initWithSide:(NCSide)side;

@end
