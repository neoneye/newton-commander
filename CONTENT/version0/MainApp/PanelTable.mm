/*********************************************************************
PanelTable.mm - data source for the NSTableView 
that shows filenames, filesizes, filetypes.
PanelTable allows you to sort the data.

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>

IDEA: better names, such as
 1. FileList_Model

IDEA: somehow integrate isAlias file, so that these files
can be treated as dirs.
Reminds me of false-positives... yes it's a file, except in some cases.


IDEA: ignore preferences:
 '.' current dir    <-- you might want to check /. sometimes
 '..' parent dir
 '.DS_Store'
 '.localized'
 '.svn'
 '.git'
 '.gitignore'

*********************************************************************/
#include "PanelTable.h"
#include <algorithm>
#include <vector>
#include <assert.h>
#include "system_GDE.h"
#include "di_protocol.h"


#define SORT_ORDER_STR_CAPACITY 20

namespace {

typedef std::vector<NSUInteger> UIntegerVector;
typedef std::vector<BOOL> BoolVector;


NSArray* MakeArrayFromUIntegerVector(UIntegerVector& v) {
	NSUInteger n = v.size();
	NSMutableArray* ary = [NSMutableArray arrayWithCapacity:n];
	for(int i=0; i<n; ++i) {
		NSUInteger value = v[i];
		NSNumber* num = [NSNumber numberWithUnsignedInteger:value];
		[ary addObject:num];
	}
	return [[ary copy] autorelease];
}

NSArray* MakeArrayFromBoolVector(BoolVector& v) {
	NSUInteger n = v.size();
	NSMutableArray* ary = [NSMutableArray arrayWithCapacity:n];
	for(int i=0; i<n; ++i) {
		BOOL value = v[i];
		NSNumber* num = [NSNumber numberWithBool:value];
		[ary addObject:num];
	}
	return [[ary copy] autorelease];
}


} // namespace


/*

usage:

def get_number_of_filenames
	m_visible_indexes.count
end

def get_filename(i)	
	m_column_names[m_visible_indexes[i]]
end


design decisions:

PROBLEM:
 - asyncronous

SOLUTION:
Data is collected on the background, when it's ready
it's inserted into the DirCache and into our PanelTable.



PROBLEM: 
 - A: a row struct, with just one column array
 - B: many column arrays

SOLUTION: 
(B) Each column in the database has it's own array.
This is because the column data arrives asynchronously
from the disk. So if data is not present, then an
entire column can be nil. And when the data arrives
it can be assigned.



PROBLEM:
 - sort by extension, followed by type

SOLUTION:
std::stable_sort

*/
struct PanelTableData {
	/*
	list that indicates which indexes that are visible.
	*/
	UIntegerVector m_visible_indexes;

	/*
	After everything has been sorted, the m_all_indexes contains
	the final ordering of the rows. Populating/updating this 
	std::vector is the whole purpose with this class.
	*/
	UIntegerVector m_all_indexes;
	
	/*
	list of filenames, containing strings 
	such as "verylongname.png"
	all objects must be NSString's
	*/
	NSArray* m_column_name;
	
	/*
	list of fileextensions, containing strings 
	such as ".png"
	all objects must be NSString's
	*/
	NSArray* m_column_extension;
	
	/*
	vector of stat64 structs
	*/
	NSData* m_column_stat64;
	
	/*
	vector of unsigned int's, such as:
	SystemGetDirEntriesTypeDir  =  4 directory
	SystemGetDirEntriesTypeFile =  8 regular file
	SystemGetDirEntriesTypeLink = 10 symbolic link
	*/
	NSData* m_column_type;
	
	/*
	vector of unsigned int's, such as:
	0
	1
	2
	3
	*/
	NSData* m_column_alias;
	
	/*
	for a list of with partial-matches we only
	want to show some of them. The list contains booleans
	such as YES. When a filename is matched by the 
	search string then it's set to YES.
	When it's not its set to NO.
	all objects must be NSNumber's 
	*/
	BoolVector m_column_visible;
	
