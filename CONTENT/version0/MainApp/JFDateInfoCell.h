/*********************************************************************
JFDateInfoCell.h - experimental date span cell
Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#ifndef __OPCODERS_JUXTAFILE_DATEINFOCELL_H__
#define __OPCODERS_JUXTAFILE_DATEINFOCELL_H__

@interface JFDateInfoCell : NSCell {
	BOOL m_hidden;
	int m_error;
	float m_value0;
	float m_value1;      
	float m_value2;
	float m_value3;
	NSColor* m_color_error;
	NSColor* m_color0;
	NSColor* m_color1;
	NSColor* m_color2;
	NSColor* m_color3;
}
-(void)setHidden:(BOOL)v;

// normal when v is 0.
// red when v != 0
-(void)setError:(int)v;

-(void)setValue0:(float)v;
-(void)setValue1:(float)v;
-(void)setValue2:(float)v;
-(void)setValue3:(float)v;
@end

#endif // __OPCODERS_JUXTAFILE_DATEINFOCELL_H__