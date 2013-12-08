//
//  NCHelpView.h
//  NCCore
//
//  Created by Simon Strandgaard on 02/08/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Webkit/Webkit.h>

@interface NCHelpObject : NSObject {

	NSString*	name;
	NSString*	orientation;
	float		x, y;
}

@property (copy) NSString* name;
@property (copy) NSString* orientation;
@property float x, y;

@end


@interface NCHelpView : WebView {
	NSMutableArray*	bindingNames;
	NSMutableArray*	bindingObservedObjects;
	NSMutableArray*	bindingObservedKeyPaths;

	NSString*	filename;
	float		angle;
	
	NCHelpObject* m_info;
	NSObjectController* m_controller;
}

@property (copy) NSString* filename;
@property	float angle;

-(void)setDict:(NSDictionary*)dict;

@end
