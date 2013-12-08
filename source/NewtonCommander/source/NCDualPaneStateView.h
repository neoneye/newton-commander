//
//  NCDualPaneStateView.h
//  NewtonCommander
//
//  Created by Simon Strandgaard on 18/02/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "NCDualPaneState.h"


@interface NCDualPaneStateView : NCDualPaneState {
	NCSide m_side;
}
@property (readonly, assign) NCSide side;

- (id)initWithSide:(NCSide)side;

@end
