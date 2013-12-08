#import <Foundation/Foundation.h>

@class CMTraversalObjectDir;
@class CMTraversalObjectFile;
@class CMTraversalObjectHardlink;
@class CMTraversalObjectSymlink;
@class CMTraversalObjectFifo;
@class CMTraversalObjectChar;
@class CMTraversalObjectBlock;
@class CMTraversalObjectOther;                           

@protocol CMTraversalObjectVisitor
-(void)visitDir:(CMTraversalObjectDir*)obj;
-(void)visitFile:(CMTraversalObjectFile*)obj;
-(void)visitHardlink:(CMTraversalObjectHardlink*)obj;
-(void)visitSymlink:(CMTraversalObjectSymlink*)obj;
-(void)visitFifo:(CMTraversalObjectFifo*)obj;
-(void)visitChar:(CMTraversalObjectChar*)obj;
-(void)visitBlock:(CMTraversalObjectBlock*)obj;
-(void)visitOther:(CMTraversalObjectOther*)obj;
@end


/*
when "exclude = YES" then the object should be ignored
examples of objects that users often want to ignore
.DS_Store
.svn
.git

*/
@interface CMTraversalObject : NSObject {
	NSString* m_path;
	BOOL m_exclude;
}
@property (retain) NSString* path;
@property (assign) BOOL exclude;

-(void)accept:(id <CMTraversalObjectVisitor>)v;
@end


@interface CMTraversalObjectDir : CMTraversalObject {
	NSArray* m_child_traversal_objects;
}
@property (retain) NSArray* childTraversalObjects;
@end


@interface CMTraversalObjectFile : CMTraversalObject {}
@end


/*
link is either set to: CMTraversalObjectDir, CMTraversalObjectFile, CMTraversalObjectFifo
*/
@interface CMTraversalObjectHardlink : CMTraversalObject {
	CMTraversalObject* m_link;
}
@property (retain) CMTraversalObject* link;
-(NSString*)linkPath;
@end

@interface CMTraversalObjectSymlink : CMTraversalObject {
	NSString* m_link_path;
}
@property (retain) NSString* linkPath;
@end

@interface CMTraversalObjectFifo : CMTraversalObject {}
@end

@interface CMTraversalObjectChar : CMTraversalObject {
	NSUInteger m_major;
	NSUInteger m_minor;
}
@property (assign) NSUInteger major;
@property (assign) NSUInteger minor;
@end

@interface CMTraversalObjectBlock : CMTraversalObject {
	NSUInteger m_major;
	NSUInteger m_minor;
}
@property (assign) NSUInteger major;
@property (assign) NSUInteger minor;
@end

@interface CMTraversalObjectOther : CMTraversalObject {}
@end
