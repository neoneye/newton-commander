//
//  NCListerCell.h
//  NCCore
//
//  Created by Simon Strandgaard on 18/09/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum {
	kNCListerCellDirtyFont        = 1,
	kNCListerCellDirtyColor       = 2,
	kNCListerCellDirtyMarked      = 4,
	kNCListerCellDirtyHighlighted = 8,
	kNCListerCellDirtyAll         = 0xffffffff,
};


@interface NCListerCell : NSTextFieldCell {
	BOOL m_is_marked;

	NSColor* m_text_color_normal_unmarked;
	NSColor* m_text_color_normal_marked;
	NSColor* m_text_color_selected_marked;
	NSColor* m_text_color_selected_unmarked;
	NSColor* m_text_color_alternative;

	BOOL m_anti_alias;
	float m_padding_left;
	float m_padding_right;
	float m_offset_y;
	float m_coretext_offset_y;

	NSUInteger m_dirty_mask;
}
@property NSUInteger dirtyMask;
@property float paddingLeft;
@property float paddingRight;
@property float offsetY;     
@property float coretextOffsetY;

-(void)setIsMarked:(BOOL)value;
-(BOOL)isMarked;

-(void)setAntiAlias:(BOOL)value;
-(BOOL)antiAlias;

-(void)setTextColorNormalUnmarked:(NSColor*)color;
-(NSColor*)textColorNormalUnmarked;
-(void)setTextColorNormalMarked:(NSColor*)color;
-(NSColor*)textColorNormalMarked;
-(void)setTextColorSelectedUnmarked:(NSColor*)color;
-(NSColor*)textColorSelectedUnmarked;
-(void)setTextColorSelectedMarked:(NSColor*)color;
-(NSColor*)textColorSelectedMarked;
-(void)setTextColorAlternative:(NSColor*)color;
-(NSColor*)textColorAlternative;


-(NSColor*)color0;    
-(NSColor*)color1;

-(void)adjustThemeForDictionary:(NSDictionary*)dict;

@end
