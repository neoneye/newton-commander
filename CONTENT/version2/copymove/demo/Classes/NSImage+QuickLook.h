/*********************************************************************
NSImage+QuickLook.h - generate quicklook images

by Matt Gemmell on 29/10/2007.
*********************************************************************/
#ifndef __OPCODERS_ORTHODOXFILEMANAGER_NSIMAGEQUICKLOOK_H__
#define __OPCODERS_ORTHODOXFILEMANAGER_NSIMAGEQUICKLOOK_H__

@interface NSImage (QuickLook)


+ (NSImage *)imageWithPreviewOfFileAtPath:(NSString *)path ofSize:(NSSize)size asIcon:(BOOL)icon;


@end

#endif // __OPCODERS_ORTHODOXFILEMANAGER_NSIMAGEQUICKLOOK_H__