//
//  NCListerCell.m
//  NCCore
//
//  Created by Simon Strandgaard on 18/09/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NCListerCell.h"



#define ASSIGN_COLOR(ivar, value) \
	do { \
		if(value != ivar) { \
			m_dirty_mask |= kNCListerCellDirtyColor; \
			ivar = value; \
		} \
	} while(0);



@implementation NCListerCell

@synthesize dirtyMask = m_dirty_mask;
@synthesize paddingLeft = m_padding_left;
@synthesize paddingRight = m_padding_right;
@synthesize offsetY = m_offset_y;
@synthesize coretextOffsetY = m_coretext_offset_y;

-(id)init {
    if ((self = [super init])) {
		m_dirty_mask = kNCListerCellDirtyAll;
    }
    return self;
}

-(id)copyWithZone:(NSZone*)zone {
    NCListerCell* cell = (NCListerCell*)[super copyWithZone:zone];
    cell->m_is_marked = m_is_marked;
	
	cell.textColorNormalUnmarked = self.textColorNormalUnmarked; 
	cell.textColorNormalMarked = self.textColorNormalMarked; 
	cell.textColorSelectedUnmarked = self.textColorSelectedUnmarked; 
	cell.textColorSelectedMarked = self.textColorSelectedMarked; 
	cell.textColorAlternative = self.textColorAlternative;
	cell->m_anti_alias = m_anti_alias;
	cell->m_padding_left = m_padding_left;
	cell->m_padding_right = m_padding_right;
	cell->m_offset_y = m_offset_y;   
	cell->m_coretext_offset_y = m_coretext_offset_y;
	cell->m_dirty_mask = kNCListerCellDirtyAll;

    return cell;
}

-(void)setIsMarked:(BOOL)value {
	if(value != m_is_marked) {
		m_dirty_mask |= kNCListerCellDirtyMarked;
		m_is_marked = value;
	}
}

-(BOOL)isMarked {
	return m_is_marked;
}

- (void)setHighlighted:(BOOL)flag {
	BOOL is_highlighted = [self isHighlighted];
	if(flag != is_highlighted) {
		m_dirty_mask |= kNCListerCellDirtyHighlighted;
		[super setHighlighted:flag];
	}
}

-(void)setFont:(NSFont*)fontObj {
	NSFont* font = [self font];
	if(fontObj != font) {
		m_dirty_mask |= kNCListerCellDirtyFont;
		[super setFont:fontObj];
	}
}

-(void)setAntiAlias:(BOOL)value {
	if(value != m_anti_alias) {
		m_dirty_mask |= kNCListerCellDirtyFont;
		m_anti_alias = value;
	}
}

-(BOOL)antiAlias {
	return m_anti_alias;
}

-(void)setTextColorNormalUnmarked:(NSColor*)color {
	ASSIGN_COLOR(m_text_color_normal_unmarked, color);
}

-(NSColor*)textColorNormalUnmarked {
	return m_text_color_normal_unmarked;
}

-(void)setTextColorNormalMarked:(NSColor*)color {
	ASSIGN_COLOR(m_text_color_normal_marked, color);
}

-(NSColor*)textColorNormalMarked {
	return m_text_color_normal_marked;
}

-(void)setTextColorSelectedUnmarked:(NSColor*)color {                      
	ASSIGN_COLOR(m_text_color_selected_unmarked, color);
}

-(NSColor*)textColorSelectedUnmarked {
	return m_text_color_selected_unmarked;
}

-(void)setTextColorSelectedMarked:(NSColor*)color {
	ASSIGN_COLOR(m_text_color_selected_marked, color);
}

-(NSColor*)textColorSelectedMarked {
	return m_text_color_selected_marked;
}

-(void)setTextColorAlternative:(NSColor*)color {
	ASSIGN_COLOR(m_text_color_alternative, color);
}

-(NSColor*)textColorAlternative {
	return m_text_color_alternative;
}

-(NSColor*)color0 {
	BOOL is_highlighted = [self isHighlighted];
	BOOL is_marked = [self isMarked];
	if(is_highlighted) {
		if(is_marked) {               
 			return self.textColorSelectedMarked;
		} else {
			return self.textColorSelectedUnmarked;
		}
	} else {
		if(is_marked) {
			return self.textColorNormalMarked;
		} else {
			return self.textColorNormalUnmarked;
		}
	}
}

-(NSColor*)color1 { return self.textColorAlternative; }

-(void)adjustThemeForDictionary:(NSDictionary*)dict {
	[self setFont:[dict objectForKey:@"font"]];
	self.textColorNormalUnmarked = [dict objectForKey:@"textColorNormalUnmarked"]; 
	self.textColorNormalMarked = [dict objectForKey:@"textColorNormalMarked"]; 
	self.textColorSelectedUnmarked = [dict objectForKey:@"textColorSelectedUnmarked"]; 
	self.textColorSelectedMarked = [dict objectForKey:@"textColorSelectedMarked"]; 
	self.textColorAlternative = [dict objectForKey:@"textColorAlternative"]; 
	self.antiAlias = [[dict objectForKey:@"antiAlias"] boolValue]; 
	self.paddingLeft = [[dict objectForKey:@"paddingLeft"] floatValue]; 
	self.paddingRight = [[dict objectForKey:@"paddingRight"] floatValue]; 
	self.offsetY = [[dict objectForKey:@"offsetY"] floatValue];
	self.coretextOffsetY = [[dict objectForKey:@"coretextOffsetY"] floatValue];
}

- (NSRect)expansionFrameWithFrame:(NSRect)cellFrame inView:(NSView *)view {
	return NSZeroRect;
}

@end