	/*
	list of selections, containing booleans
	such as YES. When a row is selected by the user
	then it's flagged YES. When its not its flagged NO.
	all objects must be NSNumber's 
	NOTE: this is a mutable array, because the user
	is expected to change selection a lot.
	*/
	BoolVector m_column_select;

	/*
	IDEA: other columns that can be added in the future
	*/
	// NSArray* m_column_kMDItemContentType; public.ruby-script
	// NSArray* m_column_date_backup;
	// NSArray* m_column_acl_rule_count;
	// NSArray* m_column_xattr_count;
	// NSArray* m_column_cnid;
	// NSArray* m_column_subdir_item_count;
	// NSArray* m_column_subdir_size_count;

	NSUInteger m_count;
	BOOL m_count_is_set;
	
	char m_sort_order_str[SORT_ORDER_STR_CAPACITY];
	
	PanelTableData() : 
		m_column_name(nil), 
		m_column_extension(nil), 
		m_column_stat64(nil),
		m_column_type(nil), 
		m_column_alias(nil), 
		m_count(0),
		m_count_is_set(YES)
	{
		m_sort_order_str[0] = 0;
	}
	
	~PanelTableData() {
		[m_column_name release];
		[m_column_extension release];
		[m_column_stat64 release];
		[m_column_type release];
		[m_column_alias release];
	}
	
	/*
	this resets the sorting indexes
	*/
	void reset_indexes() {
		m_visible_indexes.clear();
		m_all_indexes.clear();
		if(m_count_is_set == NO) {
			// NSLog(@"reset_indexes. m_count is NOT set");
			return;
		}
		for(NSUInteger i=0; i<m_count; ++i) {
			m_all_indexes.push_back(i);
			m_visible_indexes.push_back(i);
		}
	}
	
	void set_sort_order_str(const char* s) {
		strncpy(m_sort_order_str, s, SORT_ORDER_STR_CAPACITY-1);
		m_sort_order_str[SORT_ORDER_STR_CAPACITY-1] = 0;
	}


	/*
	returns -1 if lhs < rhs
	returns 0 if lhs == rhs
	returns +1 if lhs > rhs
	*/
	int compare_name(NSUInteger lhs, NSUInteger rhs) const;
	int compare_size(NSUInteger lhs, NSUInteger rhs) const;
	int compare_type(NSUInteger lhs, NSUInteger rhs) const;
	int compare_unsorted(NSUInteger lhs, NSUInteger rhs) const;

	/*
	returns true if lhs < rhs;
	otherwise false.
	*/
	bool sort_callback(NSUInteger lhs, NSUInteger rhs) const;

	/*
	sort only reorders the m_all_indexes column,
	all the other columns are unaffected.
	*/
	void sort_indexes();
	
	/*
	this updates the visible indexes array
	*/
	void rebuild_visible_indexes();

    
	/*
	returns 0 if things are good
	
	returns X if there is something wrong.. where X indicates
	what's wrong.
	*/
	NSUInteger check_integrity();


	/*
	accessor to the data obtained by stat64.
	*/
	BOOL get_stat64(NSUInteger index, struct stat64* result) const {
		if(result == NULL) {
			return NO; // no result pointer given
		}
		if(m_column_stat64 == nil) {
			return NO; // the column is not populated with any data
		}
		NSUInteger elements = [m_column_stat64 length] / sizeof(struct stat64);
		if(index >= elements) {
			return NO; // out of bounds
		}
		NSRange range = NSMakeRange(
			index * sizeof(struct stat64), 
			sizeof(struct stat64)
		);
		[m_column_stat64 getBytes:result range:range];
		return YES;
	}


	/*
	accessor to the data obtained by GetDirectoryEntries.
	*/
	BOOL get_type(NSUInteger index, unsigned int* result) const {
		if(result == NULL) {
			// NSLog(@"a");
			return NO; // no result pointer given
		}
		if(m_column_type == nil) {
			// NSLog(@"b");
			return NO; // the column is not populated with any data
		}
		NSUInteger elements = [m_column_type length] / sizeof(unsigned int);
		if(index >= elements) {
			// NSLog(@"c");
			return NO; // out of bounds
		}
		NSRange range = NSMakeRange(
			index * sizeof(unsigned int), 
			sizeof(unsigned int)
		);
		[m_column_type getBytes:result range:range];
		return YES;
	}


