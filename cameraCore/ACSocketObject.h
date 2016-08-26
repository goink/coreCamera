//
//  ACSocketObject.h
//  cameraCore
//
//  Created by neo on 16/8/16.
//  Copyright © 2016年 xy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ACSocketObject : NSObject
@property (nonatomic,assign) int      msg_id;
@property (nonatomic,assign) int      token;
@property (nonatomic,strong) NSString *type;
@property (nonatomic,strong) NSString *param;
@property (nonatomic,strong) NSString *path;
@property (nonatomic,strong) NSString *heartbeat;

+ (instancetype)objectWithMsgID:(int)msg_id type:(NSString *)type param:(NSString *)param path:(NSString *)path;
+ (instancetype)objectWithMsgID:(int)msg_id type:(NSString *)type param:(NSString *)param token:(int)token;
+ (instancetype)objectWithMsgID:(int)msg_id type:(NSString *)type param:(NSString *)param;
+ (instancetype)objectWithMsgID:(int)msg_id type:(NSString *)type;
+ (instancetype)objectWithMsgID:(int)msg_id;

- (NSString *)objectToJSON;

@end
