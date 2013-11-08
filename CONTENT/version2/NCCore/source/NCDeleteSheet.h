//
//  NCDeleteSheet.h
//  NCCore
//
//  Created by Simon Strandgaard on 28/04/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NCDeleteSheet : NSObject {
	id m_delegate;
	NSArray* m_paths;
}
@property (assign) IBOutlet id delegate;
@property (retain) NSArray* paths;
+(NCDeleteSheet*)shared;

-(void)beginSheetForWindow:(NSWindow*)window;

@end

@interface NSObject (NCDeleteSheetDelegate)
-(void)deleteControllerDidDelete:(NCDeleteSheet*)ctrl;
@end