//
//  NCListPanelTabModel.h
//  NewtonCommander
//
//  Created by Simon Strandgaard on 25/01/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#import "NCListPanelTabModel.h"


@implementation NCListPanelTabModel

@synthesize controller = m_controller;
@synthesize icon = m_icon;

- (id)init {
	if((self == [super init])) {
		_isProcessing = NO;
		_iconName = nil;
		_objectCount = 0;
		_isEdited = NO;
	}
	return self;
}


// accessors
- (BOOL)isProcessing {
	return _isProcessing;
}

- (void)setIsProcessing:(BOOL)value {
	_isProcessing = value;
}

- (NSString *)iconName {
	return _iconName;
}

- (void)setIconName:(NSString *)iconName {
	[iconName retain];
	[_iconName release];
	_iconName = iconName;
}

- (NSInteger)objectCount {
	return _objectCount;
}

- (void)setObjectCount:(NSInteger)value {
	_objectCount = value;
}

- (BOOL)isEdited {
	return _isEdited;
}

- (void)setIsEdited:(BOOL)value {
	_isEdited = value;
}


- (NSImage *)largeImage {
	return [NSImage imageNamed:@"largeImage"];
}

- (void)setLargeImage:(NSImage *)icon {
	[self setIcon:icon];
}

@end
