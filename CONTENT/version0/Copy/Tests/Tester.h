/*********************************************************************
Tester.h - interface for exercising the copy code

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/

@interface Tester : NSObject {
	NSString* m_root_dir;
	NSString* m_source_dir;
	NSString* m_dest_dir;
}
@property (copy) NSString* rootDir;
@property (copy) NSString* sourceDir;
@property (copy) NSString* destDir;

+(Tester*)tester;

-(BOOL)areWeUsingAppleCopy;

// create temporary dirs for use as test area
-(void)setup;

// create a file in the source dir
-(void)makeFile:(NSString*)name data:(NSData*)data;

// copy a file from the source dir to the dest dir
-(void)copyFile:(NSString*)name;

// copy a file from the source dir to the given dest dir
-(void)copyFile:(NSString*)name toPath:(NSString*)absPath;

// compate contents of two files
-(BOOL)compareContentFile:(NSString*)name;

// compare extended attributes of two files
-(BOOL)compareXAttrFile:(NSString*)name;    

// compare stat64 flags
-(BOOL)compareFlagsFile:(NSString*)name;

// compare everything for a file
-(BOOL)compareFile:(NSString*)name;

// random test data
-(NSData*)randomDataOfSize:(NSUInteger)bytes;

// get the stat64 flags as a string
-(NSString*)flagsForFile:(NSString*)abs_path;

/*
set the stat64 flags. Some of them are only 
changable by the super-user. Some of them are
not implemented in Mac OS X.

user settable flags
UF_NODUMP	 0x00000001 "nodump"
UF_IMMUTABLE 0x00000002 "uchg"      only root can unset this flag!
UF_APPEND	 0x00000004 "uappnd"    only root can unset this flag!
UF_OPAQUE	 0x00000008 "opaque"
UF_NOUNLINK	 0x00000010 doesn't have a chflags name
?????????    0x00000020 doesn't have a chflags name
?????????    0x00000040 doesn't have a chflags name
?????????    0x00000080 doesn't have a chflags name
?????????    0x00000100 doesn't have a chflags name
?????????    0x00000200 doesn't have a chflags name
?????????    0x00000400 doesn't have a chflags name
?????????    0x00000800 doesn't have a chflags name
?????????    0x00001000 doesn't have a chflags name
?????????    0x00002000 doesn't have a chflags name
?????????    0x00004000 doesn't have a chflags name
UF_HIDDEN	 0x00008000 "hidden"

super user settable flags
SF_ARCHIVED	 0x00010000
SF_IMMUTABLE 0x00020000
SF_APPEND	 0x00040000
SF_NOUNLINK	 0x00100000
SF_SNAPSHOT	 0x00200000
*/
-(void)setFlags:(NSUInteger)flags file:(NSString*)name;


// get all the exteded attributes for a file
-(NSArray*)xattrForFile:(NSString*)abs_path;

// append an exteded attribute to a file
-(void)setXattr:(NSString*)xattrname 
          value:(NSData*)xattrvalue 
  		   file:(NSString*)name;

// set resource fork data
-(void)setRsrcData:(NSData*)data file:(NSString*)name;

-(BOOL)compareRsrcForFile:(NSString*)name;

-(NSData*)rsrcDataFromFile:(NSString*)abs_path;


-(NSString*)sourcePathForFile:(NSString*)file;

-(void)setACL:(NSString*)acl_text path:(NSString*)path;
-(void)assignGarbageACLToFile:(NSString*)name;
-(BOOL)compareACLFile:(NSString*)name;
-(NSString*)aclDataFromFile:(NSString*)path;

@end