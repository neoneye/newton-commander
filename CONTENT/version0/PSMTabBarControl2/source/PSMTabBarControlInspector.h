//
//  PSMTabBarControlInspector.h
//  PSMTabBarControl
//
//  Created by Simon Strandgaard on 21/01/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <InterfaceBuilderKit/InterfaceBuilderKit.h>

@interface PSMTabBarControlInspector : IBInspector {
    IBOutlet NSPopUpButton* m_style;

}
-(IBAction)styleAction:(id)sender;

@end
