//
//  NCTableHeaderView.h
//  cocoa_clickable_headercell
//
//  Created by Simon Strandgaard on 04/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NCTableHeaderView : NSTableHeaderView {
	id m_delegate;
}
@property(assign) id delegate;

@end


@interface NSObject (NCTableHeaderViewDelegate)

-(NSMenu*)menuForHeaderEvent:(NSEvent*)event;

@end
