#import "sc_traversal_objects.h"

@implementation TraversalObject
@synthesize path = m_path;

-(void)accept:(id <TraversalObjectVisitor>)v {
	// do nothing, subclass must implement this method
}
@end


@implementation TODirPre
-(void)accept:(id <TraversalObjectVisitor>)v { [v visitDirPre:self]; }
@end


@implementation TODirPost
-(void)accept:(id <TraversalObjectVisitor>)v { [v visitDirPost:self]; }
@end


@implementation TOFile
-(void)accept:(id <TraversalObjectVisitor>)v { [v visitFile:self]; }
@end


@implementation TOHardlink
@synthesize link = m_link;
-(void)accept:(id <TraversalObjectVisitor>)v { [v visitHardlink:self]; }

-(NSString*)linkPath {
	if(m_link == nil) return nil;
	return [m_link path];
}
@end

@implementation TOSymlink
@synthesize linkPath = m_link_path;
-(void)accept:(id <TraversalObjectVisitor>)v { [v visitSymlink:self]; }
@end



@implementation TOFifo
-(void)accept:(id <TraversalObjectVisitor>)v { [v visitFifo:self]; }
@end


@implementation TOChar
@synthesize major = m_major;
@synthesize minor = m_minor;
-(void)accept:(id <TraversalObjectVisitor>)v { [v visitChar:self]; }
@end


@implementation TOBlock
@synthesize major = m_major;
@synthesize minor = m_minor;
-(void)accept:(id <TraversalObjectVisitor>)v { [v visitBlock:self]; }
@end


@implementation TOOther
-(void)accept:(id <TraversalObjectVisitor>)v { [v visitOther:self]; }
@end


@implementation TOProgressBefore
@synthesize name = m_name;
-(void)accept:(id <TraversalObjectVisitor>)v { [v visitProgressBefore:self]; }
@end

@implementation TOProgressAfter
@synthesize name = m_name;
-(void)accept:(id <TraversalObjectVisitor>)v { [v visitProgressAfter:self]; }
@end

