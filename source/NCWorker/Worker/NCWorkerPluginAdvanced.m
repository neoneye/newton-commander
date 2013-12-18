//
// NCWorkerPluginAdvanced.m
// Newton Commander
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "NCWorkerPluginAdvanced.h"
#import "NCDirEnumerator.h"
#import "NCFileItem.h"
#import "NCFileManager.h"
#import "NCLog.h"
#import "sc_transfer.h"
#import "NCFileEventManager.h"

unsigned int map_dirent_to_itemtype3(unsigned int dirent_type) {
	switch(dirent_type) {
	case NCDirEntryTypeUnknown:  
		// happens all the time with FTP connections
		return kNCItemTypeDirGuess;
	case NCDirEntryTypeFifo:     return kNCItemTypeFifo;
	case NCDirEntryTypeChar:     return kNCItemTypeChar;
	case NCDirEntryTypeSocket:   return kNCItemTypeSocket;
	case NCDirEntryTypeBlock:    return kNCItemTypeBlock;
	case NCDirEntryTypeWhiteout: return kNCItemTypeWhiteout;
	case NCDirEntryTypeFile:     return kNCItemTypeFileOrAlias;
	case NCDirEntryTypeDir:      return kNCItemTypeDir;
	case NCDirEntryTypeLink:     return kNCItemTypeLinkToDirGuess;
	}
	LOG_WARNING(@"map_dirent_to_itemtype() - unknown dirent_type %i, guessing it's a dir", (int)dirent_type);
	return kNCItemTypeDirGuess;
}


@interface NCWorkerPluginAdvanced () <NCFileEventManagerDelegate>
-(void)setWorkingDir:(NSString*)path;
-(void)setResolvedWorkingDir:(NSString*)path;

-(NSArray*)sortItems:(NSArray*)items;

-(void)processNext;
-(void)enqueueSelector:(SEL)sel;

-(void)requestList:(NSDictionary*)dict;
-(void)requestPrepareCopy:(NSDictionary*)dict;
-(void)requestExecuteCopy:(NSDictionary*)dict;
-(void)requestAbortCopy:(NSDictionary*)dict;
-(void)requestPrepareMove:(NSDictionary*)dict;
-(void)requestExecuteMove:(NSDictionary*)dict;
-(void)requestAbortMove:(NSDictionary*)dict;

@end

@implementation NCWorkerPluginAdvanced

#pragma mark -
#pragma mark ctor / dtor

- (id)init {
    if(self = [super init]) {
		m_delegate = nil;
		m_queue = [[NSMutableArray alloc] init];
		m_working_dir = nil;
		m_resolved_working_dir = nil;
		m_items = nil;
/*		m_profiler = [[NCTimeProfilerSetWorkingDir alloc] init]; */
		m_copy_operation = nil;
		m_move_operation = nil;
	}
	return self;
}

- (void)dealloc {
	m_delegate = nil;
	
	m_queue = nil;

	m_working_dir = nil;
	
	m_resolved_working_dir = nil;
	
	m_items = nil;

	m_copy_operation = nil;

	m_move_operation = nil;

/*	[m_profiler release];
	m_profiler = nil; */

}

#pragma mark -
#pragma mark Setters and getters

-(void)setDelegate:(id<NCWorkerPluginDelegate>)delegate {
	m_delegate = delegate;
}

-(void)setWorkingDir:(NSString*)path {
	if(m_working_dir != path) {
		m_working_dir = [path copy];
	}
}

-(void)setResolvedWorkingDir:(NSString*)path {
	if(m_resolved_working_dir != path) {
		m_resolved_working_dir = [path copy];
	}
}

-(void)setItems:(NSArray*)items {
	if(m_items != items) {
		m_items = [items copy];
	}
}

#pragma mark -
#pragma mark Queue mechanism

-(void)processNext {
	if([m_queue count] < 1) {
		// LOG_DEBUG(@"%s all events have been processed", _cmd);
		return;
	}
	
	// dequeue the first element
	id obj = [m_queue objectAtIndex:0];
	[m_queue removeObjectAtIndex:0];
	
	// execute it
	if([obj isKindOfClass:[NSInvocation class]]) {
		NSInvocation* inv = (NSInvocation*)obj;
		[inv invoke];
	}

	[self performSelector:@selector(processNext) withObject:nil afterDelay:0];
}

-(void)enqueueSelector:(SEL)sel {
	id obj = self;
	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:sel]];
	[inv setTarget:obj];
	[inv setSelector:sel];
	[m_queue addObject:inv];
}

#pragma mark -
#pragma mark Dispatch events

