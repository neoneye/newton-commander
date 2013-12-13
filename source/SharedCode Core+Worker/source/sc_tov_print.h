#import "sc_traversal_objects.h"

@interface TOVPrint : NSObject <TraversalObjectVisitor> {
	NSMutableString* m_result;
	NSString* m_source_path;
	NSString* m_target_path;
}
@property (strong) NSString* sourcePath;
@property (strong) NSString* targetPath;

-(NSString*)result;

-(NSString*)convert:(NSString*)path;
@end
