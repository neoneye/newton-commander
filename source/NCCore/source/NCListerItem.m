//
//  NCListerItem.m
//  NCCore
//
//  Created by Simon Strandgaard on 17/07/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NCListerItem.h"


@implementation NCListerItem

@synthesize icon = m_icon;

-(id)initWithCoder:(NSCoder*)coder {
	// our superclass supports NSCoding
    if (self = [super initWithCoder: coder]) {
		if([coder allowsKeyedCoding]) {
	        m_icon = [coder decodeObjectForKey: @"icon"];
		} else {
	        m_icon = [coder decodeObject];    
		}
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder*)coder {
	// our superclass supports NSCoding
	[super encodeWithCoder:coder];
	
	if([coder allowsKeyedCoding]) {
	    [coder encodeObject:m_icon  forKey: @"icon"];
	} else {
	    [coder encodeObject:m_icon];
	}
}

- (id)copyWithZone:(NSZone*)zone {
	// our superclass supports NSCopying, so we use [super copyWithZone:zone].
	NCListerItem* item = [super copyWithZone:zone];
	if(!item) return nil;
    [item setIcon:[m_icon copy]];
    return item;
}


+(NCListerItem*)backItem {
	NCListerItem* item = [[NCListerItem alloc] init];
	[item setName:@"[ back ]"];
	[item setItemType:kNCItemTypeGoBack];
	return item;
}

+(NCListerItem*)listerItemFromFileItem:(NCFileItem*)item {
	NCListerItem* item2 = [[NCListerItem alloc] init];
	[item2 setName:[item name]];
	[item2 setItemType:[item itemType]];
	[item2 setLink:[item link]];
	[item2 setSize:[item size]];
	[item2 setResourceForkSize:[item resourceForkSize]];
	[item2 setInode:[item inode]];
	[item2 setFlags:[item flags]];
	[item2 setReferenceCount:[item referenceCount]];
	[item2 setItemCount:[item itemCount]];
	[item2 setAclCount:[item aclCount]];
	[item2 setXattrCount:[item xattrCount]];
	[item2 setGroup:[item group]];
	[item2 setOwner:[item owner]];
	[item2 setPosixPermissions:[item posixPermissions]];
	[item2 setAccessDate:[item accessDate]];
	[item2 setContentModificationDate:[item contentModificationDate]];
	[item2 setAttributeModificationDate:[item attributeModificationDate]];
	[item2 setCreationDate:[item creationDate]];        
	[item2 setBackupDate:[item backupDate]];
	[item2 setKind:[item kind]];
	[item2 setContentType:[item contentType]];
	[item2 setComment:[item comment]];
	return item2;
}

@end