-(void)request:(NSDictionary*)dict {
	// LOG_DEBUG(@"plugin.request before");
	if(!m_delegate) {
		LOG_ERROR(@"plugin.request - delegate must be initialized, but is nil.");
		return;
	}

	NSString* operation = [dict objectForKey:@"operation"];
	if([operation isEqual:@"list"]) { 
		[self requestList:dict];
	} else
	if([operation isEqual:@"prepareCopy"]) {
		[self requestPrepareCopy:dict];
	} else
	if([operation isEqual:@"executeCopy"]) {
		[self requestExecuteCopy:dict];
	} else
	if([operation isEqual:@"abortCopy"]) {
		[self requestAbortCopy:dict];
	} else
	if([operation isEqual:@"prepareMove"]) {
		[self requestPrepareMove:dict];
	} else
	if([operation isEqual:@"executeMove"]) {
		[self requestExecuteMove:dict];
	} else
	if([operation isEqual:@"abortMove"]) {
		[self requestAbortMove:dict];
	} else {
		LOG_DEBUG(@"requstData unknown operation (%@) - full dump: %@", operation, dict);
	}

	// LOG_DEBUG(@"plugin.request after");
}

#pragma mark -
#pragma mark Copy operation

-(void)requestPrepareCopy:(NSDictionary*)dict {
	// LOG_DEBUG(@"requstData Begin SCAN: %@", dict);

	NSArray* names = [dict objectForKey:@"names"];
	NSString* from_dir = [dict objectForKey:@"fromDir"];
	NSString* to_dir = [dict objectForKey:@"toDir"];
	NSAssert(names, @"must not be nil");
	NSAssert(from_dir, @"must not be nil");
	NSAssert(to_dir, @"must not be nil");
	
/*	LOG_DEBUG(@"fromDir = %@", from_dir);
	LOG_DEBUG(@"toDir = %@", to_dir);
	LOG_DEBUG(@"names = %@", names);*/
	
	if(!m_copy_operation) {
		m_copy_operation = [TransferOperation copyOperation];
		[m_copy_operation setDelegate:self];
	}
	
	[m_copy_operation setFromDir:from_dir];
	[m_copy_operation setToDir:to_dir];
	[m_copy_operation setNames:names];

	[m_copy_operation performScan];
	LOG_DEBUG(@"now scanning...");
}

-(void)requestExecuteCopy:(NSDictionary*)dict {
	// LOG_DEBUG(@"requstData begin TRANSFER: %@", dict);
	NSAssert(m_copy_operation, @"must not be nil. Is supposed to be initialized in the prepareCopy phase.");

	[m_copy_operation performOperation];
	LOG_DEBUG(@"now transfering...");
}

-(void)requestAbortCopy:(NSDictionary*)dict {
	// LOG_DEBUG(@"requstData begin TRANSFER: %@", dict);
	NSAssert(m_copy_operation, @"must not be nil. Is supposed to be initialized in the prepareCopy phase.");

	[m_copy_operation abortOperation];
	LOG_DEBUG(@"aborting...");
}

#pragma mark -
#pragma mark Move operation

-(void)requestPrepareMove:(NSDictionary*)dict {
	// LOG_DEBUG(@"requstData Begin SCAN: %@", dict);

	NSArray* names = [dict objectForKey:@"names"];
	NSString* from_dir = [dict objectForKey:@"fromDir"];
	NSString* to_dir = [dict objectForKey:@"toDir"];
	NSAssert(names, @"must not be nil");
	NSAssert(from_dir, @"must not be nil");
	NSAssert(to_dir, @"must not be nil");
	
/*	LOG_DEBUG(@"fromDir = %@", from_dir);
	LOG_DEBUG(@"toDir = %@", to_dir);
	LOG_DEBUG(@"names = %@", names);*/
	
	if(!m_move_operation) {
		m_move_operation = [TransferOperation moveOperation];
		[m_move_operation setDelegate:self];
	}
	
	[m_move_operation setFromDir:from_dir];
	[m_move_operation setToDir:to_dir];
	[m_move_operation setNames:names];

	[m_move_operation performScan];
	LOG_DEBUG(@"now scanning...");
}

-(void)requestExecuteMove:(NSDictionary*)dict {
	// LOG_DEBUG(@"requstData begin TRANSFER: %@", dict);
	NSAssert(m_move_operation, @"must not be nil. Is supposed to be initialized in the prepareMove phase.");

	[m_move_operation performOperation];
	LOG_DEBUG(@"now transfering...");
}

-(void)requestAbortMove:(NSDictionary*)dict {
	// LOG_DEBUG(@"requstData begin TRANSFER: %@", dict);
	NSAssert(m_move_operation, @"must not be nil. Is supposed to be initialized in the prepareMove phase.");

	[m_move_operation abortOperation];
	LOG_DEBUG(@"aborting...");
}