	/*
	accessor to the data obtained by FSResolveAliasFileWithMountFlags.
	*/
	BOOL get_alias(NSUInteger index, unsigned int* result) const {
		if(result == NULL) {
			return NO; // no result pointer given
		}
		if(m_column_alias == nil) {
			return NO; // the column is not populated with any data
		}
		NSUInteger elements = [m_column_alias length] / sizeof(unsigned int);
		if(index >= elements) {
			return NO; // out of bounds
		}
		NSRange range = NSMakeRange(
			index * sizeof(unsigned int), 
			sizeof(unsigned int)
		);
		[m_column_alias getBytes:result range:range];
		return YES;
	}


	/*
	Determining if something is a dir or a file is tricky.
	Especially when it's about showing data as quick as possible
	to the user. The stat64 struct takes forever to obtain,
	until it has been obtained we have to use the data 
	we got from GetDirectoryEntries.. and it has some false positives!
	When the filetype is a link then it can either point to a dir or a file
	or something else. Stat64 resolves the link, so you can see
	what kind of type you are dealing with.
	GetDirectoryEntries doesn't resolve it, so it's fuzzy.
	In this case we treat links as directories.
	*/
	BOOL get_stattype(NSUInteger index, PanelTableType* result) const {
		if(result == NULL) {
			return NO; // no result pointer given
		}
		
		/*
		In Apple's file system world there is a thing called an Alias.
		It's works much like a symlink, except Alias'es aren't
		accessible from the unix filesystem api. Further more
		it's not possible to do relative paths to a symlink,
		so following an Alias replaces the full path.
		A good thing about aliases is that they are robust to renames,
		so the link wont braek if you rename the target file.
		
		It also takes a lot of time to determine if a file is an alias.
		If it's an alias for a directory.. then we should 
		not treat it as a file.. but instead as a directory.
		For this reason we start out determining if this is the case.
		*/
		unsigned int isalias = 0;
		BOOL ok0 = get_alias(index, &isalias);
		if(ok0) {
			// NSLog(@"index: %i   isalias: %u", (int)index, isalias);
			if(isalias == kListToolIsAliasYesFolder) {
				*result = kPanelTableTypeDirLink;
				return YES;
			}
			if(isalias == kListToolIsAliasYesFile) {
				*result = kPanelTableTypeFileLink;
				return YES;
			}
			/*
			fall through. it's not an alias file.
			*/
		}

		BOOL is_link = NO;
		unsigned int filetype = 0;
		BOOL ok2 = get_type(index, &filetype);
		if(ok2) {
			if(filetype == SystemGetDirEntriesTypeLink) {
				is_link = YES;
			}
		}

		/*
		obtaining the stat64 struct takes forever for Mac OS X,
		and it contains the info for what symlinks points to.
		If a file is a symlink to a dir.. it tells us it's a dir.
		For this reason we first check if we have been going
		through the pain of obtaining stat64.. and use this info.
		*/
		struct stat64 st;
		BOOL ok1 = get_stat64(index, &st);
		if(ok1) {
			PanelTableType v = kPanelTableTypeUnknown;
			switch(st.st_mode & S_IFMT) {
			case S_IFDIR: 
				v = is_link ? kPanelTableTypeDirLink : kPanelTableTypeDir; 
				break;
		    case S_IFREG: 
				v = is_link ? kPanelTableTypeFileLink : kPanelTableTypeFile;
				break;
		    case S_IFLNK: v = kPanelTableTypeLink; break;
		    case S_IFIFO: v = kPanelTableTypeFifo; break;
		    case S_IFCHR: v = kPanelTableTypeChar; break;
		    case S_IFBLK: v = kPanelTableTypeBlock; break;
		    case S_IFSOCK: v = kPanelTableTypeSocket; break;
		    case S_IFWHT: v = kPanelTableTypeWhiteout; break;
			}
			*result = v;
			return YES;
		}

		/*
		without any meaningful info in stat64..
		we look at the info we got from GetDirectoryEntries.
		The big problem with this info is that the symlinks
		has no info about wether it points to a file or a dir.
		*/
		if(ok2) {
			PanelTableType v = kPanelTableTypeUnknown;
			switch(filetype) {
			case SystemGetDirEntriesTypeFile: v = kPanelTableTypeFile; break;
			case SystemGetDirEntriesTypeDir: v = kPanelTableTypeDir; break;
			case SystemGetDirEntriesTypeLink: v = kPanelTableTypeLink; break;
			case SystemGetDirEntriesTypeFifo: v = kPanelTableTypeFifo; break;
			case SystemGetDirEntriesTypeChar: v = kPanelTableTypeChar; break;
			case SystemGetDirEntriesTypeBlock: v = kPanelTableTypeBlock; break;
			case SystemGetDirEntriesTypeSocket: v = kPanelTableTypeSocket; break;
			case SystemGetDirEntriesTypeWhiteout: v = kPanelTableTypeWhiteout; break;
			}
			return YES;
		}

		return NO;
	}
	
};

