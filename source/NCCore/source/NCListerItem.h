//
//  NCListerItem.h
//  NCCore
//
//  Created by Simon Strandgaard on 17/07/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCFileItem.h"


@interface NCListerItem : NCFileItem {
	NSImage* m_icon;

}
@property (strong) NSImage* icon;

+(NCListerItem*)backItem;
+(NCListerItem*)listerItemFromFileItem:(NCFileItem*)item;

@end
