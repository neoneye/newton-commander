#import "CMTraversalObject.h"

@implementation CMTraversalObject
@synthesize path = m_path;
@synthesize exclude = m_exclude;

-(void)accept:(id <CMTraversalObjectVisitor>)v {
	// do nothing, subclass must implement this method
}
@end


@implementation CMTraversalObjectDir
@synthesize childTraversalObjects = m_child_traversal_objects;
-(void)accept:(id <CMTraversalObjectVisitor>)v { [v visitDir:self]; }
@end

@implementation CMTraversalObjectFile
-(void)accept:(id <CMTraversalObjectVisitor>)v { [v visitFile:self]; }
@end


@implementation CMTraversalObjectHardlink
@synthesize link = m_link;
-(void)accept:(id <CMTraversalObjectVisitor>)v { [v visitHardlink:self]; }

-(NSString*)linkPath {
	if(m_link == nil) return nil;
	return [m_link path];
}
@end

@implementation CMTraversalObjectSymlink
@synthesize linkPath = m_link_path;
-(void)accept:(id <CMTraversalObjectVisitor>)v { [v visitSymlink:self]; }
@end



@implementation CMTraversalObjectFifo
-(void)accept:(id <CMTraversalObjectVisitor>)v { [v visitFifo:self]; }
@end


@implementation CMTraversalObjectChar
@synthesize major = m_major;
@synthesize minor = m_minor;
-(void)accept:(id <CMTraversalObjectVisitor>)v { [v visitChar:self]; }
@end


@implementation CMTraversalObjectBlock
@synthesize major = m_major;
@synthesize minor = m_minor;
-(void)accept:(id <CMTraversalObjectVisitor>)v { [v visitBlock:self]; }
@end


@implementation CMTraversalObjectOther
-(void)accept:(id <CMTraversalObjectVisitor>)v { [v visitOther:self]; }
@end


