//
//  NCDateCell.h
//  NCCore
//
//  Created by Simon Strandgaard on 14/08/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NCListerCell.h"


@interface NCDateCell : NCListerCell {

	NSTextStorage* m_text_storage;
	NSTextContainer* m_text_container;
	NSLayoutManager* m_layout_manager;
	NSMutableParagraphStyle* m_para_style;
	NSDictionary* m_attr;

	NSDateFormatter* m_date_formatter_verbose;
	NSDateFormatter* m_date_formatter_compact;
	
	float m_width_of_verbose_text;
	
	CFMutableAttributedStringRef m_attr_string;
	CTLineRef m_ellipsis;
	CFDictionaryRef m_attr0;
	CFDictionaryRef m_attr1;
}
@property (strong) NSTextStorage* textStorage;
@property (strong) NSTextContainer* textContainer;
@property (strong) NSLayoutManager* layoutManager;
@property (strong) NSMutableParagraphStyle* paraStyle;
@property (strong) NSDictionary* attr;
@property (strong) NSDateFormatter* dateFormatterVerbose;
@property (strong) NSDateFormatter* dateFormatterCompact;
@property float widthOfVerboseText;

@end