#pragma mark -
#pragma mark Shared between Copy operation and Move operation

-(void)transferOperation:(TransferOperation*)operation response:(NSDictionary*)dict forKey:(NSString*)key {
	if(!operation) {
		LOG_ERROR(@"expected operation to be either copy or move, but it is nil. Ignoring");
		return;
	}
	if(operation == m_copy_operation) {
		NSArray* keys = [NSArray arrayWithObjects:@"operation", @"response_type", @"response_object", nil];
		NSArray* objects = [NSArray arrayWithObjects:@"copy", key, dict, nil];
		NSDictionary* xdict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
		[m_delegate plugin:self response:xdict];
	} else
	if(operation == m_move_operation) {
		NSArray* keys = [NSArray arrayWithObjects:@"operation", @"response_type", @"response_object", nil];
		NSArray* objects = [NSArray arrayWithObjects:@"move", key, dict, nil];
		NSDictionary* xdict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
		[m_delegate plugin:self response:xdict];
	}
}


#pragma mark -
#pragma mark File system monitoring

-(void)fileEventManager:(NCFileEventManager*)fileEventManager changeOccured:(NSArray*)ary {
	// LOG_DEBUG(@"called: %@", ary);

	{
		// NSData* items_data = [NSArchiver archivedDataWithRootObject:items];
		// NSData* items_data = [NSKeyedArchiver archivedDataWithRootObject:items];

		NSArray* xkeys = [NSArray arrayWithObjects:@"operation", nil];
		NSArray* xobjects = [NSArray arrayWithObjects:@"monitor", nil];
		NSDictionary* xdict = [NSDictionary dictionaryWithObjects:xobjects forKeys:xkeys];

		[m_delegate plugin:self response:xdict];
	}
}


#pragma mark -
#pragma mark List operation

-(void)requestList:(NSDictionary*)dict {
	// LOG_DEBUG(@"requstData LIST");

	NSString* path = [dict objectForKey:@"path"];
	// LOG_DEBUG(@"LIST.path = %@", path);

	[self setWorkingDir:path];

	// remove all pending operations from the queue 
	[m_queue removeAllObjects];

	[self enqueueSelector:@selector(listStep1ResolvePath)];
	[self enqueueSelector:@selector(listStep2ObtainNames)];
	[self enqueueSelector:@selector(listStep3ObtainTypes)];
	[self enqueueSelector:@selector(listStep4AnalyzeLinks)];
	[self enqueueSelector:@selector(listStep5DetectAliases)];
	[self enqueueSelector:@selector(listStep6StatRemainingItems)];
	[self enqueueSelector:@selector(listStep7Spotlight)];
	[self enqueueSelector:@selector(listStep8AccessControlList)];
	[self enqueueSelector:@selector(listStep9ExtendedAttributes)];
/*	[self enqueueSelector:@selector(listStep7WeAreDone)]; */

	[self performSelector:@selector(processNext) withObject:nil afterDelay:0];
}

-(NSArray*)sortItems:(NSArray*)items {
	NSSortDescriptor* sd0 = [[NSSortDescriptor alloc] initWithKey:@"sortItemType"
	    ascending:YES];
	NSSortDescriptor* sd1 = [[NSSortDescriptor alloc] initWithKey:@"name"
		ascending:YES selector:@selector(caseInsensitiveCompare:)];
	NSArray* sds = [NSArray arrayWithObjects:sd0, sd1, nil];
	return [items sortedArrayUsingDescriptors:sds];
}

-(void)listStep1ResolvePath {
	// LOG_DEBUG(@"resolve it");

	// [m_profiler startCounter:@"test"];
	// [m_profiler stopCounter:@"test"];
	
	// [m_profiler startCounter:@"resolvepath"];
	
	NSString* resolved_path = @"/";
	NSFileManager* fm = [NSFileManager defaultManager];
	NCFileManager* ncfm = [NCFileManager shared];
	NSString* path = [ncfm resolvePath:m_working_dir];
	if(path) {
		BOOL isdir = NO;
		BOOL exists = [fm fileExistsAtPath:path isDirectory:&isdir];
		if(exists && isdir)  {
			resolved_path = path;
		}
	}

	[self setResolvedWorkingDir:resolved_path];

	// [m_profiler setObject:resolved_path forKey:@"resolvedpath"];
	// [m_profiler stopCounter:@"resolvepath"];

	// only send a notification when the resolved path is different from the requested path
	if(![resolved_path isEqual:m_working_dir]) {
		// LOG_DEBUG(@"revolved path: %@  ->  %@  -> %@", m_working_dir, path, resolved_path);

		NSArray* xkeys = [NSArray arrayWithObjects:@"operation", @"phase", @"requested_path", @"resolved_path", nil];
		NSArray* xobjects = [NSArray arrayWithObjects:@"list", @"resolveStep", m_working_dir, resolved_path, nil];
		NSDictionary* xdict = [NSDictionary dictionaryWithObjects:xobjects forKeys:xkeys];

		[m_delegate plugin:self response:xdict];
	}
}

