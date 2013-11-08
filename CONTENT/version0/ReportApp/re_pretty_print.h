/*********************************************************************
re_pretty_print.h - obtain detailed info about a file/dir/...

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#ifndef __OPCODERS_KEYBOARDCOMMANDER_REPORTAPP_PRETTYPRINT_H__
#define __OPCODERS_KEYBOARDCOMMANDER_REPORTAPP_PRETTYPRINT_H__

@interface REPrettyPrint : NSObject {
	NSString* m_path;
	NSMutableAttributedString* m_result;
	BOOL m_append_to_result;
	BOOL m_debug;
	BOOL m_debug_sections;
	
	NSFont* m_font1;
	NSFont* m_font2;    
	NSFont* m_font3;
	NSDictionary* m_attr1;
	NSDictionary* m_attr2;
	NSDictionary* m_attr3;
	NSDictionary* m_attr4;
}
-(id)initWithPath:(NSString*)path;

-(void)obtain;

-(NSAttributedString*)result;

@end

#endif // __OPCODERS_KEYBOARDCOMMANDER_REPORTAPP_PRETTYPRINT_H__