NSUInteger PanelTableData::check_integrity() {
	if(m_count_is_set == NO) return 1;
	if(m_all_indexes.size() != m_count) return 2;
	if(m_column_select.size() != m_count) return 3;
	if(m_column_visible.size() != m_count) return 4;

	if(m_column_name != nil) {
		NSUInteger n = [m_column_name count];
		if(n != m_count) return 5;
	}
	if(m_column_extension != nil) {
		NSUInteger n = [m_column_extension count];
		if(n != m_count) return 6;
	}
	if(m_column_stat64 != nil) {
		NSUInteger actual = [m_column_stat64 length];
		NSUInteger expected = m_count * sizeof(struct stat64);
		if(actual != expected) return 7;
	}
	if(m_column_type != nil) {
		NSUInteger actual = [m_column_type length];
		NSUInteger expected = m_count * sizeof(unsigned int);
		if(actual != expected) return 8;
	}
	if(m_column_alias != nil) {
		NSUInteger actual = [m_column_alias length];
		NSUInteger expected = m_count * sizeof(unsigned int);
		if(actual != expected) return 8;
	}
	return 0; // integrity is good
}

void PanelTableData::rebuild_visible_indexes() {
	if(m_count_is_set == NO) {
		NSLog(@"rebuild_visible_indexes. m_count is NOT set");
		return;
	}
	NSUInteger n0 = m_column_visible.size();
	NSUInteger n1 = m_all_indexes.size();
	if((n0 != m_count) || (n1 != m_count)) {
		NSLog(@"rebuild_visible_indexes: ERROR: mismatch in size. n0: %i  n1: %i  m_count: %i", (int)n0, (int)n1, (int)m_count);
		return;
	}

	assert(n0 == m_count);
	assert(n1 == m_count);

	m_visible_indexes.clear();
	
	NSUInteger n = m_all_indexes.size();
	for(NSUInteger i=0; i<n; ++i) {
		NSUInteger index = m_all_indexes[i];
		if(index >= m_count) {
			// should not happen.. index is outside bounds
			continue;
		}
		if(m_column_visible[index]) {
			m_visible_indexes.push_back(index);
		}
	}
}

int PanelTableData::compare_name(NSUInteger lhs, NSUInteger rhs) const {
	if(m_column_name == nil) return 0;

	id obj0 = [m_column_name objectAtIndex:lhs];
	if(obj0 == nil) return 0;
	if([obj0 isKindOfClass:[NSString class]] == NO) return 0;
	
	id obj1 = [m_column_name objectAtIndex:rhs];
	if(obj1 == nil) return 0;
	if([obj1 isKindOfClass:[NSString class]] == NO) return 0;
	
	NSString* v0 = (NSString*)obj0;
	NSString* v1 = (NSString*)obj1;
	NSComparisonResult result = 
		[v0 compare:v1 options:NSCaseInsensitiveSearch];

	switch(result) {
	case NSOrderedAscending: return -1;
	case NSOrderedDescending: return 1;
	}
	return 0;
}

