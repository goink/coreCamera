//
//  JSONParser.h
//  cameraCore
//
//  Created by neo on 16/8/16.
//  Copyright © 2016年 xy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JSONParser : NSObject
+ (NSMutableArray *)parserData:(out NSMutableData * __strong *)mutData;
@end
