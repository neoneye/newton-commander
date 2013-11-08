//
//  LayoutView.h
//  Layouter
//
//  Created by Simon Strandgaard on 6/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define kVerticalLayoutViewCapacity 10

@interface VerticalLayoutView : NSView {
@private
	float m_height_array[kVerticalLayoutViewCapacity];
	NSView* m_flexible_view;
}

-(void)setHeight:(float)value forIndex:(NSInteger)index;
-(float)heightForIndex:(NSInteger)index;
-(void)setFlexibleView:(NSView*)view;

@end
