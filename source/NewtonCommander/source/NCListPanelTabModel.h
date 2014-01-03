//
//  NCListPanelTabModel.h
//  Newton Commander
//
#import <Cocoa/Cocoa.h>
#import "PSMTabViewItemIdentifier.h"

@class NCListTabController;

@interface NCListPanelTabModel : NSObject <PSMTabViewItemIdentifier> {
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
