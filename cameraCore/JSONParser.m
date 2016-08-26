//
//  JSONParser.m
//  cameraCore
//
//  Created by neo on 16/8/16.
//  Copyright © 2016年 xy. All rights reserved.
//

#import "JSONParser.h"

@implementation JSONParser

+ (NSMutableArray *)parserData:(out NSMutableData * __strong *)mutData
{
    if (!*mutData || (*mutData).length == 0) {
        return nil;
    }
    
    NSString *str = [[NSString alloc] initWithData:*mutData encoding:NSUTF8StringEncoding];
    if (![[str substringFromIndex:str.length-1] isEqualToString:@"}"]) {
        return nil;
    }
    
    NSMutableArray *mutArr = [NSMutableArray array];
    
    @autoreleasepool {
        
        int jsonStarter = 0;
        
        NSString *msg = [[NSString alloc] initWithData:*mutData encoding:NSUTF8StringEncoding];
        int getNum = 0;
        
        
        for (int i=0; i<msg.length; i++) {
            
            @autoreleasepool {
                
                char a= [msg characterAtIndex:i];
                if (a =='{') {
                    ++getNum;
                }else if (a=='}'){
                    
                    --getNum;
                    if (getNum==0)
                    {
                        //从jsonStarter开始到当前index i为一个完整的json消息体
                        NSString *s = [msg substringWithRange:NSMakeRange(jsonStarter, i - jsonStarter + 1)];
                        jsonStarter = i + 1;//下一个json消息体的开始的位置
                        
                        NSData *dataR = [s dataUsingEncoding:NSUTF8StringEncoding];
                        //                        JSONDecoder * sbjson = [[JSONDecoder alloc]init];
                        //                        NSDictionary *dic = [sbjson objectWithData:dataR];
                        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:dataR options:NSJSONReadingMutableLeaves error:nil];
                        if (dic)
                        {
                            [mutArr addObject:dic];
                        }
                    }
                }
            }
            
        }
        if (jsonStarter < msg.length) {//如果还下buffer没有解析完成，赋值给mutData，socket继续读取，继续解析
            *mutData = [NSMutableData dataWithData:[*mutData subdataWithRange:NSMakeRange(jsonStarter, msg.length - jsonStarter)]];
        }else {
            *mutData = nil;
        }
        
    }
    
    
    return mutArr;
    
    
}

@end
