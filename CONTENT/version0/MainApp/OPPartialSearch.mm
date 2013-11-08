/*********************************************************************
OPPartialSearch.mm - helper for faster StringA.isEqualPartial(StringB)

Copyright (c) 2007 - opcoders.com
Simon Strandgaard <neoneye@opcoders.com>
*********************************************************************/
#include "OPPartialSearch.h"

@implementation OPPartialSearch

-(id)initWithCapacity:(size_t)capacity {
    self = [super init];
	if(self) {
		_capacity = capacity;
		_buffer1 = new unichar[capacity * 2];
		_buffer2 = _buffer1 + capacity;
		_search_text = nil;
		_length1 = 0;
		_ignore_case = NO;
		_render_attr_string = [[NSMutableAttributedString alloc] initWithString:@""];
		_normal_attrs = [[NSDictionary dictionary] retain];
		_match_attrs = [[NSDictionary dictionary] retain];
	}
	return self;
}

-(void)setIgnoreCase:(BOOL)aBool {
	_ignore_case = aBool;
}

-(void)setSearchText:(NSString*)search_text {
	if(_ignore_case) {
		// TODO: it's wrong to lowercase text, what we really want is caseless compare
		search_text = [search_text lowercaseString];
	}
	
	[search_text retain];
	[_search_text release];
	_search_text = search_text;
	
	_length1 = [_search_text length];
	if(_length1 > _capacity) {
		_length1 = _capacity;
	}

	//TRACE("let's get it");
	[_search_text getCharacters:_buffer1 range:NSMakeRange(0, _length1)];
	//TRACE("after");
}

-(BOOL)isEqual:(NSString*)text {
	if(_ignore_case) {
		// TODO: it's wrong to lowercase text, what we really want is caseless compare
		text = [text lowercaseString];
		//NSLog(@"'%@' ~= '%@'", _search_text, text);
	}

	NSString* s2 = text;
	size_t length2 = [s2 length];

	if(_length1 == 0) {
		return YES;
	}
	if(_length1 > length2) {
		// more search text than real text, that can never match
		return NO;
	}
	NSAssert(_length1 > 0, @"_length1 must be greater than zero");
	NSAssert(length2 > 0, @"length2 must be greater than zero");

	// copy to buffer
	if(length2 > _capacity) {
		length2 = _capacity;
	}
	[s2 getCharacters:_buffer2 range:NSMakeRange(0, length2)];

	
	/*
	scan through the long 's2' string, to see 
	if all the letters of the short 's1' string
	show up in the right order.
	*/
	int i1 = 0;
	int i2 = 0;
	int match_count = 0;
	while((i1 < _length1) && (i2 < length2)) {
		unichar char1 = _buffer1[i1++];
		while(i2 < length2) {
			unichar char2 = _buffer2[i2++];
			if(char1 == char2) {
				++match_count;
				break;
			}
		} 
	}
	
	return (match_count == _length1);
}

-(void)setNormalAttributes:(NSDictionary*)attrs {
	[attrs retain];
	[_normal_attrs release];
	_normal_attrs = attrs;
}

-(void)setMatchAttributes:(NSDictionary*)attrs {
	[attrs retain];
	[_match_attrs release];
	_match_attrs = attrs;
}

-(NSAttributedString*)renderString:(NSString*)text {

	// erase old result.. and prepare for a new result
	{
		int length = [_render_attr_string length];
		[_render_attr_string replaceCharactersInRange:NSMakeRange(0, length) withString:text];
	}

	{
		int length = [_render_attr_string length];
		[_render_attr_string setAttributes:_normal_attrs range:NSMakeRange(0, length)];
	}

	if(_ignore_case) {
		// TODO: it's wrong to lowercase text, what we really want is caseless compare
		text = [text lowercaseString];
		//NSLog(@"'%@' ~= '%@'", _search_text, text);
	}


	NSString* s2 = text;
	size_t length2 = [s2 length];

	if(_length1 == 0) {
		return [[_render_attr_string copy] autorelease];
	}
	if(_length1 > length2) {
		// more search text than real text, that can never match
		return [[_render_attr_string copy] autorelease];
	}
	NSAssert(_length1 > 0, @"_length1 must be greater than zero");
	NSAssert(length2 > 0, @"length2 must be greater than zero");

	// copy to buffer
	if(length2 > _capacity) {
		length2 = _capacity;
	}
	[s2 getCharacters:_buffer2 range:NSMakeRange(0, length2)];


	int i1 = 0;
	int i2 = 0;
	while((i1 < _length1) && (i2 < length2)) {
		unichar char1 = _buffer1[i1++];
		while(i2 < length2) {
			unichar char2 = _buffer2[i2++];
			if(char1 == char2) {
				[_render_attr_string setAttributes:_match_attrs range:NSMakeRange(i2-1, 1)];
				break;
			}
		} 
	}
	
	return [[_render_attr_string copy] autorelease];
}

-(void)dealloc {
	delete [] _buffer1;
	[_search_text release];
	[_render_attr_string release];
	[_normal_attrs release];
	[_match_attrs release];
	[super dealloc];
}

@end // OPPartialSearch