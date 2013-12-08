//
//  NCDualPaneStateHelp.h
//  NewtonCommander
//
//  Created by Simon Strandgaard on 02/08/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "NCDualPaneState.h"


@interface NCDualPaneStateHelp : NCDualPaneState {
	NCSide m_side;
}
@property (readonly, assign) NCSide side;

- (id)initWithSide:(NCSide)side;

@end
