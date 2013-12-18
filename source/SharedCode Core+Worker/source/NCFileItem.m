//
// NCFileItem.m
// Newton Commander
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "NCFileItem.h"


@implementation NCFileItem

@synthesize direntType = m_dirent_type;
@synthesize itemType = m_item_type;
@synthesize name = m_name;
@synthesize link = m_link;
@synthesize size = m_size;
@synthesize resourceForkSize = m_resource_fork_size;
@synthesize inode = m_inode;
@synthesize flags = m_flags;
@synthesize aclCount = m_acl_count;
@synthesize xattrCount = m_xattr_count;
@synthesize referenceCount = m_reference_count;
@synthesize itemCount = m_item_count;
@synthesize group = m_group;
@synthesize owner = m_owner;
@synthesize posixPermissions = m_posix_permissions;
@synthesize kind = m_kind;
@synthesize contentType = m_content_type;
@synthesize comment = m_comment;
@synthesize accessDate = m_access_date;
@synthesize contentModificationDate = m_content_modification_date;
@synthesize attributeModificationDate = m_attribute_modification_date;
@synthesize creationDate = m_creation_date;
@synthesize backupDate = m_backup_date;

-(id)initWithCoder:(NSCoder*)coder {
    if (self = [super init]) {
		if([coder allowsKeyedCoding]) {
	        m_dirent_type = [coder decodeIntForKey: @"direntType"];
	        m_item_type = [coder decodeIntForKey: @"itemType"];
	        m_name = [coder decodeObjectForKey: @"name"];
	        m_link = [coder decodeObjectForKey: @"link"];
	        m_size = [coder decodeInt64ForKey: @"dataSize"];
	        m_resource_fork_size = [coder decodeInt64ForKey: @"rsrcSize"];
	        m_inode = [coder decodeInt64ForKey: @"inode"];
	        m_flags = [coder decodeIntForKey: @"flags"];
	        m_reference_count = [coder decodeIntForKey: @"refCount"];
	        m_item_count = [coder decodeIntForKey: @"itemCount"];
	        m_acl_count = [coder decodeIntForKey: @"aclCount"];
	        m_xattr_count = [coder decodeIntForKey: @"xattrCount"];
	        m_group = [coder decodeObjectForKey: @"group"];
	        m_owner = [coder decodeObjectForKey: @"owner"];
	        m_posix_permissions = [coder decodeIntForKey: @"posixPerm"];
	        m_kind = [coder decodeObjectForKey: @"kind"];
	        m_content_type = [coder decodeObjectForKey: @"contentType"];
	        m_comment = [coder decodeObjectForKey: @"comment"];
	        m_access_date = [coder decodeObjectForKey: @"accessDate"];
	        m_content_modification_date = [coder decodeObjectForKey: @"contentModDate"];
	        m_attribute_modification_date = [coder decodeObjectForKey: @"attrModDate"];
	        m_creation_date = [coder decodeObjectForKey: @"createDate"];
	        m_backup_date = [coder decodeObjectForKey: @"backupDate"];
		} else {
			[coder decodeValueOfObjCType:@encode(unsigned char) at:&m_dirent_type];
			[coder decodeValueOfObjCType:@encode(int) at:&m_item_type];
	        m_name = [coder decodeObject];    
	        m_link = [coder decodeObject];
			[coder decodeValueOfObjCType:@encode(unsigned long long) at:&m_size];
			[coder decodeValueOfObjCType:@encode(unsigned long long) at:&m_resource_fork_size];
			[coder decodeValueOfObjCType:@encode(unsigned long long) at:&m_inode];
			[coder decodeValueOfObjCType:@encode(unsigned long) at:&m_flags];
			[coder decodeValueOfObjCType:@encode(int) at:&m_reference_count];
			[coder decodeValueOfObjCType:@encode(int) at:&m_item_count];     
			[coder decodeValueOfObjCType:@encode(int) at:&m_acl_count];
			[coder decodeValueOfObjCType:@encode(int) at:&m_xattr_count];
	        m_group = [coder decodeObject];    
	        m_owner = [coder decodeObject];                   
			[coder decodeValueOfObjCType:@encode(int) at:&m_posix_permissions];
	        m_kind = [coder decodeObject];    
	        m_content_type = [coder decodeObject];    
	        m_comment = [coder decodeObject];    
	        m_access_date = [coder decodeObject];    
	        m_content_modification_date = [coder decodeObject];    
	        m_attribute_modification_date = [coder decodeObject];    
	        m_creation_date = [coder decodeObject];    
	        m_backup_date = [coder decodeObject];    
		}
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder*)coder {
	if([coder allowsKeyedCoding]) {
	    [coder encodeInt:m_dirent_type forKey: @"direntType"];
	    [coder encodeInt:m_item_type forKey: @"itemType"];
	    [coder encodeObject:m_name forKey: @"name"];
	    [coder encodeObject:m_link forKey: @"link"];
	    [coder encodeInt64:m_size forKey: @"dataSize"];
	    [coder encodeInt64:m_resource_fork_size forKey: @"rsrcSize"];
	    [coder encodeInt64:m_inode forKey: @"inode"];
	    [coder encodeInt:m_flags forKey: @"flags"];
	    [coder encodeInt:m_reference_count forKey: @"refCount"];
	    [coder encodeInt:m_item_count forKey: @"itemCount"];             
	    [coder encodeInt:m_acl_count forKey: @"aclCount"];      
	    [coder encodeInt:m_xattr_count forKey: @"xattrCount"];
	    [coder encodeObject:m_group forKey: @"group"];
	    [coder encodeObject:m_owner forKey: @"owner"];
	    [coder encodeInt:m_posix_permissions forKey: @"posixPerm"];
	    [coder encodeObject:m_kind forKey: @"kind"];
	    [coder encodeObject:m_content_type forKey: @"contentType"];
	    [coder encodeObject:m_comment forKey: @"comment"];
	    [coder encodeObject:m_access_date forKey: @"accessDate"];
	    [coder encodeObject:m_content_modification_date forKey: @"contentModDate"];
	    [coder encodeObject:m_attribute_modification_date forKey: @"attrModDate"];
	    [coder encodeObject:m_creation_date forKey: @"createDate"];
	    [coder encodeObject:m_backup_date forKey: @"backupDate"];
	} else {
		[coder encodeValueOfObjCType:@encode(unsigned char) at:&m_dirent_type];
		[coder encodeValueOfObjCType:@encode(int) at:&m_item_type];
	    [coder encodeObject:m_name];              
	    [coder encodeObject:m_link];
		[coder encodeValueOfObjCType:@encode(unsigned long long) at:&m_size];
		[coder encodeValueOfObjCType:@encode(unsigned long long) at:&m_resource_fork_size];
		[coder encodeValueOfObjCType:@encode(unsigned long long) at:&m_inode];
		[coder encodeValueOfObjCType:@encode(unsigned long) at:&m_flags];
		[coder encodeValueOfObjCType:@encode(int) at:&m_reference_count];
		[coder encodeValueOfObjCType:@encode(int) at:&m_item_count];
		[coder encodeValueOfObjCType:@encode(int) at:&m_acl_count];
		[coder encodeValueOfObjCType:@encode(int) at:&m_xattr_count];
	    [coder encodeObject:m_group];
	    [coder encodeObject:m_owner];                             
		[coder encodeValueOfObjCType:@encode(int) at:&m_posix_permissions];
	    [coder encodeObject:m_kind]; 
	    [coder encodeObject:m_content_type]; 
	    [coder encodeObject:m_comment]; 
	    [coder encodeObject:m_access_date];        
	    [coder encodeObject:m_content_modification_date];        
	    [coder encodeObject:m_attribute_modification_date];        
	    [coder encodeObject:m_creation_date];              
	    [coder encodeObject:m_backup_date];
	}
}

- (id)copyWithZone:(NSZone*)zone {
	NCFileItem* item = [[[self class] allocWithZone:zone] init];
	if(!item) return nil;
    [item setItemType:m_item_type];
    [item setName:m_name];
    [item setLink:m_link];
    [item setSize:m_size];
    [item setResourceForkSize:m_resource_fork_size];
    [item setInode:m_inode];
    [item setFlags:m_flags];
    [item setReferenceCount:m_reference_count];
    [item setItemCount:m_item_count];
    [item setAclCount:m_acl_count];
    [item setXattrCount:m_xattr_count];
    [item setGroup:m_group];
    [item setOwner:m_owner];
    [item setPosixPermissions:m_posix_permissions];
    [item setKind:m_kind];         
    [item setContentType:m_content_type];
    [item setComment:m_comment];
    [item setAccessDate:m_access_date];
    [item setContentModificationDate:m_content_modification_date];
    [item setAttributeModificationDate:m_attribute_modification_date];
    [item setCreationDate:m_creation_date];
    [item setBackupDate:m_backup_date];
    return item;
}

-(NSURL*)urlInWorkingDir:(NSString*)wdir {
	BOOL isdir = YES;
	switch(m_item_type) {
	case kNCItemTypeFile:  
	case kNCItemTypeFifo:  
	case kNCItemTypeChar:  
	case kNCItemTypeBlock:  
	case kNCItemTypeSocket:  
	case kNCItemTypeWhiteout:  
	case kNCItemTypeLinkToFile:  
	case kNCItemTypeLinkToOther:  
	case kNCItemTypeAliasToFile:
	case kNCItemTypeFileOrAlias:
		isdir = NO;
	}
	NSString* path = [wdir stringByAppendingPathComponent:m_name];
	return [NSURL fileURLWithPath:path isDirectory:isdir];
}

-(BOOL)countsAsDirectory {
	int itemtype = self.itemType;
	switch(itemtype) {
	case kNCItemTypeUnknown:
	case kNCItemTypeDirGuess:
	case kNCItemTypeDir:
	case kNCItemTypeLinkToDirGuess:
	case kNCItemTypeLinkToDir:
	case kNCItemTypeAliasToDir:
		return YES;
	}
	/*
	kNCItemTypeNone, kNCItemTypeFile, kNCItemTypeFifo, etc..
	*/
	return NO;
}

-(BOOL)countsAsFile {
	int itemtype = self.itemType;
	switch(itemtype) {
	case kNCItemTypeFile:  
	case kNCItemTypeFifo:  
	case kNCItemTypeChar:  
	case kNCItemTypeBlock:  
	case kNCItemTypeSocket:  
	case kNCItemTypeWhiteout:  
	case kNCItemTypeLinkToFile:  
	case kNCItemTypeLinkToOther:  
	case kNCItemTypeLinkIsBroken:
	case kNCItemTypeFileOrAlias:
	case kNCItemTypeAliasToFile:
	case kNCItemTypeAliasIsBroken:
		return YES;
	}
	/*
	kNCItemTypeNone, kNCItemTypeDir, kNCItemTypeDirGuess, etc..
	*/
	return NO;
}

-(int)sizeColumnMode {
	int itemtype = self.itemType;
	switch(itemtype) {
	case kNCItemTypeNone:
	case kNCItemTypeUnknown:
	case kNCItemTypeDirGuess:
	case kNCItemTypeDir:
	case kNCItemTypeLinkToDirGuess:
	case kNCItemTypeLinkToDir:
	case kNCItemTypeAliasToDir:
	case kNCItemTypeGoBack:
		return 1; // show item-count based on number of hardlinks
	}
	
	// show file size in bytes
	return 0;
}

-(NSString*)iconColumnText {
	int itemtype = self.itemType;
	switch(itemtype) {
	case kNCItemTypeUnknown:
	case kNCItemTypeDirGuess:
	case kNCItemTypeDir:
	case kNCItemTypeLinkToDirGuess:
	case kNCItemTypeLinkToDir:
	case kNCItemTypeAliasToDir:
		return @"D";
	}
	/*
	kNCItemTypeNone, kNCItemTypeFile, kNCItemTypeFifo, kNCItemTypeFileOrAlias, etc..
	*/
	return @"F";
}

-(int)sortItemType {
	int itemtype = self.itemType;
	switch(itemtype) {
	case kNCItemTypeGoBack:
		return 0;
	case kNCItemTypeUnknown:
	case kNCItemTypeDirGuess:
	case kNCItemTypeDir:
	case kNCItemTypeLinkToDirGuess:
	case kNCItemTypeLinkToDir:
	case kNCItemTypeAliasToDir:
		return 1;
	}
	return 100;
}

-(NSString*)description {
	return [NSString stringWithFormat:@"FileItem: type: %i name: '%@'", 
		(int)m_item_type, m_name];
}

@end