-(void)listStep2ObtainNames {
	// LOG_DEBUG(@"listStep2ObtainNames");

	NSString* wdir = m_resolved_working_dir;


	// start monitoring this dir
	if(!m_file_event_manager) {
		m_file_event_manager = [[NCFileEventManager alloc] init];
		[m_file_event_manager setDelegate:self];
	}
	{
		NSArray* paths = [NSArray arrayWithObject:wdir];
		[m_file_event_manager setPathsToWatch:paths];
		[m_file_event_manager start];
		// LOG_DEBUG(@"now monitoring: %@", paths);
	}


	NCDirEnumerator* e = [NCDirEnumerator enumeratorWithPath:wdir];
	if(!e) {
		LOG_ERROR(@"cannot create enumerator for path");
		return;
	}

	NSMutableArray* items = [NSMutableArray arrayWithCapacity:10000];
	NCDirEntry* entry;
	while ( (entry = [e nextObject]) ) {
		NSString* name = [entry name];
		unsigned char dirent_type = [entry direntType];
		unsigned long long inode = [entry inode];

		if([name isEqual:@"."]) continue;
		if([name isEqual:@".."]) continue;
		
		NCFileItem* item = [[NCFileItem alloc] init];
		[item setName:name];
		[item setInode:inode];
		[item setDirentType:dirent_type];
		[item setItemType:map_dirent_to_itemtype3(dirent_type)];
		[item setOwner:@"?"];
		[item setGroup:@"?"];
		[items addObject:item];
	}
	// LOG_DEBUG(@"worker.listStep2ObtainNames %@ -> %@", wdir, items);

	[self setItems:[self sortItems:items]];

	{
		NSData* items_data = [NSArchiver archivedDataWithRootObject:items];
		// NSData* items_data = [NSKeyedArchiver archivedDataWithRootObject:items];

		NSArray* xkeys = [NSArray arrayWithObjects:@"operation", @"phase", @"path", @"items", nil];
		NSArray* xobjects = [NSArray arrayWithObjects:@"list", @"obtainNames", wdir, items_data, nil];
		NSDictionary* xdict = [NSDictionary dictionaryWithObjects:xobjects forKeys:xkeys];

		[m_delegate plugin:self response:xdict];
	}
}

/*
This function only makes sense when you consider FTP mounted volumes.
*/
-(void)listStep3ObtainTypes {
	// LOG_DEBUG(@"listStep3ObtainTypes");
	// [m_profiler startCounter:@"obtaintypes"];

	/*
	when browsing via FTP, then NCDirEnumerator cannot determine wether an item
	is a file or a dir. In this step we try determine type of item we are dealing with.
	*/
	if(!m_items) return; // bail out when operation has been cancelled

	NSString* wdir = m_resolved_working_dir;
	//NSFileManager* fm = [NSFileManager defaultManager];
	NCFileManager* ncfm = [NCFileManager shared];

	NSEnumerator* e = [m_items objectEnumerator];
	NCFileItem* item;
	while((item = [e nextObject])) {
		int itemtype = [item itemType];
		NSString* name = [item name];
		
		if(itemtype != kNCItemTypeDirGuess) {
			/*
			itemtype is already obtained successfully. Usually the case when browsing
			a local mounted file system, but rarely the case with remotely mounted file systems.
			*/
			// LOG_DEBUG(@"type is good for name: %@", name);
			continue;
		}

		// LOG_DEBUG(@"obtaining types for name: %@", name);
	
		NSString* path = [wdir stringByAppendingPathComponent:name];
		NSDictionary* dict = [ncfm attributesOfItemAtPath:path error:NULL];
		NSString* filetype = [dict objectForKey:NCFileType];
		if([filetype isEqual:NCFileTypeDirectory]) {
			[item setItemType:kNCItemTypeDir];
		} else
		if([filetype isEqual:NCFileTypeRegular]) {
			[item setItemType:kNCItemTypeFile];
		} else
		if([filetype isEqual:NCFileTypeSymbolicLink]) {
			[item setItemType:kNCItemTypeLinkToDirGuess];
		} else
		if([filetype isEqual:NCFileTypeFIFO]) {
			[item setItemType:kNCItemTypeFifo];
		} else
		if([filetype isEqual:NCFileTypeWhiteout]) {
			[item setItemType:kNCItemTypeWhiteout];
		} else
		if([filetype isEqual:NCFileTypeSocket]) {
			[item setItemType:kNCItemTypeSocket];
		} else
		if([filetype isEqual:NCFileTypeCharacterSpecial]) {
			[item setItemType:kNCItemTypeChar];
		} else
		if([filetype isEqual:NCFileTypeBlockSpecial]) {
			[item setItemType:kNCItemTypeBlock];
		} else {
			[item setItemType:kNCItemTypeDirGuess];
		}
	}
	[self setItems:[self sortItems:m_items]];

	{
		NSData* items_data = [NSArchiver archivedDataWithRootObject:m_items];
		// NSData* items_data = [NSKeyedArchiver archivedDataWithRootObject:items];

		NSArray* xkeys = [NSArray arrayWithObjects:@"operation", @"phase", @"path", @"items", nil];
		NSArray* xobjects = [NSArray arrayWithObjects:@"list", @"ObtainTypes", wdir, items_data, nil];
		NSDictionary* xdict = [NSDictionary dictionaryWithObjects:xobjects forKeys:xkeys];

		[m_delegate plugin:self response:xdict];
	}

	// [m_profiler stopCounter:@"obtaintypes"];
}

