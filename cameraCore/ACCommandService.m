//
//  ACCommandService.m
//  ActionCamera
//
//  Created by Guisheng on 16/1/18.
//  Copyright © 2016年 AC. All rights reserved.
//

#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <mach/mach.h>
#include <arpa/inet.h>
#include <ifaddrs.h>

#import "ACCommandService.h"
#import "ACSocketService.h"
#import "ACSocketObject.h"
#import "AsyncSocket.h"
#import "ACDefines.h"

@implementation ACCommandService

#pragma mark - 执行相机命令，带回调注册
+ (void)execute:(int)msgid params:(NSDictionary *)params success:(void (^)(id))success failure:(void (^)(id))failure
{
    ACSocketObject *socObj = [ACSocketObject objectWithMsgID:msgid type:params[@"type"] param:params[@"param"]];
    [[ACSocketService shared] sendCommandWithSocketObject:socObj success:success failure:failure];
}

#pragma mark - 注册相机命令监听器，带回调注册
+ (void)listen:(int)msgid success:(void (^)(id))success failure:(void (^)(id))failure
{
    NSString *msgidString = [NSString stringWithFormat:@"%u", msgid];
    [[ACSocketService shared] addSystemHandlerForMsgId:msgidString success:success failure:failure];
}

#pragma mark - session管理相关
+ (void)startCommandSocketSession
{
    [[ACSocketService shared] startCommandSocketSession];
}

+(void)stopCommandSocketSession
{
    [[ACSocketService shared] stopCommandSocketSession];
}

+ (void)startSession
{
#if HEARTBEAT_ENABLE
    ACSocketObject *socObj = [ACSocketObject objectWithMsgID:MSGID_START_SESSION heartbeat:@"1"];
    [[ACSocketService shared] sendCommandWithSocketObject:socObj success:nil failure:nil];
#else
    [ACCommandService execute:MSGID_START_SESSION params:nil success:nil failure:nil];
#endif
    
}

#pragma mark - 无回调快捷命令接口
+ (void)getAllCurrentSettings
{
    [ACCommandService execute:MSGID_GET_ALL_CURRENT_SETTINGS params:nil success:nil failure:nil];
}

+ (void)getSettingOptions:(NSString *)setting
{
    if (setting) {
        NSDictionary *params = @{@"param":setting};
        [ACCommandService execute:MSGID_GET_SETTING params:params success:nil failure:nil];
    }
}

+ (void)setSettingWithType:(NSString *)type param:(NSString *)param
{
    if (type && param) {
        NSDictionary *params = @{@"param":param, @"type":type};
        [ACCommandService execute:MSGID_SET_SETTING params:params success:nil failure:nil];
    }
}

+ (void)getSettingWithType:(NSString *)type
{
    if (type) {
        NSDictionary *params = @{@"type":type};
        [ACCommandService execute:MSGID_GET_SETTING params:params success:nil failure:nil];
    }
}

+ (void)resetVideoFlow
{
    NSDictionary *params = @{@"param":@"none_force"};
    [ACCommandService execute:MSGID_BOSS_RESETVF params:params success:nil failure:nil];
}

+ (void)stopVideoFlow
{
    [ACCommandService execute:MSGID_STOP_VF params:nil success:nil failure:nil];
}

+ (void)syncCameraClock
{
    [ACCommandService syncCameraClockWithSuccess:nil failure:nil];
}

+ (void)syncCameraClockWithSuccess:(void (^)(id))success failure:(void (^)(id))failure
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *twentyFour = [[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"];
    dateFormatter.locale = twentyFour;
    [dateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [NSDate date];
    NSString *time = [dateFormatter stringFromDate:date];
    
    NSString *type = @"camera_clock";
    NSDictionary *params = @{@"param":time, @"type":type};
    [ACCommandService execute:MSGID_SET_SETTING params:params success:success failure:failure];
}

+ (void)getBatteryStatus
{
    [ACCommandService execute:MSGID_GET_BATTERY_LEVEL params:nil success:nil failure:nil];
}

+ (void)getPIVSupport
{
    NSDictionary *params = @{@"type":@"piv_enable"};
    [ACCommandService execute:MSGID_GET_SETTING params:params success:nil failure:nil];
}

+ (void)getAutoLowLightSupport
{
    NSDictionary *params = @{@"type":@"support_auto_low_light"};
    [ACCommandService execute:MSGID_GET_SETTING params:params success:nil failure:nil];
}

+ (void)quitIdelSendMsg_Id
{
    [ACCommandService execute:16777230 params:nil success:nil failure:nil];
}

+ (void)syncCameraParams
{
    [ACCommandService getAllCurrentSettings];
}

+ (void)setClientinfo
{
    NSDictionary *params = @{@"type":@"TCP", @"param":[ACCommandService ipAddressWIFI]};
    [ACCommandService execute:MSGID_SET_CLNT_INFO params:params success:nil failure:nil];
}

+ (NSString *)ipAddressWIFI {
    NSString *address = nil;
    struct ifaddrs *addrs = NULL;
    if (getifaddrs(&addrs) == 0) {
        struct ifaddrs *addr = addrs;
        while (addr != NULL) {
            if (addr->ifa_addr->sa_family == AF_INET) {
                if ([[NSString stringWithUTF8String:addr->ifa_name] isEqualToString:@"en0"]) {
                    address = [NSString stringWithUTF8String:
                               inet_ntoa(((struct sockaddr_in *)addr->ifa_addr)->sin_addr)];
                    break;
                }
            }
            addr = addr->ifa_next;
        }
    }
    freeifaddrs(addrs);
    return address;
}
@end
