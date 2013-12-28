//
// NCFileItem+FileItemsForPath.m
// Newton Commander
//

#import "NCFileItem+FileItemsForPath.h"
#include <sys/stat.h>
#include <err.h>
#include <fts.h>

@implementation NCFileItem (FileItemsForPath)

+(NCFileItem*)fileItemFromFTSENT:(FTSENT *)p {
	switch (p->fts_info) {
		case FTS_ERR: {
			NSLog(@"FTS_ERR occurred");
			break; }
		case FTS_DC:
		case FTS_D: {
			printf("d %s\n", p->fts_path);
			
			NSString *fullPath = [NSString stringWithUTF8String:p->fts_path];
			NSString *name = [fullPath lastPathComponent];
			unsigned long long inode = p->fts_ino;
			
			NCFileItem* item = [NCFileItem new];
			item.name = name;
			item.inode = inode;
			item.itemType = kNCItemTypeDirGuess;
			item.owner = @"?";
			item.group = @"?";
			
			return item; }
		case FTS_F: {
			printf("f %s\n", p->fts_path);
			
			NSString *fullPath = [NSString stringWithUTF8String:p->fts_path];
			NSString *name = [fullPath lastPathComponent];
			unsigned long long inode = p->fts_ino;
			
			NCFileItem* item = [NCFileItem new];
			item.name = name;
			item.inode = inode;
			item.itemType = kNCItemTypeFileOrAlias;
			item.owner = @"?";
			item.group = @"?";
			
			return item; }
		case FTS_SLNONE:
		case FTS_SL: {
			printf("sl %s\n", p->fts_path);
			
			NSString *fullPath = [NSString stringWithUTF8String:p->fts_path];
			NSString *name = [fullPath lastPathComponent];
			unsigned long long inode = p->fts_ino;
			
			NCFileItem* item = [NCFileItem new];
			item.name = name;
			item.inode = inode;
			item.itemType = kNCItemTypeLinkToDirGuess;
			item.owner = @"?";
			item.group = @"?";
			
			return item; }
		case FTS_DNR:
		case FTS_W:
		case FTS_NS:
		case FTS_DEFAULT: {
			printf("default %s\n", p->fts_path);
			
			NSString *fullPath = [NSString stringWithUTF8String:p->fts_path];
			NSString *name = [fullPath lastPathComponent];
			unsigned long long inode = p->fts_ino;
			
			NCFileItem* item = [NCFileItem new];
			item.name = name;
			item.inode = inode;
			item.itemType = kNCItemTypeUnknown;
			item.owner = @"?";
			item.group = @"?";
			
			return item; }
			
		default:
			break;
	}
	return nil;
}

+(NSArray*)fileItemsForPath:(NSString*)path {
	NSMutableArray *items = [NSMutableArray new];
	
	int fts_options = FTS_LOGICAL | FTS_NOCHDIR;
	
	char* path_array[2];
	path_array[0] = (char*)strdup([path UTF8String]);
	path_array[1] = NULL;
	
	
	FTS *ftsp = fts_open(path_array, fts_options, NULL);
	if (!ftsp) {
		warn("fts_open");
		return nil;
	}
	FTSENT *chp = fts_children(ftsp, 0);
	if (chp == NULL) {
		NSLog(@"no files to traverse");
		return nil;
	}
	while (1) {
		FTSENT *p = fts_read(ftsp);
		if (!p) break;
		if (p->fts_level < 1) continue;
		
		NCFileItem *item = [NCFileItem fileItemFromFTSENT:p];
		if (item) {
			[items addObject:item];
		}
		
		// Non-recursive
		if (p->fts_level >= 1) {
			fts_set(ftsp, p, FTS_SKIP);
		}
	}
	fts_close(ftsp);
	
	return items.copy;
}

@end
