//
//  NSView+SubviewExtensions.h
//  NCCore
//
//  Created by Simon Strandgaard on 25/04/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSView (SubviewExtensions)

/*
add subview so it fits within the our frame
*/
-(void)addResizedSubview:(NSView*)aView;

/*
replace zero or more subviews with the provided view
*/
-(void)replaceSubviewsWithView:(NSView*)aView;

@end
