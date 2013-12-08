//
//  FPOCsvWriter.h
//  FourCSV
//
//  Created by Matthias Bartelmeß on 13.01.10.
//  Copyright 2010 fourplusone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FPOICsvWriter.h"

@interface FPOCsvWriter : NSObject <FPOICsvWriter>  {

@private NSFileHandle * filehandle;

}

@end
