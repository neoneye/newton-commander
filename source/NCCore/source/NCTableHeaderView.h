//
//  NCTableHeaderView.h
//  cocoa_clickable_headercell
//
//  Created by Simon Strandgaard on 04/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol NCTableHeaderViewDelegate <NSObject>

-(NSMenu*)menuForHeaderEvent:(NSEvent*)event;

@end


@interface NCTableHeaderView : NSTableHeaderView
@property(unsafe_unretained) NSObject <NCTableHeaderViewDelegate> *delegate;

@end
