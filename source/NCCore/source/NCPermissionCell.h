//
//  NCPermissionCell.h
//  NCCore
//
//  Created by Simon Strandgaard on 24/05/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCListerCell.h"


@interface NCPermissionCell : NCListerCell {
	NSAttributedString* m_rbit;
	NSAttributedString* m_wbit;
	NSAttributedString* m_xbit;
	NSAttributedString* m_dash;
	NSAttributedString* m_value1;
	NSAttributedString* m_value2;
	NSAttributedString* m_value3;
	NSAttributedString* m_value4;
	NSAttributedString* m_value5;
	NSAttributedString* m_value6;
	NSAttributedString* m_value7;
}
@property (strong) NSAttributedString* rbit;
@property (strong) NSAttributedString* wbit;
@property (strong) NSAttributedString* xbit;
@property (strong) NSAttributedString* dash;
@property (strong) NSAttributedString* value1;
@property (strong) NSAttributedString* value2;
@property (strong) NSAttributedString* value3;
@property (strong) NSAttributedString* value4;
@property (strong) NSAttributedString* value5;
@property (strong) NSAttributedString* value6;
@property (strong) NSAttributedString* value7;

@end
