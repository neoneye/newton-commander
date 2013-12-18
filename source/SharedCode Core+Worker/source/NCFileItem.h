//
// NCFileItem.h
// Newton Commander
//
#import <Foundation/Foundation.h>

enum {
	// uninitialized - we have not received any data from backend
	kNCItemTypeNone = 0,
	
	// the backend tells us that this is an unknown type
	kNCItemTypeUnknown,

	// go back to previous dir, either the [..] item or the [back]
	kNCItemTypeGoBack,
	
	// until the exact type is fully resolved we assume it's a directory
	kNCItemTypeDirGuess,

	// until a file have been made sure that it's not an dir alias
	kNCItemTypeFileOrAlias,

	kNCItemTypeDir,
	kNCItemTypeFile,  
	kNCItemTypeFifo,  
	kNCItemTypeChar,  
	kNCItemTypeBlock,  
	kNCItemTypeSocket,  
	kNCItemTypeWhiteout,  

	// until the exact type is fully resolved we assume it's a directory
	kNCItemTypeLinkToDirGuess,
	kNCItemTypeLinkToDir,
	kNCItemTypeLinkToFile,  
	kNCItemTypeLinkToOther,  
	kNCItemTypeLinkIsBroken,

	kNCItemTypeAliasToDir,
	kNCItemTypeAliasToFile,
	// TODO: can alias point to sockets/fifos/char/block/etc. ?
	kNCItemTypeAliasIsBroken,
};

@interface NCFileItem : NSObject <NSCopying, NSCoding> {
	unsigned char m_dirent_type;

	int m_item_type;
	
	// the file name
	NSString* m_name;
	
	// for links/aliases: the path that the link resolves to
	NSString* m_link;
	
	// size of the file data in bytes
	unsigned long long m_size;
	
	// size of the resource fork in bytes
	unsigned long long m_resource_fork_size;

	unsigned long long m_inode;
	
	unsigned long m_flags;
	
	int m_reference_count; // number of hardlinks
	
	int m_item_count; // number of items in dir.. TODO: get rid of this, instead derive this from reference_count 

	int m_acl_count; // number of ACL rules
	int m_xattr_count; // number of extended attributes (xattr)
	
	NSString* m_group;
	NSString* m_owner;
	NSUInteger m_posix_permissions;
	
	NSString* m_kind;
	NSString* m_content_type;
	NSString* m_comment;

	NSDate* m_access_date;
	NSDate* m_content_modification_date;   
	NSDate* m_attribute_modification_date;   
	NSDate* m_creation_date;
	NSDate* m_backup_date;
}
@property unsigned char direntType;
@property int itemType;
@property (copy) NSString* name;
@property (copy) NSString* link;
@property unsigned long long inode;
@property unsigned long long size;  
@property unsigned long long resourceForkSize;  
@property unsigned long flags;
@property int referenceCount;
@property int itemCount;                        
@property int aclCount;
@property int xattrCount;
@property (copy) NSString* group;
@property (copy) NSString* owner;
@property NSUInteger posixPermissions;
@property (copy) NSString* kind;
@property (copy) NSString* contentType;
@property (copy) NSString* comment;
@property (copy) NSDate* accessDate;
@property (copy) NSDate* contentModificationDate;
@property (copy) NSDate* attributeModificationDate;
@property (copy) NSDate* creationDate;
@property (copy) NSDate* backupDate;

-(NSURL*)urlInWorkingDir:(NSString*)wdir;

/*
treat this item as a dir or as a file when summing file size and dir count
*/
-(BOOL)countsAsDirectory;
-(BOOL)countsAsFile;


-(int)sizeColumnMode;

-(NSString*)iconColumnText;

-(int)sortItemType;

@end