-(void)listStep4AnalyzeLinks {
	// [m_profiler startCounter:@"analyzelinks"];
	// LOG_DEBUG(@"listStep4AnalyzeLinks");
	
	/*
	determine wether a link point to a file or a dir or something else
	*/
	if(!m_items) return; // bail out when operation has been cancelled

	NSString* wdir = m_resolved_working_dir;
	//NSFileManager* fm = [NSFileManager defaultManager];
	NCFileManager* ncfm = [NCFileManager shared];

	NSEnumerator* e = [m_items objectEnumerator];
	NCFileItem* item;
	while((item = [e nextObject])) {
		int itemtype = [item itemType];
		NSString* name = [item name];
		
		if(itemtype != kNCItemTypeLinkToDirGuess) {
			continue;
		}
		
		NSString* path = [wdir stringByAppendingPathComponent:name];
		NSString* path2 = [ncfm resolvePath:path];
		
		if(!path2) {
			[item setItemType:kNCItemTypeLinkIsBroken];
			continue;
		}

		NSDictionary* dict = [ncfm attributesOfItemAtPath:path2 error:NULL];

		NSString* filetype = [dict objectForKey:NCFileType];
		if([filetype isEqual:NCFileTypeDirectory]) {
	        NSNumber* refcount = [dict objectForKey:NCFileReferenceCount];
			int count = 0;
			if(refcount != nil) {
				count = [refcount intValue] - 2;
			}
			if(count < 0) count = 0;
			[item setItemCount:count];
		} else {
        	NSNumber* filesize = [dict objectForKey:NCFileSize];
			[item setSize:[filesize unsignedLongLongValue]];
		}

		if([filetype isEqual:NCFileTypeDirectory]) {
			[item setItemType:kNCItemTypeLinkToDir];
		} else
		if([filetype isEqual:NCFileTypeRegular]) {
			[item setItemType:kNCItemTypeLinkToFile];
		} else {
			[item setItemType:kNCItemTypeLinkToOther];
		}

		{
        	NSString* s = [dict objectForKey:NCFileGroupOwnerAccountName];
			[item setGroup:s];
		}

		{
        	NSString* s = [dict objectForKey:NCFileOwnerAccountName];
			[item setOwner:s];
		}

		{
        	id obj = [dict objectForKey:NCFilePosixPermissions];
			[item setPosixPermissions:[obj unsignedLongValue]];
		}

		{
			[item setAccessDate:[dict objectForKey:NCFileAccessDate]];
			[item setContentModificationDate:[dict objectForKey:NCFileContentModificationDate]];
			[item setAttributeModificationDate:[dict objectForKey:NCFileAttributeModificationDate]];
			[item setCreationDate:[dict objectForKey:NCFileCreationDate]];
			[item setBackupDate:[dict objectForKey:NCFileBackupDate]];
		}

	}
	[self setItems:[self sortItems:m_items]];

	{
		NSData* items_data = [NSArchiver archivedDataWithRootObject:m_items];
		// NSData* items_data = [NSKeyedArchiver archivedDataWithRootObject:items];

		NSArray* xkeys = [NSArray arrayWithObjects:@"operation", @"phase", @"path", @"items", nil];
		NSArray* xobjects = [NSArray arrayWithObjects:@"list", @"AnalyzeLinks", wdir, items_data, nil];
		NSDictionary* xdict = [NSDictionary dictionaryWithObjects:xobjects forKeys:xkeys];

		[m_delegate plugin:self response:xdict];
	}
	// [m_profiler stopCounter:@"analyzelinks"];
}

