//
//  NCTableHeaderView.m
//  cocoa_clickable_headercell
//
//  Created by Simon Strandgaard on 04/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NCTableHeaderView.h"


@implementation NCTableHeaderView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		// LOG_DEBUG(@"NCTableHeaderView %s", _cmd);
    }
    return self;
} 

-(NSMenu*)menuForEvent:(NSEvent*)event {

	NSObject <NCTableHeaderViewDelegate> *obj = self.delegate;
	if([obj respondsToSelector:@selector(menuForHeaderEvent:)]) {
		// LOG_DEBUG(@"%s calling menuForHeaderEvent:", _cmd);
		return [obj menuForHeaderEvent:event];
	}

	// LOG_DEBUG(@"%s", _cmd);
	return [super menuForEvent:event];
}

/*- (NSMenu *)menu {
	LOG_DEBUG(@"%s", _cmd);
	return [super menu];
}*/

@end
