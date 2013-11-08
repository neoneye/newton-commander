/*********************************************************************
JFMainWindow.h - a NSWindow with special keyboard event handler

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/

@interface JFMainWindow : NSWindow {
}
@end

@interface NSObject (JFSystemCopyThreadDelegate)

-(void)mainWindow:(JFMainWindow*)mainWindow
     flagsChanged:(NSUInteger)flags;

@end