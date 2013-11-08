/*********************************************************************
NCVolumeInfo.h - collect info about a mounted volume, such as
 1. volume name, e.g.  Machintosh HD
 2. harddisk capacity, e.g. 320 GB
 3. harddisk used, e.g. 42 GB

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#ifndef __OPCODERS_NEWTONCOMMANDER_VOLUME_INFO_H__
#define __OPCODERS_NEWTONCOMMANDER_VOLUME_INFO_H__
                        
@interface NCVolumeInfo : NSObject {
	NSString* m_path;
	NSString* m_info;
}
-(void)reloadInfo;
-(NSString*)info;
-(void)setPath:(NSString*)path;
@end

#endif // __OPCODERS_NEWTONCOMMANDER_VOLUME_INFO_H__