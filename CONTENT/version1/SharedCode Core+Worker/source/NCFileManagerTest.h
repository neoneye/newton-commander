//
//  NSFileManager+PathExtensionsTest.h
//  NCCore
//
//  Created by Simon Strandgaard on 22/05/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>


@interface NSFileManager_ResolvePathTest : SenTestCase {

}

-(NSString*)nc_readlink:(NSString*)path;

@end

@interface NSFileManager_ResolvePathTest_UsingTempdir : SenTestCase {
	NSString* m_temp_dir;
}

/*
create dir inside tempdir and return absolute path to it
*/
-(NSString*)mkdir:(NSString*)name;

/*
create file inside tempdir and return absolute path to it
*/
-(NSString*)mkfile:(NSString*)name;

/*
create symlink inside tempdir and return absolute path to it
*/
-(NSString*)mklink:(NSString*)name dest:(NSString*)dest;

/*
create alias inside tempdir and return absolute path to it
*/
-(NSString*)mkalias:(NSString*)destname dest:(NSString*)srcname;

@end