-(void)listStep5DetectAliases {
	// [m_profiler startCounter:@"detectaliases"];
	// LOG_DEBUG(@"listStep5DetectAliases");
	
	if(!m_items) return; // bail out when operation has been cancelled

	NSString* wdir = m_resolved_working_dir;
	//NSFileManager* fm = [NSFileManager defaultManager];
	NCFileManager* ncfm = [NCFileManager shared];

	NSEnumerator* e = [m_items objectEnumerator];
	NCFileItem* item;
	while((item = [e nextObject])) {
		int itemtype = [item itemType];
		NSString* name = [item name];
		
		if(itemtype != kNCItemTypeFileOrAlias) {
			continue;
		}
		// LOG_DEBUG(@"%s analyzing: %@", _cmd, name);

		NSString* path = [wdir stringByAppendingPathComponent:name];

		// determine if it's a file or an alias
		int alias_type = -1;
		NSString* target_path = [ncfm resolveAlias:path mode:&alias_type];
		if(!target_path) {
			[item setItemType:kNCItemTypeFile];
			continue;
		}

		// detect if the alias is broken
		NSString* path2 = [ncfm resolvePath:path];
		if(!path2) {
			[item setItemType:kNCItemTypeAliasIsBroken];
			continue;
		}

		NSDictionary* dict = [ncfm attributesOfItemAtPath:path2 error:NULL];

		NSString* filetype = [dict objectForKey:NCFileType];
		if([filetype isEqual:NCFileTypeDirectory]) {
	        NSNumber* refcount = [dict objectForKey:NCFileReferenceCount];
			int count = 0;
			if(refcount != nil) {
				count = [refcount intValue] - 2;
			}
			if(count < 0) count = 0;
			[item setItemCount:count];
		} else {
        	NSNumber* filesize = [dict objectForKey:NCFileSize];
			[item setSize:[filesize unsignedLongLongValue]];
		}

		if([filetype isEqual:NCFileTypeDirectory]) {
			[item setItemType:kNCItemTypeAliasToDir];
		} else
		// if([filetype isEqual:NCFileTypeRegular]) 
		{
			[item setItemType:kNCItemTypeAliasToFile];
		// } else {
			// [item setItemType:kNCItemTypeAliasToOther];
		}

		{
        	NSString* s = [dict objectForKey:NCFileGroupOwnerAccountName];
			[item setGroup:s];
		}

		{
        	NSString* s = [dict objectForKey:NCFileOwnerAccountName];
			[item setOwner:s];
		}

		{
        	id obj = [dict objectForKey:NCFilePosixPermissions];
			[item setPosixPermissions:[obj unsignedLongValue]];
		}

		{
			[item setAccessDate:[dict objectForKey:NCFileAccessDate]];
			[item setContentModificationDate:[dict objectForKey:NCFileContentModificationDate]];
			[item setAttributeModificationDate:[dict objectForKey:NCFileAttributeModificationDate]];
			[item setCreationDate:[dict objectForKey:NCFileCreationDate]];
			[item setBackupDate:[dict objectForKey:NCFileBackupDate]];
		}
	}
	[self setItems:[self sortItems:m_items]];

	{
		NSData* items_data = [NSArchiver archivedDataWithRootObject:m_items];
		// NSData* items_data = [NSKeyedArchiver archivedDataWithRootObject:items];

		NSArray* xkeys = [NSArray arrayWithObjects:@"operation", @"phase", @"path", @"items", nil];
		NSArray* xobjects = [NSArray arrayWithObjects:@"list", @"DetectAliases", wdir, items_data, nil];
		NSDictionary* xdict = [NSDictionary dictionaryWithObjects:xobjects forKeys:xkeys];

		[m_delegate plugin:self response:xdict];
	}
	// [m_profiler stopCounter:@"detectaliases"];
}

