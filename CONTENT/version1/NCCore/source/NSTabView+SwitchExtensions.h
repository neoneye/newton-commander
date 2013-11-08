//
//  NSTabView+SwitchExtensions.h
//  NCCore
//
//  Created by Simon Strandgaard on 03/07/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSTabView (SwitchExtensions)

/*
This action method selects the next tab view item in the sequence.
If the currently visible item is the last item in the sequence, this method selects the first tabview.
*/
-(void)selectNextOrFirstTabViewItem:(id)sender;

/*
This action method selects the previous tab view item in the sequence.
If the currently visible item is the first item in the sequence, this method selects the last tabview.
*/
-(void)selectPreviousOrLastTabViewItem:(id)sender;

-(void)removeAllTabs:(id)sender;

@end