int PanelTableData::compare_size(NSUInteger lhs, NSUInteger rhs) const {
	struct stat64 st;
	if(get_stat64(lhs, &st) == NO) return 0;
	uint64_t s0 = st.st_size;
	if(get_stat64(rhs, &st) == NO) return 0;
	uint64_t s1 = st.st_size;
	if(s0 == s1) return 0;
	return (s0 < s1) ? -1 : 1;
}

int PanelTableData::compare_type(NSUInteger lhs, NSUInteger rhs) const {
	PanelTableType type0, type1;
	
	if(get_stattype(lhs, &type0) == NO) return 0;
	if(get_stattype(rhs, &type1) == NO) return 0;

	unsigned int xtype0 = 1;
	if((type0 == kPanelTableTypeDir) ||         
		(type0 == kPanelTableTypeDirLink) ||
		(type0 == kPanelTableTypeLink)) {
		xtype0 = 0;
	}
	unsigned int xtype1 = 1;
	if((type1 == kPanelTableTypeDir) ||
		(type1 == kPanelTableTypeDirLink) ||
		(type1 == kPanelTableTypeLink)) {
		xtype1 = 0;
	}

	if(xtype0 == xtype1) return 0;
	return (xtype0 < xtype1) ? -1 : 1;
}

int PanelTableData::compare_unsorted(NSUInteger lhs, NSUInteger rhs) const {
	if(lhs == rhs) return 0;
	return (lhs < rhs) ? -1 : 1;
}

bool PanelTableData::sort_callback(NSUInteger lhs, NSUInteger rhs) const {
	if(lhs >= m_count) return false;
	if(rhs >= m_count) return false;

	// char sort_order[] = "-n";        
	// char sort_order[] = "tsn";
	const char* sort_order = m_sort_order_str;
	
	bool reverse = false;
	
	const char* s = sort_order;
	for(;;) {
		char v = *s;
		if(v == 0) break;
		++s;

		if(v == '-') {
			reverse = true;
			continue;
		}
		
		
		int rc = 0;
		switch(v) {
		case 'u': rc = compare_unsorted(lhs, rhs); break;
		case 'n': rc = compare_name(lhs, rhs); break;
		case 's': rc = compare_size(lhs, rhs); break;
		case 't': rc = compare_type(lhs, rhs); break;
		// default is to do nothing 
		}
		if(rc != 0) {
			return reverse ? (rc > 0) : (rc < 0);
		}
		reverse = false;
	}
	return false;
}


struct PanelTableDataSortIndexes {
	PanelTableData& m_data;
	PanelTableDataSortIndexes(PanelTableData& data) : m_data(data) {}
	
	bool operator() (NSUInteger lhs, NSUInteger rhs) const {
		return m_data.sort_callback(lhs, rhs);
	}
};

void PanelTableData::sort_indexes() {
	reset_indexes();
	std::sort(
		m_all_indexes.begin(), 
		m_all_indexes.end(), 
		PanelTableDataSortIndexes(*this)
	);
	rebuild_visible_indexes();
}



@interface PanelTable (Private)

-(void)verifyStringArray:(NSArray*)ary;
-(void)verifyNumberArray:(NSArray*)ary;

@end


@implementation PanelTable

-(id)init {
	self = [super init];
    if(self) {
		m_data = new PanelTableData;
    }
    return self;
}

-(void)test {
	NSArray* col_name = [NSArray arrayWithObjects:
		@"d", 
		@"b", 
		@"c", 
		@"a", 
		nil
	];
	[self setColumnName:col_name];

	NSArray* col_ext = [NSArray arrayWithObjects:
		@"png", 
		@"html", 
		@"jpg", 
		@"tex", 
		nil
	];
	[self setColumnExtension:col_ext];

	NSArray* col_type = [NSArray arrayWithObjects:
		[NSNumber numberWithUnsignedInteger:0],
		[NSNumber numberWithUnsignedInteger:1],
		[NSNumber numberWithUnsignedInteger:0],
		[NSNumber numberWithUnsignedInteger:1],
		nil
	];
	// [self setColumnType:col_type];

	NSArray* col_size = [NSArray arrayWithObjects:
		[NSNumber numberWithUnsignedInteger:123],
		[NSNumber numberWithUnsignedInteger:100],
		[NSNumber numberWithUnsignedInteger:500],
		[NSNumber numberWithUnsignedInteger:200],
		nil
	];
	// use stat64 instead
	// [self setColumnSize:col_size];

	[self setCount:4];

	[self setColumnVisibleTo:YES];
	m_data->m_column_visible[2] = NO;

	[self setColumnSelectTo:NO];
	m_data->m_column_select[1] = YES;
	m_data->m_column_select[3] = YES;
	

	m_data->reset_indexes();
	[self setSortOrderString:@"t-s"];
	[self sort];
	
	NSLog(@"%s %@", _cmd, self);
	
	[self logVisibleRows];
}

