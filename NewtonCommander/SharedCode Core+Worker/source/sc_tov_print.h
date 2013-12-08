#import "sc_traversal_objects.h"

@interface TOVPrint : NSObject <TraversalObjectVisitor> {
	NSMutableString* m_result;
	NSString* m_source_path;
	NSString* m_target_path;
}
@property (retain) NSString* sourcePath;
@property (retain) NSString* targetPath;

-(NSString*)result;

-(NSString*)convert:(NSString*)path;
@end
