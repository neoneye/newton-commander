//
//  DebugView.h
//  project
//
//  Created by Simon Strandgaard on 09/04/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DebugView : NSView {
    NSInteger m_inset_x;
    NSInteger m_inset_y;
    NSString *m_color_name;
}
@property (assign) NSInteger insetX;
@property (assign) NSInteger insetY;
@property (retain) NSString *colorName;

@end
