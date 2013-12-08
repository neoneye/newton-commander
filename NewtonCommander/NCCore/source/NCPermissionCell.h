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
@property (retain) NSAttributedString* rbit;
@property (retain) NSAttributedString* wbit;
@property (retain) NSAttributedString* xbit;
@property (retain) NSAttributedString* dash;
@property (retain) NSAttributedString* value1;
@property (retain) NSAttributedString* value2;
@property (retain) NSAttributedString* value3;
@property (retain) NSAttributedString* value4;
@property (retain) NSAttributedString* value5;
@property (retain) NSAttributedString* value6;
@property (retain) NSAttributedString* value7;

@end
