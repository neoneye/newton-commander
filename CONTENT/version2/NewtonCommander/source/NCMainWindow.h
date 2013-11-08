//
//  NCMainWindow.h
//  NCCore
//
//  Created by Simon Strandgaard on 21/06/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NCMainWindow : NSWindow {

}

@end


@interface NSObject (NCMainWindowDelegate)

-(void)flagsChangedInWindow:(NSWindow*)window;

@end
