//
//  NCTableCornerView.h
//  cocoa_clickable_headercell
//
//  Created by Simon Strandgaard on 01/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NCTableCornerView : NSView {
	NSGradient* m_fill_gradient;

	id m_menu_target;
	SEL m_menu_action;
}
@property(nonatomic, strong) NSGradient* fillGradient;
@property(nonatomic, strong) id menuTarget;
@property(nonatomic) SEL menuAction;

@end
