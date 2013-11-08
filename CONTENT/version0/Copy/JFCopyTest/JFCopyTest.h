/*********************************************************************
JFCopyTest.h - Test the code for copying files

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/

@class JFCopy;
@interface JFCopyTest : NSObject {
	IBOutlet NSWindow* m_mainwindow;
	JFCopy* m_copy;
}

-(IBAction)quitAction:(id)sender;
-(IBAction)showSheetAction:(id)sender;

@end