-(void)logVisibleRows {
	NSUInteger n = [self visibleNumberOfRows];
	for(NSUInteger i=0; i<n; ++i) {
		NSString* v_name = [self visibleNameForRow:i];
		NSUInteger v_size = [self visibleSizeForRow:i];
		NSUInteger v_type = [self visibleTypeForRow:i];
		NSLog(@"row#%i %@ %i %i", (int)i, v_name, (int)v_size, (int)v_type);
	}
}

-(void)verifyStringArray:(NSArray*)ary {
	id thing;
	NSEnumerator* en = [ary objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[NSString class]]) continue;
		if([thing isKindOfClass:[NSNull class]]) continue;
		NSAssert(NO, @"all objects must be NSString's or NSNull");
	}
}

-(void)verifyNumberArray:(NSArray*)ary {
	id thing;
	NSEnumerator* en = [ary objectEnumerator];
	while(thing = [en nextObject]) {
		if([thing isKindOfClass:[NSNumber class]]) continue;
		if([thing isKindOfClass:[NSNull class]]) continue;
		NSAssert(NO, @"all objects must be NSNumber's or NSNull");
	}
}

-(void)setColumnName:(NSArray*)ary {
	if(m_data->m_column_name != ary) {
		if(ary) [self verifyStringArray:ary];
		[m_data->m_column_name release];
		m_data->m_column_name = [ary copy];
	}
}

-(void)setColumnExtension:(NSArray*)ary {
	if(m_data->m_column_extension != ary) {
		if(ary) [self verifyStringArray:ary];
		[m_data->m_column_extension release];
		m_data->m_column_extension = [ary copy];
	}
}

-(void)setColumnStat64Vector:(NSData*)data {
	if(m_data->m_column_stat64 != data) {
		if(data != nil) {
			if([data isKindOfClass:[NSData class]] == NO) {
				NSLog(@"ERROR: PanelTable %s - expected NSData, but got something else", _cmd);
				data = nil;
			}
		}
		[m_data->m_column_stat64 release];
		m_data->m_column_stat64 = [data copy];
	}
}

-(void)setColumnTypeVector:(NSData*)data {
	if(m_data->m_column_type != data) {
		if(data != nil) {
			if([data isKindOfClass:[NSData class]] == NO) {
				NSLog(@"ERROR: PanelTable %s - expected NSData, but got something else", _cmd);
				data = nil;
			}
		}
		[m_data->m_column_type release];
		m_data->m_column_type = [data copy];
	}
}

-(void)setColumnAliasVector:(NSData*)data {
	if(m_data->m_column_alias != data) {
		if(data != nil) {
			if([data isKindOfClass:[NSData class]] == NO) {
				NSLog(@"ERROR: PanelTable %s - expected NSData, but got something else", _cmd);
				data = nil;
			}
		}
		[m_data->m_column_alias release];
		m_data->m_column_alias = [data copy];
	}
}

-(void)setColumnVisibleTo:(BOOL)value {
	NSUInteger n = m_data->m_count;
	m_data->m_column_visible.clear();
	for(NSUInteger i=0; i<n; ++i) {
		m_data->m_column_visible.push_back(value);
	}
}

-(void)setColumnSelectTo:(BOOL)value {
	NSUInteger n = m_data->m_count;
	m_data->m_column_select.clear();
	for(NSUInteger i=0; i<n; ++i) {
		m_data->m_column_select.push_back(value);
	}
}

