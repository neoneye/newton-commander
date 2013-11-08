//
//  NCPermissionSheet.h
//  NCCore
//
//  Created by Simon Strandgaard on 13/09/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NCPermissionSheet : NSWindowController {

}
+(NCPermissionSheet*)shared;

-(void)beginSheetForWindow:(NSWindow*)window;

-(IBAction)cancelAction:(id)sender;
-(IBAction)submitAction:(id)sender;

@end

@interface NSObject (NCPermissionSheetDelegate)

@end
