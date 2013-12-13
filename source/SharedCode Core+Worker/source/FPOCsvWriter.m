//
//  FPOCsvWriter.m
//  FourCSV
//
//  Created by Matthias Bartelmeß on 13.01.10.
//  Copyright 2010 fourplusone. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "FPOCsvWriter.h"


@implementation FPOCsvWriter

-(id)initWithFileHandle:(NSFileHandle *)fh
{
    self = [super init];
    if(self){
        filehandle = fh;
    }
    return self;
    
}


-(NSString *)escapeString:(NSString *)s
{
    
    NSString * escapedString = s;
    
    BOOL containsSeperator = !NSEqualRanges([s rangeOfString:@","], NSMakeRange(NSNotFound, 0));
    BOOL containsQuotes = !NSEqualRanges([s rangeOfString:@"\""], NSMakeRange(NSNotFound, 0));
    BOOL containsLineBreak = !NSEqualRanges([s rangeOfString:@"\n"], NSMakeRange(NSNotFound, 0));
    
    
    if (containsQuotes) {
        escapedString = [escapedString stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""];
    }
    
    if (containsSeperator || containsLineBreak) {
        escapedString = [NSString stringWithFormat:@"\"%@\"", escapedString];
    }
    
    return escapedString;
}

-(NSData *)encodeString:(NSString *)s
{
    return [s dataUsingEncoding:NSUTF8StringEncoding];
}


-(void)writeRow:(NSArray *)row
{
    NSMutableString * string = [NSMutableString string];
    BOOL firstColumn = YES;
    for(id column in row)
    {
        NSString * rawColumn;
        if ([column isKindOfClass:[NSString class]]) {
            rawColumn = column;
               
        }else{
			if([column respondsToSelector:@selector(stringRepresentation)]) {
				rawColumn = [column performSelector:@selector(stringRepresentation) withObject:nil];
			} else {
            	rawColumn = [column description];
			}
        }
        NSString * delimiter = !firstColumn?@",":@"";
        
        [string appendFormat:@"%@%@", delimiter,[self escapeString:rawColumn]];
        firstColumn = NO;
        
    }
    [string appendString:@"\n"];
    
    [filehandle writeData:[self encodeString:string]];
    
}

-(void)writeRows:(NSArray *)rows
{
    for(NSArray * row in rows)
    {
        [self writeRow:row];
    }
    
}

@end