-(void)listStep6StatRemainingItems {
	// [m_profiler startCounter:@"statremaining"];
	// LOG_DEBUG(@"step6StatRemainingItems");
	
	NSArray* items = m_items;
	if(!m_items) return; // bail out when operation has been cancelled

	NSString* wdir = m_resolved_working_dir;
	NCFileManager* ncfm = [NCFileManager shared];

	NSEnumerator* e = [items objectEnumerator];
	NCFileItem* item;
	while((item = [e nextObject])) {
		int itemtype = [item itemType];
		NSString* name = [item name];
		
		if(itemtype == kNCItemTypeGoBack) {
			NSString* path2 = [wdir stringByDeletingLastPathComponent];
			NSDictionary* dict2 = [ncfm attributesOfItemAtPath:path2 error:NULL];
	        NSNumber* refcount = [dict2 objectForKey:NCFileReferenceCount];
			// LOG_DEBUG(@"%s go back: %@ %@ %@", _cmd, path2, dict2, refcount);
			int count = 0;
			if(refcount != nil) {
				count = [refcount intValue] - 2;
			}
			if(count < 0) count = 0;
			[item setItemCount:count];
			continue;
		}


		NSString* path = [wdir stringByAppendingPathComponent:name];
		NSError* error = nil;
		NSDictionary* dict = [ncfm attributesOfItemAtPath:path error:&error];
		if(error) {
			LOG_DEBUG(@"ERROR in attributesOfItemAtPath: %@  error: %@", path, error);
			continue;
		}

        NSNumber* n_refcount = [dict objectForKey:NCFileReferenceCount];
		int refcount = [n_refcount intValue];
		[item setReferenceCount:refcount];


		if([[dict objectForKey:NCFileType] isEqual:NCFileTypeDirectory]) {
			/*
			IDEA: alternatively use kMDItemFSNodeCount
			*/
			int count = 0;
			if(n_refcount != nil) {
				count = refcount - 2;
			}
			if(count < 0) count = 0;
			[item setItemCount:count];
		} else {
        	NSNumber* obj = [dict objectForKey:NCFileSize];
			[item setSize:[obj unsignedLongLongValue]];
		}

		{
        	NSString* obj = [dict objectForKey:NCFileGroupOwnerAccountName];
			[item setGroup:obj];
		}

		{
        	NSString* obj = [dict objectForKey:NCFileOwnerAccountName];
			[item setOwner:obj];
		}

		{
        	id obj = [dict objectForKey:NCFilePosixPermissions];
			[item setPosixPermissions:[obj unsignedLongValue]];
		}

		{
        	id obj = [dict objectForKey:NCFileSystemFileNumber];
			[item setInode:[obj unsignedLongValue]];
		}

		{
			[item setAccessDate:[dict objectForKey:NCFileAccessDate]];
			[item setContentModificationDate:[dict objectForKey:NCFileContentModificationDate]];
			[item setAttributeModificationDate:[dict objectForKey:NCFileAttributeModificationDate]];
			[item setCreationDate:[dict objectForKey:NCFileCreationDate]];
			[item setBackupDate:[dict objectForKey:NCFileBackupDate]];
		}

		{
        	NSNumber* obj = [dict objectForKey:NCFileFlags];
			[item setFlags:[obj unsignedLongValue]];
		}
	}

	{
		NSData* items_data = [NSArchiver archivedDataWithRootObject:m_items];
		// NSData* items_data = [NSKeyedArchiver archivedDataWithRootObject:items];

		NSArray* xkeys = [NSArray arrayWithObjects:@"operation", @"phase", @"path", @"items", nil];
		NSArray* xobjects = [NSArray arrayWithObjects:@"list", @"StatRemainingItems", wdir, items_data, nil];
		NSDictionary* xdict = [NSDictionary dictionaryWithObjects:xobjects forKeys:xkeys];

		[m_delegate plugin:self response:xdict];
	}

	// [m_profiler stopCounter:@"statremaining"];
}

-(void)listStep7Spotlight {
	// [m_profiler startCounter:@"spotlight"];
	// LOG_DEBUG(@"listStep7Spotlight");
	
	NSArray* items = m_items;
	if(!m_items) return; // bail out when operation has been cancelled

	NSString* wdir = m_resolved_working_dir;
	NCFileManager* ncfm = [NCFileManager shared];

	NSEnumerator* e = [items objectEnumerator];
	NCFileItem* item;
	while((item = [e nextObject])) {
		int itemtype = [item itemType];
		NSString* name = [item name];
		
		if(itemtype == kNCItemTypeGoBack) {
			// IDEA: set kind/contenttype/comment for parent dir as well
			continue;
		}


		NSString* path = [wdir stringByAppendingPathComponent:name];
		NSDictionary* dict = [ncfm spotlightAttributesOfItemAtPath:path error:NULL];
		if(!dict) {
			LOG_DEBUG(@"no spotlight info for file: %@", path);
		}
		// LOG_DEBUG(@"file: %@  spotlight: %@", path, dict);

		{
        	NSString* value = [dict objectForKey:NCSpotlightKind];
			// value = @"poxciuv";
			[item setKind:value];
		}

		{
        	NSString* value = [dict objectForKey:NCSpotlightContentType];
			[item setContentType:value];
		}

		{
        	NSString* value = [dict objectForKey:NCSpotlightFinderComment];
			[item setComment:value];
		}
	}

	{
		NSData* items_data = [NSArchiver archivedDataWithRootObject:m_items];
		// NSData* items_data = [NSKeyedArchiver archivedDataWithRootObject:items];

		NSArray* xkeys = [NSArray arrayWithObjects:@"operation", @"phase", @"path", @"items", nil];
		NSArray* xobjects = [NSArray arrayWithObjects:@"list", @"Spotlight", wdir, items_data, nil];
		NSDictionary* xdict = [NSDictionary dictionaryWithObjects:xobjects forKeys:xkeys];

		[m_delegate plugin:self response:xdict];
	}

	// [m_profiler stopCounter:@"spotlight"];
}

