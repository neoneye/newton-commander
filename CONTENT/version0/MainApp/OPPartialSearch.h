/*********************************************************************
OPPartialSearch.h - helper for faster StringA.isEqualPartial(StringB)

Copyright (c) 2007 - opcoders.com
Simon Strandgaard <neoneye@opcoders.com>

by PARTIAL we mean is all the letters in the search-string included
in the text-string, and does the occur in the same order.

example if the search text is: simon
then we can write it as regex:  s(.*?)i(.*?)m(.*?)o(.*?)n
this could match these strings:
 1. simon strandgaard
 2. fables li modern
 3. svga pimpl only

but doesn't match
 1. nomis
 2. abcdefg


TODO: real caseless comparison is not easy to do, figure it out.
right now it's poor mans comparison, using lowercase folding,
which doesn't work for the danish letters: lowercase(ÆØÅ) != æøå

*********************************************************************/
#ifndef __OPCODERS_COMMONLIB_OPPARTIALSEARCH_H__
#define __OPCODERS_COMMONLIB_OPPARTIALSEARCH_H__

@interface OPPartialSearch : NSObject {
	unichar* _buffer1;
	unichar* _buffer2;
	size_t _capacity;
	NSString* _search_text;
	size_t _length1;
	BOOL _ignore_case;

	// formatting related
	NSMutableAttributedString* _render_attr_string;
	NSDictionary* _normal_attrs;
	NSDictionary* _match_attrs;
}

-(id)initWithCapacity:(size_t)capacity;

// partial search related
-(void)setIgnoreCase:(BOOL)aBool;
-(void)setSearchText:(NSString*)search_text;
-(BOOL)isEqual:(NSString*)text;

// formatting of the partial search results
-(void)setNormalAttributes:(NSDictionary*)attrs;
-(void)setMatchAttributes:(NSDictionary*)attrs;
-(NSAttributedString*)renderString:(NSString*)text;

@end

#endif // __OPCODERS_COMMONLIB_OPPARTIALSEARCH_H__