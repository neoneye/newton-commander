//
//  NCMainWindow.h
//  Newton Commander
//
#import <Cocoa/Cocoa.h>


@interface NCMainWindow : NSWindow {

}

@end


@interface NSObject (NCMainWindowDelegate)

-(void)flagsChangedInWindow:(NSWindow*)window;

@end
