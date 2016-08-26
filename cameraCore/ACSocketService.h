//
//  ACSocketService.h
//  cameraCore
//
//  Created by neo on 16/8/16.
//  Copyright © 2016年 xy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACDefines.h"
#import "AsyncSocket.h"
#import "ACSocketObject.h"
#import "JSONParser.h"

@protocol AsyncSocketDelegate;

@interface ACSocketService : NSObject <AsyncSocketDelegate>

@property (nonatomic, strong) AsyncSocket *commandSocket;
@property (nonatomic, strong) AsyncSocket *dataSocket;
@property (nonatomic, assign) int         tokenNumber;

+ (ACSocketService *)shared;

- (void)startCommandSocketSession;
- (void)stopCommandSocketSession;

- (void)startDataSocketSession;
- (void)stopDataSocketSession;

- (void)addSystemHandlerForMsgId:(NSString *)msg_id
                    success:(void (^)(id responseObject))success
                    failure:(void (^)(id errorObject))failure;

- (void)sendCommandWithSocketObject:(ACSocketObject *)socketObj
                            success:(void (^)(id responseObject))success
                            failure:(void (^)(id errorObject))failure;


- (void)userListenOnNotification:(NSString *)notification
                   forTarget:(NSString *)target
                     success:(void (^)(id responseObject))success
                     failure:(void (^)(id errorObject))failure;

- (void)userRemoveListener:(NSObject *)notification forTarget:(NSString *)target;


@end
