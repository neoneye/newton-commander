/*********************************************************************
JFPermissionInfoCell.h - experimental posix permission indicator cell
Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#ifndef __OPCODERS_JUXTAFILE_PERMISSIONINFOCELL_H__
#define __OPCODERS_JUXTAFILE_PERMISSIONINFOCELL_H__

@interface JFPermissionInfoCell : NSCell {
	NSColor* m_colors[9];
	NSUInteger m_permissions;
}
-(void)setPermissions:(NSUInteger)perm;
@end

#endif // __OPCODERS_JUXTAFILE_PERMISSIONINFOCELL_H__