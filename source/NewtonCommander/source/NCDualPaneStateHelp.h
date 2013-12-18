//
//  NCDualPaneStateHelp.h
//  Newton Commander
//
#import "NCDualPaneState.h"


@interface NCDualPaneStateHelp : NCDualPaneState {
	NCSide m_side;
}
@property (readonly, assign) NCSide side;

- (id)initWithSide:(NCSide)side;

@end
