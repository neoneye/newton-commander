//
//  NCListPanelTabModel.h
//  NewtonCommander
//
//  Created by Simon Strandgaard on 25/01/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#import <Cocoa/Cocoa.h>

@class NCListTabController;

@interface NCListPanelTabModel : NSObject {
	NCListTabController*  m_controller;
	BOOL						_isProcessing;
	NSImage					*m_icon;
	NSString					*_iconName;
	NSInteger					_objectCount;
	BOOL						_isEdited;
}

@property(nonatomic, strong) NCListTabController* controller;
@property(nonatomic, strong) NSImage* icon;

// creation/destruction
- (id)init;

// accessors
- (BOOL)isProcessing;
- (void)setIsProcessing:(BOOL)value;
- (NSString *)iconName;
- (void)setIconName:(NSString *)iconName;
- (NSInteger)objectCount;
- (void)setObjectCount:(NSInteger)value;
- (BOOL)isEdited;
- (void)setIsEdited:(BOOL)value;

@end
