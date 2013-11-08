/*********************************************************************
OFMTableView.h - NSTableView with different keybindings

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#ifndef __OPCODERS_ORTHODOXFILEMANAGER_TABLEVIEW_H__
#define __OPCODERS_ORTHODOXFILEMANAGER_TABLEVIEW_H__

void logic_for_page_up1(NSRange range, int row, int rows, int* out_row, int* out_toprow);
void logic_for_page_up2(NSRange range, int row, int rows, int* out_row, int* out_toprow);


void logic_for_page_down1(NSRange range, int row, int rows, int* out_row, int* out_botrow);
void logic_for_page_down2(NSRange range, int row, int rows, int* out_row, int* out_botrow);
void logic_for_page_down3(NSRange range, int row, int rows, int* out_row, int* out_visiblerow);


@interface OFMTableView : NSTableView {
	NSImage* m_background_image;
}
-(void)setBackgroundImage:(NSImage*)image;
@end

#endif // __OPCODERS_ORTHODOXFILEMANAGER_TABLEVIEW_H__