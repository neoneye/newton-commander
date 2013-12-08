//
//  NCTableHeaderCell.h
//  cocoa_clickable_headercell
//
//  Created by Simon Strandgaard on 01/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NCTableHeaderCell : NSTextFieldCell {
	NSGradient* m_gradient;
	NSGradient* m_pressed_gradient;
	NSGradient* m_selected_gradient;
	NSGradient* m_selected_pressed_gradient;

	BOOL m_padding_cell;
	
	int m_sort_indicator;
}
@property(nonatomic, retain) NSGradient* gradient;
@property(nonatomic, retain) NSGradient* pressedGradient;
@property(nonatomic, retain) NSGradient* selectedGradient;
@property(nonatomic, retain) NSGradient* selectedPressedGradient;

// -1 = descending, 0 = none, 1 = ascending
@property(nonatomic) int sortIndicator;
@property(nonatomic) BOOL paddingCell;

@end
