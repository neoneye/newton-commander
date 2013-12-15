//
//  LayoutView.m
//  Layouter
//
//  Created by Simon Strandgaard on 6/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

/*

IDEA: -(void)setGap:(int)pixels
IDEA: -(void)setPadding:(int)pixels
IDEA: -(void)setAlign:(int)align;  // left, center, right, both
*/

#import "VerticalLayoutView.h"


@interface VerticalLayoutView ()
-(void)adjustSubviews;
@end

@implementation VerticalLayoutView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		for(NSInteger i=0; i<kVerticalLayoutViewCapacity; i++) {
			m_height_array[i] = 100;
		}
		
		m_flexible_view = nil;
    }
    return self;
}


-(void)setHeight:(float)value forIndex:(NSInteger)index {
	if((index >= 0) && (index < kVerticalLayoutViewCapacity)) {
		m_height_array[index] = value;
		[self adjustSubviews];
	}
}

-(float)heightForIndex:(NSInteger)index {
	if((index >= 0) && (index < kVerticalLayoutViewCapacity)) {
		return m_height_array[index];
	}
	return 0;
}

-(void)setFlexibleView:(NSView*)view {
	m_flexible_view = view;  // NOTE: we assign. We don't retain, because we only need this for pointer comparison
	[self adjustSubviews];
}


- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
	[self adjustSubviews];
}

-(void)didAddSubview:(NSView *)subview {
	[self adjustSubviews];
}

-(void)adjustSubviews {	
	
	NSRect bounds = self.bounds;
	
	NSArray* views = [self subviews];
	int n = [views count];
	if(n < 1) {
		return;
	}
	NSParameterAssert(n < kVerticalLayoutViewCapacity);

	float sum_top = 0;
	float sum_bottom = 0;
	
	NSView* found_flexible_view = nil;

	// layout top views
	{
		for(int i=0; i<n; i++) {
			id obj = [views objectAtIndex:i];
			float height = m_height_array[i];
		
			if(![obj isKindOfClass:[NSView class]]) continue;
			NSView* view = (NSView*)obj;
		
			if(view == m_flexible_view) {
				found_flexible_view = view;
				break;
			}
		
			sum_top += height;
			view.frame = NSMakeRect(NSMinX(bounds), NSHeight(bounds) - sum_top, NSWidth(bounds), height);
		}
	}
    
	// layout bottom views
	{
		for(int i=0; i<n; i++) {
			int j = n - i - 1;
			id obj = [views objectAtIndex:j];
			float height = m_height_array[j];
		
			if(![obj isKindOfClass:[NSView class]]) continue;
			NSView* view = (NSView*)obj;
		
			if(view == m_flexible_view) {
				break;
			}
		
			view.frame = NSMakeRect(NSMinX(bounds), sum_bottom, NSWidth(bounds), height);
			sum_bottom += height;
		}
	}
	
	if(found_flexible_view) {
		found_flexible_view.frame = NSMakeRect(NSMinX(bounds), sum_bottom, NSWidth(bounds), NSHeight(bounds) - sum_bottom - sum_top);
	}
    
}

@end
