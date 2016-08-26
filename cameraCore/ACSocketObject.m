//
//  ACSocketObject.m
//  cameraCore
//
//  Created by neo on 16/8/16.
//  Copyright © 2016年 xy. All rights reserved.
//

#import "ACSocketObject.h"
#import "ACSocketService.h"

@implementation ACSocketObject

+ (instancetype)objectWithMsgID:(int)msg_id type:(NSString *)type param:(NSString *)param path:(NSString *)path
{
    ACSocketObject *m = [[ACSocketObject alloc] init];
    if (m) {
        m.msg_id = msg_id;
        m.type = type;
        m.param = param;
        m.path = path;
        m.token = [ACSocketService shared].tokenNumber;
    }
    return m;
}

+ (instancetype)objectWithMsgID:(int)msg_id type:(NSString *)type param:(NSString *)param token:(int)token
{
    ACSocketObject *m = [[ACSocketObject alloc] init];
    if (m) {
        m.msg_id = msg_id;
        m.type = type;
        m.param = param;
        m.token = token;
    }
    return m;
}

+ (instancetype)objectWithMsgID:(int)msg_id type:(NSString *)type param:(NSString *)param
{
    ACSocketObject *m = [ACSocketObject objectWithMsgID:msg_id type:type param:param token:[ACSocketService shared].tokenNumber];
    return m;
}

+ (instancetype)objectWithMsgID:(int)msg_id type:(NSString *)type
{
    ACSocketObject *m = [ACSocketObject objectWithMsgID:msg_id type:type param:nil token:[ACSocketService shared].tokenNumber];
    return m;
}

+ (instancetype)objectWithMsgID:(int)msg_id
{
    ACSocketObject *m = [ACSocketObject objectWithMsgID:msg_id type:nil param:nil token:[ACSocketService shared].tokenNumber];
    return m;
}

- (NSString *)objectToJSON
{
    //[sendMsg]-:{"param":"system_default_mode","msg_id":9,"token":64}
    NSString *tmp = @"";
    if (_token >= 0) {
        tmp = [tmp stringByAppendingString:[NSString stringWithFormat:@"\"token\":%d", _token]];
    }
    if (_msg_id >= 0) {
        tmp = [tmp stringByAppendingString:[NSString stringWithFormat:@",\"msg_id\":%d", _msg_id]];
    }
    if (_type && ![_type isEqualToString:@""]) {
        tmp = [tmp stringByAppendingString:[NSString stringWithFormat:@",\"type\":\"%@\"", _type]];
    }
    if (_param && ![_param isEqualToString:@""]) {
        tmp = [tmp stringByAppendingString:[NSString stringWithFormat:@",\"param\":\"%@\"", _param]];
    }
    if (_path && ![_path isEqualToString:@""]) {
        tmp = [tmp stringByAppendingString:[NSString stringWithFormat:@",\"path\":\"%@\"", _path]];
    }
    if (_heartbeat && ![_heartbeat isEqualToString:@""]) {
        tmp = [tmp stringByAppendingString:[NSString stringWithFormat:@",\"heartbeat\":\"%@\"", _heartbeat]];
    }
    return [tmp isEqualToString:@""]? nil : [NSString stringWithFormat:@"{%@}", tmp];
}

@end
