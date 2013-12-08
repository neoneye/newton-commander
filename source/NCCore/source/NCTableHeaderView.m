//
//  NCTableHeaderView.m
//  cocoa_clickable_headercell
//
//  Created by Simon Strandgaard on 04/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NCTableHeaderView.h"


@implementation NCTableHeaderView

@synthesize delegate = m_delegate;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		// LOG_DEBUG(@"NCTableHeaderView %s", _cmd);
    }
    return self;
} 

-(NSMenu*)menuForEvent:(NSEvent*)event {

	id obj = m_delegate;
	SEL sel = @selector(menuForHeaderEvent:);
	if([obj respondsToSelector:sel]) {
		// LOG_DEBUG(@"%s calling menuForHeaderEvent:", _cmd);
		return [obj performSelector:sel withObject:event];
	}

	// LOG_DEBUG(@"%s", _cmd);
	return [super menuForEvent:event];
}

/*- (NSMenu *)menu {
	LOG_DEBUG(@"%s", _cmd);
	return [super menu];
}*/

@end
