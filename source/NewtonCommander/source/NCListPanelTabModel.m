//
//  NCListPanelTabModel.h
//  Newton Commander
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "NCListPanelTabModel.h"


@implementation NCListPanelTabModel

@synthesize controller = m_controller;
@synthesize icon = m_icon;

- (id)init {
    self = [super init];
	if(self) {
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
