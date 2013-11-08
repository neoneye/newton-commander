//
//  NSTableView+ColumnLayout.h
//  cocoa_clickable_headercell
//
//  Created by Simon Strandgaard on 04/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSTableView (NCColumnLayout)

-(NSArray*)arrayWithColumnLayout;
-(void)adjustColumnLayoutForArray:(NSArray*)ary;

@end