#pragma mark -

-(void)listStep8AccessControlList {
	// [m_profiler startCounter:@"acl"];
	// LOG_DEBUG(@"listStep8AccessControlList");
	
	NSArray* items = m_items;
	if(!m_items) return; // bail out when operation has been cancelled

	NSString* wdir = m_resolved_working_dir;
	NCFileManager* ncfm = [NCFileManager shared];

	NSEnumerator* e = [items objectEnumerator];
	NCFileItem* item;
	while((item = [e nextObject])) {
		int itemtype = [item itemType];
		NSString* name = [item name];
		
		if(itemtype == kNCItemTypeGoBack) {
			[item setAclCount:0];
			continue;
		}


		NSString* path = [wdir stringByAppendingPathComponent:name];
		NSDictionary* dict = [ncfm aclForItemAtPath:path error:NULL];
		
		// LOG_DEBUG(@"file: %@  acl: %@", path, dict);
		int count = (dict != nil) ? 1 : 0;
		[item setAclCount:count];
	}

	{
		NSData* items_data = [NSArchiver archivedDataWithRootObject:m_items];
		// NSData* items_data = [NSKeyedArchiver archivedDataWithRootObject:items];

		NSArray* xkeys = [NSArray arrayWithObjects:@"operation", @"phase", @"path", @"items", nil];
		NSArray* xobjects = [NSArray arrayWithObjects:@"list", @"AccessControlList", wdir, items_data, nil];
		NSDictionary* xdict = [NSDictionary dictionaryWithObjects:xobjects forKeys:xkeys];

		[m_delegate plugin:self response:xdict];
	}

	// [m_profiler stopCounter:@"acl"];
}

-(void)listStep9ExtendedAttributes {
	// [m_profiler startCounter:@"xattr"];
	// LOG_DEBUG(@"listStep9ExtendedAttributes");
	
	NSArray* items = m_items;
	if(!m_items) return; // bail out when operation has been cancelled

	NSString* wdir = m_resolved_working_dir;
	NCFileManager* ncfm = [NCFileManager shared];

	NSEnumerator* e = [items objectEnumerator];
	NCFileItem* item;
	while((item = [e nextObject])) {
		int itemtype = [item itemType];
		NSString* name = [item name];
		
		if(itemtype == kNCItemTypeGoBack) {
			[item setXattrCount:0];
			continue;
		}


		NSString* path = [wdir stringByAppendingPathComponent:name];
		NSDictionary* dict = [ncfm extendedAttributesOfItemAtPath:path error:NULL];
		int count = 0;
		if(dict) {
			// LOG_DEBUG(@"file: %@  xattr: %@", path, dict);
			count = [[dict objectForKey:@"Count"] unsignedIntegerValue];
		}
		[item setXattrCount:count];
		
		
		unsigned long long rsrc_size = 0;
		if([item direntType] != NCDirEntryTypeDir) {
			rsrc_size = [ncfm sizeOfResourceFork:path];
		}
		[item setResourceForkSize:rsrc_size];
	}

	{
		NSData* items_data = [NSArchiver archivedDataWithRootObject:m_items];
		// NSData* items_data = [NSKeyedArchiver archivedDataWithRootObject:items];

		NSArray* xkeys = [NSArray arrayWithObjects:@"operation", @"phase", @"path", @"items", nil];
		NSArray* xobjects = [NSArray arrayWithObjects:@"list", @"last", wdir, items_data, nil];
		NSDictionary* xdict = [NSDictionary dictionaryWithObjects:xobjects forKeys:xkeys];

		[m_delegate plugin:self response:xdict];
	}

	// [m_profiler stopCounter:@"xattr"];
}

@end
