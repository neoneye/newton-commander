/*********************************************************************
JFSizeInfoCell.h - experimental size indicator cell
Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>

TODO: also show the size of the resource fork

*********************************************************************/
#ifndef __OPCODERS_JUXTAFILE_SIZEINFOCELL_H__
#define __OPCODERS_JUXTAFILE_SIZEINFOCELL_H__

enum JFSizeInfoCellLayout {
	kJFSizeInfoCellLayoutBarLeft = 0,
	kJFSizeInfoCellLayoutBarMiddle,
	kJFSizeInfoCellLayoutBarRight,
	kJFSizeInfoCellLayoutSparkLeft,
	kJFSizeInfoCellLayoutSparkRight,
};

@interface JFSizeInfoCell : NSCell {
	NSColor* m_color;
	uint64_t m_size;
	JFSizeInfoCellLayout m_layout;
}
-(void)setSize:(uint64_t)size;
-(void)setLayout:(JFSizeInfoCellLayout)layout;
@end

#endif // __OPCODERS_JUXTAFILE_SIZEINFOCELL_H__