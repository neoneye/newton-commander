#import <Foundation/Foundation.h>

@class TODirPre;
@class TODirPost;
@class TOFile;
@class TOHardlink;
@class TOSymlink;
@class TOFifo;
@class TOChar;
@class TOBlock;
@class TOOther;                           
@class TOProgressBefore;
@class TOProgressAfter;

@protocol TraversalObjectVisitor
-(void)visitDirPre:(TODirPre*)obj;
-(void)visitDirPost:(TODirPost*)obj;
-(void)visitFile:(TOFile*)obj;
-(void)visitHardlink:(TOHardlink*)obj;
-(void)visitSymlink:(TOSymlink*)obj;
-(void)visitFifo:(TOFifo*)obj;
-(void)visitChar:(TOChar*)obj;
-(void)visitBlock:(TOBlock*)obj;
-(void)visitOther:(TOOther*)obj;
-(void)visitProgressBefore:(TOProgressBefore*)obj;
-(void)visitProgressAfter:(TOProgressAfter*)obj;
@end


@interface TraversalObject : NSObject {
	NSString* m_path;
}
@property (retain) NSString* path;

-(void)accept:(id <TraversalObjectVisitor>)v;
@end


@interface TODirPre : TraversalObject {}
@end


@interface TODirPost : TraversalObject {}
@end


@interface TOFile : TraversalObject {}
@end


/*
link is either set to: TODirPre, TOFile, TOFifo
*/
@interface TOHardlink : TraversalObject {
	TraversalObject* m_link;
}
@property (retain) TraversalObject* link;
-(NSString*)linkPath;
@end

@interface TOSymlink : TraversalObject {
	NSString* m_link_path;
}
@property (retain) NSString* linkPath;
@end

@interface TOFifo : TraversalObject {}
@end

@interface TOChar : TraversalObject {
	NSUInteger m_major;
	NSUInteger m_minor;
}
@property (assign) NSUInteger major;
@property (assign) NSUInteger minor;
@end

@interface TOBlock : TraversalObject {
	NSUInteger m_major;
	NSUInteger m_minor;
}
@property (assign) NSUInteger major;
@property (assign) NSUInteger minor;
@end

@interface TOOther : TraversalObject {}
@end


/*
This class is an aid for updating the progressbars.
It's inserted in between the other traversal objects and when it's 
encountered it syncronizes with the progressbars.
It's used before copying of a major dir.
*/
@interface TOProgressBefore : TraversalObject {
	NSString* m_name;
}
@property (retain) NSString* name;

@end

/*
This class is an aid for updating the progressbars.
It's inserted in between the other traversal objects and when it's 
encountered it syncronizes with the progressbars.
It's used after a major dir has been copied.
*/
@interface TOProgressAfter : TraversalObject {
	NSString* m_name;
}
@property (retain) NSString* name;

@end
