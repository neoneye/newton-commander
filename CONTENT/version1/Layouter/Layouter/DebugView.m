//
//  DebugView.m
//  project
//
//  Created by Simon Strandgaard on 09/04/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import "DebugView.h"


@implementation DebugView

@synthesize insetX = m_inset_x;
@synthesize insetY = m_inset_y;
@synthesize colorName = m_color_name;

- (id)initWithFrame:(NSRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
        self.insetX = 4;
        self.insetY = 4;
        self.colorName = @"red";
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(NSRect)rect {
   
    NSString *selectorString = [self.colorName stringByAppendingString:@"Color"];
    SEL selector = NSSelectorFromString(selectorString);
    NSColor *color = [NSColor redColor];
    if ([NSColor respondsToSelector:selector]) {
        color = [NSColor performSelector:selector];
    }
    
	
    CGRect bounds_cg = NSRectToCGRect(self.bounds);
    CGRect fill_area = CGRectInset(bounds_cg, self.insetX, self.insetY);
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];

    
    CGFloat red = 0, green = 0, blue = 0, alpha = 0;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    CGContextSetRGBFillColor(context, red, green, blue, alpha);
    
    CGContextFillRect( context, fill_area );
}

- (void)dealloc {
    [super dealloc];
}


@end
