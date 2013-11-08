/*********************************************************************
PanelTable.h - data source for the NSTableView 
that shows filenames, filesizes, filetypes.
PanelTable allows you to sort the data.

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#ifndef __OPCODERS_KEYBOARDCOMMANDER_PANELTABLE_H__
#define __OPCODERS_KEYBOARDCOMMANDER_PANELTABLE_H__

#include <sys/types.h>
#include <sys/stat.h>

enum {
	kPanelTableTypeNone = 0, // we have not yet received any data from backend
	kPanelTableTypeUnknown,
	kPanelTableTypeFile,
	kPanelTableTypeFileLink,
	kPanelTableTypeDir,    
	kPanelTableTypeDirLink,
	kPanelTableTypeLink,
	kPanelTableTypeFifo,
	kPanelTableTypeChar,
	kPanelTableTypeBlock,
	kPanelTableTypeSocket,
	kPanelTableTypeWhiteout,
};
typedef NSUInteger PanelTableType;


struct PanelTableData;
@interface PanelTable : NSObject {
	PanelTableData* m_data;
}

-(void)test;
-(void)logVisibleRows;

// immutable NSString array
-(void)setColumnName:(NSArray*)ary;

// immutable NSString array
-(void)setColumnExtension:(NSArray*)ary;

// must be an immutable NSData containing a vector of stat64 structs
-(void)setColumnStat64Vector:(NSData*)data;

// must be an immutable NSData containing a vector of unsigned int's
-(void)setColumnTypeVector:(NSData*)data;

// must be an immutable NSData containing a vector of unsigned int's
-(void)setColumnAliasVector:(NSData*)data;

// mutable
-(void)setColumnVisibleTo:(BOOL)value;

// mutable
-(void)setColumnSelectTo:(BOOL)value;

// mutable
-(void)setCount:(NSUInteger)n;
-(NSUInteger)count;
-(void)unsetCount;
-(BOOL)isCountSet;

-(void)removeAllData;

// must be called before sort
-(void)resetIndexes;

-(void)setSortOrderString:(NSString*)s;
-(void)sort;

// how many rows can you see in the table
-(NSUInteger)visibleNumberOfRows;

// what is the name of the file
-(NSString*)visibleNameForRow:(NSUInteger)row;

// what is the size in bytes
-(uint64_t)visibleSizeForRow:(NSUInteger)row;

// what is the posix permissions as 3-digit octals
-(NSUInteger)visiblePermissionForRow:(NSUInteger)row;

/*
You must specify a pointer to where you want the result to go.
returns YES if the result could be obtained.
returns NO if not.
*/
-(BOOL)visibleStat64ForRow:(NSUInteger)row outStat64:(struct stat64*)result;


/* 
what filetype are we dealing with
 0 = unknown
 1 = file
 2 = dir
*/
-(PanelTableType)visibleTypeForRow:(NSUInteger)row;

// is the row selected
-(BOOL)visibleSelectedForRow:(NSUInteger)row;
-(void)setVisibleSelectedForRow:(NSUInteger)row value:(BOOL)value;


/*
BOOL callback(NSString* name, void* context) {
	OPPartialSearch* ps = reinterpret_cast<OPPartialSearch*>(context);
	return [ps isEqual:name];
}
... elsewhere ...
[m_panel_table filterVisibleByName:callback context:m_partial_search];

*/
-(void)filterVisibleByName:(BOOL (*)(NSString*, void *))func context:(void*)context;


/*
is the integrity ok.
*/
-(BOOL)isValid;

@end


#endif // __OPCODERS_KEYBOARDCOMMANDER_PANELTABLE_H__