-(void)setCount:(NSUInteger)n {
	m_data->m_count = n;
	m_data->m_count_is_set = YES;
}

-(NSUInteger)count {
	return m_data->m_count;
}

-(void)unsetCount {
	m_data->m_count_is_set = NO;
}

-(BOOL)isCountSet {
	return m_data->m_count_is_set;
}

-(void)setSortOrderString:(NSString*)s {
	const char* str = [s UTF8String];
	m_data->set_sort_order_str(str);
}

-(void)sort {
	// NSLog(@"%s", _cmd);
	NSAssert([self isValid], @"table is bad before sort");
	m_data->sort_indexes();
	NSAssert([self isValid], @"table is bad after sort");
}

-(void)resetIndexes {
	NSAssert(m_data != NULL, @"must not be null");
	m_data->reset_indexes();
}

-(NSUInteger)visibleNumberOfRows {
	NSAssert(m_data != NULL, @"must not be null");
	return m_data->m_visible_indexes.size();
}

-(NSString*)visibleNameForRow:(NSUInteger)row {
	NSAssert(m_data != NULL, @"must not be null");
	if(m_data->m_column_name == nil) {
		return nil; // names not yet loaded from disk, can happen and is ok
	}
	if(row >= m_data->m_visible_indexes.size()) {
		return nil; // should never happen, unless sorting fucked up
	}
	NSUInteger index = m_data->m_visible_indexes[row];
	if(index >= [m_data->m_column_name count]) {
		NSLog(@"%s ERROR: out of bounds", _cmd);
		return nil; // should never happen, unless sorting fucked up
	}
	id thing = [m_data->m_column_name objectAtIndex:index];
	if([thing isKindOfClass:[NSString class]] == NO) {
		// should not happen.. thing are supposed to be NSString always
		return nil;
	}
	return (NSString*)thing;
}

-(uint64_t)visibleSizeForRow:(NSUInteger)row {
	struct stat64 st;
	BOOL ok = [self visibleStat64ForRow:row outStat64:&st];
	if(!ok) return 0;
	return st.st_size;
}

-(NSUInteger)visiblePermissionForRow:(NSUInteger)row {
	struct stat64 st;
	BOOL ok = [self visibleStat64ForRow:row outStat64:&st];
	if(!ok) return 0;
	return st.st_mode & 0777;
}

-(BOOL)visibleStat64ForRow:(NSUInteger)row outStat64:(struct stat64*)result {
	if(result == NULL) return NO;
	
	NSAssert(m_data != NULL, @"must not be null");
	if(row >= m_data->m_visible_indexes.size()) {
		return NO; // should never happen, unless sorting fucked up
	}
	NSUInteger index = m_data->m_visible_indexes[row];
	return m_data->get_stat64(index, result);
}

-(PanelTableType)visibleTypeForRow:(NSUInteger)row {
	NSAssert(m_data != NULL, @"must not be null");
	if(row >= m_data->m_visible_indexes.size()) {
		return kPanelTableTypeNone; // should never happen, unless sorting fucked up
	}
	NSUInteger index = m_data->m_visible_indexes[row];
	PanelTableType result = kPanelTableTypeNone;
	m_data->get_stattype(index, &result);
	return result;
}

-(BOOL)visibleSelectedForRow:(NSUInteger)row {
	NSAssert(m_data != NULL, @"must not be null");
	if(row >= m_data->m_visible_indexes.size()) {
		return NO; // should never happen, unless sorting fucked up
	}
	NSUInteger index = m_data->m_visible_indexes[row];
	if(index >= m_data->m_column_select.size()) {
		NSLog(@"%s ERROR: out of bounds", _cmd);
		return NO; // should never happen, unless sorting fucked up
	}
	BOOL is_row_selected = m_data->m_column_select[index];
	return is_row_selected;
}

-(void)setVisibleSelectedForRow:(NSUInteger)row value:(BOOL)value {
	NSAssert(m_data != NULL, @"must not be null");
	if(row >= m_data->m_visible_indexes.size()) {
		return; // should never happen, unless sorting fucked up
	}
	NSUInteger index = m_data->m_visible_indexes[row];
	if(index >= m_data->m_column_select.size()) {
		NSLog(@"%s ERROR: out of bounds", _cmd);
		return; // should never happen, unless sorting fucked up
	}
	m_data->m_column_select[index] = value;
}

-(void)filterVisibleByName:(BOOL (*)(NSString*, void *))func context:(void*)context 
{
	NSAssert(m_data != NULL, @"must not be null");
	NSAssert(func != NULL, @"no callback provided");

	if(m_data->m_column_name == nil) {
		return; // names not yet loaded from disk, can happen and is ok
	}

	NSUInteger n = [m_data->m_column_name count];
	int n2 = m_data->m_column_visible.size();
	if(n != n2) {
		NSLog(@"ERROR: mismatch in column_visible.size, correcting");
		[self setColumnVisibleTo:YES];
	}
	n2 = m_data->m_column_visible.size();
	if(n != n2) {
		NSLog(@"ERROR: failed correcting mismatch in column_visible.size");
		return;
	}
	
	// it's like multiplication:  visible = visible * filter(name)
	for(NSUInteger i=0; i<n; ++i) {
		BOOL value = m_data->m_column_visible[i];
		if(!value) continue;
		
		id thing = [m_data->m_column_name objectAtIndex:i];
		if([thing isKindOfClass:[NSString class]]) {
			value = func((NSString*)thing, context);
		}
		if(!value) {
			m_data->m_column_visible[i] = NO;
		}
	}

	// NSArray* vis1 = MakeArrayFromBoolVector(m_data->m_column_visible);
	// NSLog(@"%s BEFORE: %@", _cmd, vis0);
	// NSLog(@"%s AFTER: %@", _cmd, vis1);
}

-(NSString*)description {
	NSArray* all_indexes = MakeArrayFromUIntegerVector(
		m_data->m_all_indexes);
	NSArray* vis_indexes = MakeArrayFromUIntegerVector(
		m_data->m_visible_indexes);
	NSArray* col_name = m_data->m_column_name;
	NSArray* col_ext = m_data->m_column_extension;
  	int bytes_stat64 = [m_data->m_column_stat64 length];
	int bytes_type = [m_data->m_column_type length];
	int bytes_alias = [m_data->m_column_alias length];
	NSArray* col_visible = MakeArrayFromBoolVector(m_data->m_column_visible);
	NSArray* col_sel = MakeArrayFromBoolVector(m_data->m_column_select);
	int n = m_data->m_count;
	const char* isset = (m_data->m_count_is_set) ? "set" : "NULL";
	
	return [NSString stringWithFormat: 
		@"PanelTable\n"
		"m_count: %i %s\n"
		"all_indexes: %@\n"
		"vis_indexes: %@\n"
		"col_name: %@\n"                       
		"col_extension: %@\n"
		"bytes_stat64: %i\n"               
		"bytes_type: %i\n"
		"bytes_alias: %i\n"
		"col_visible: %@\n"
		"col_select: %@", 
		n, isset,
		all_indexes,
		vis_indexes,
		col_name,
		col_ext,
		bytes_stat64,
		bytes_type,
		bytes_alias,
		col_visible,
		col_sel
	];
}

-(void)removeAllData {
	[self setColumnName:nil];
	[self setColumnExtension:nil];
	[self setColumnTypeVector:nil];
	[self setColumnAliasVector:nil];
	[self setColumnStat64Vector:nil];
	m_data->m_column_visible.clear();
	m_data->m_column_select.clear();
	[self setCount:0];
	[self unsetCount];
	[self resetIndexes];
}

-(BOOL)isValid {
	if(m_data->m_count_is_set == NO) {
		// this is a valid state
		return YES;
	}
	int rc = m_data->check_integrity();
	if(rc != 0) {
		NSLog(@"PanelTable %s - rc: %i  self: %@", _cmd, rc, self);
		return NO;
	}
	return YES;
}

-(void)dealloc {
	delete m_data;
    [super dealloc];
}

@end
