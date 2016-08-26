//
//  ACSocketService.m
//  cameraCore
//
//  Created by neo on 16/8/16.
//  Copyright © 2016年 xy. All rights reserved.
//

#import "ACSocketService.h"
#import "ACSocketObject.h"
#import "ACCommandObject.h"
#import "ACCommandService.h"

@interface ACSocketService ()
@property (nonatomic, strong) NSMutableArray *queue;
@property (nonatomic, strong) NSCondition *condition;
@property (nonatomic, assign) BOOL canSendNewCommand;
@property (nonatomic, strong) ACCommandObject *cmdObject;

@property (strong, nonatomic) NSMutableData *cmdSocketData;
@property (strong, nonatomic) NSMutableData *datSocketData;

@property (nonatomic, strong) NSMutableDictionary *successHandlers;
@property (nonatomic, strong) NSMutableDictionary *failureHanlders;
@property (nonatomic, strong) NSMutableDictionary *notifyHanlders;//字典以通知名为key，value是一个"以target为key，以block为value的字典“

@end

@implementation ACSocketService

static ACSocketService *socketService = nil;

#pragma mark - life cycle
+ (ACSocketService *)shared {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        socketService = [[self alloc] init];
    });
    
    return socketService;
}

- (id)init
{
    if (socketService != nil) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        
        self.condition = [NSCondition new];
        self.canSendNewCommand = YES;
        
        self.successHandlers = [NSMutableDictionary dictionary];
        self.failureHanlders = [NSMutableDictionary dictionary];
        self.notifyHanlders  = [NSMutableDictionary dictionary];
        
        [self systemProbe];
        
        [NSThread detachNewThreadSelector:@selector(commandLoop) toTarget:self withObject:nil];
        
        self.commandSocket = [[AsyncSocket alloc] initWithDelegate:self];
        [self.commandSocket setRunLoopModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
        
        self.dataSocket = [[AsyncSocket alloc] initWithDelegate:self];
        [self.dataSocket setRunLoopModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
        
    }
    return self;
}

#pragma mark - command queue operation
- (NSMutableArray *)queue
{
    if (!_queue) {
        _queue = [[NSMutableArray alloc] init];
    }
    return _queue;
}

- (void)enQueue:(id)object
{
    @synchronized (self.queue) {
        if (self.queue) {
            [_condition lock];
            [self.queue addObject:object];
            [_condition signal];
            [_condition unlock];
        }
    }
}

- (id)deQueue
{
    id object = nil;
    
    @synchronized (self.queue) {
        if (self.queue && _queue.count > 0) {
            object = [self.queue objectAtIndex:0];
            if (object) {
                [self.queue removeObjectAtIndex:0];
            }
        }
    }
    
    return object;
}

- (void)resetQueue
{
    @synchronized (self.queue) {
        if (self.queue) {
            [self.queue removeAllObjects];
        }
    }
}

- (void)commandLoop
{
    while (YES) {
        [_condition lock];
        
        while (_queue.count == 0 || !self.canSendNewCommand) {
            [_condition wait];
        }
        
        self.canSendNewCommand = NO;
        
        id object = [self deQueue];
        _cmdObject = (ACCommandObject *)object;
        
        NSString *jsonToSend = [_cmdObject.socketObject objectToJSON];
        NSLog(@"send: %@", jsonToSend);
        
        NSData *cmdData = [jsonToSend dataUsingEncoding:NSUTF8StringEncoding];
        if (!cmdData) return;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.commandSocket writeData:cmdData withTimeout:-1 tag:0];
        });

        [_condition unlock];
    }
}

#pragma public method

- (void)startCommandSocketSession
{
    if (![self.commandSocket isConnected]) {
        [self.commandSocket connectToHost:CAMERA_IP onPort:CAMERA_CMD_PORT withTimeout:TIMEOUT error:nil];
    }
}

- (void)stopCommandSocketSession
{
    [self.commandSocket disconnect];
}

- (void)startDataSocketSession
{
    if (![self.dataSocket isConnected]) {
        [self.dataSocket connectToHost:CAMERA_IP onPort:CAMERA_DAT_PORT withTimeout:TIMEOUT error:nil];
    }
}

- (void)stopDataSocketSession
{
    [self.dataSocket disconnect];
}

#pragma AsyncSocket Delegate

- (BOOL)onSocketWillConnect:(AsyncSocket *)sock
{
    if (sock == self.commandSocket) {
        NSLog(@"onSocketWillConnect---commandSocket");
    }
    
    if (sock == self.dataSocket) {
        NSLog(@"onSocketWillConnect---dataSocket");
    }
    return YES;
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    if (sock == self.commandSocket) {
        NSLog(@"didConnectToHost  7878");
        [ACCommandService startSession];
        [sock readDataWithTimeout:-1 tag:0];
    } else {
        NSLog(@"didConnectToHost  8787");
    }
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
    if (sock == self.commandSocket) {
        NSLog(@"onSocketDidDisconnect---commandSocket");
    }
    
    if (sock == self.dataSocket) {
        NSLog(@"onSocketDidDisconnect---dataSocket");
    }
}

- (NSTimeInterval)onSocket:(AsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length
{
    
    return 0; // keep time out value as usual
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    //NSLog(@"didReadData---%@", data);
    if (sock == self.commandSocket) {
        [self handleCommandSocket:sock data:data tag:tag];
        [self.commandSocket readDataWithTimeout:-1 buffer:nil bufferOffset:0 maxLength:0 tag:0];
    }
    
    if (sock == self.dataSocket) {
        NSLog(@"onSocketDidDisconnect---dataSocket");
    }
}

#pragma mark - handle
- (void)handleCommandSocket:(AsyncSocket *)sock data:(NSData *)data tag:(long)tag
{
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"[rcv]: %@", dataString);
    
    if (!_cmdSocketData) {
        _cmdSocketData = [[NSMutableData alloc] init];
    }
    
    [self.cmdSocketData appendData:data];
    
    NSMutableArray *mutArr = [JSONParser parserData:&_cmdSocketData];
    
    for (NSDictionary *dic in mutArr)
    {
        //DDLogError(@"--[recvMsg]:%ld bytes\n%@", (unsigned long)data.length, dic);
        int msg_id_int = [dic[@"msg_id"] intValue];
        NSString *msg_id = [NSString stringWithFormat:@"%d", msg_id_int];
        
        //1793命令说明有另外的app尝试连接当前相机，本app需要在800ms内回复该消息，否则相机会将控制权交给另外一个app
        //[self check1793message:msg_id];
        
        if (msg_id_int == MSGID_CALLBACK_NOTIFICATION) {
            
            NSString *type = dic[@"type"];
            //NSString *param = dic[@"param"];
            
            NSMutableDictionary *blocksDic = self.notifyHanlders[type];
            if (blocksDic) {
                [blocksDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    //key 是监听者自己self
                    void (^block)(NSDictionary *dictionnary) = obj;
                    block(dic);
                }];
            }
            
        } else if (_cmdObject && _cmdObject.socketObject.msg_id == msg_id_int) {
            
            self.canSendNewCommand = YES; // 是上一条发出指令的对应回复，允许继续下发新的指令
            
            int rval = [dic[@"rval"] intValue];
            if (rval < 0) {
                if ([self failureHandlerIsSupport:msg_id]) {
                    NSArray *handlers = self.failureHanlders[msg_id];
                    if (handlers) {
                        [handlers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            void (^block)(NSDictionary *dictionnary) = obj;
                            block(dic);
                        }];
                    }
                }
                
                if (_cmdObject.failureBlock) {
                    _cmdObject.failureBlock(dic);
                    _cmdObject = nil;
                }
                
            } else {
                if ([self successHandlerIsSupport:msg_id]) {
                    NSArray *handlers = self.successHandlers[msg_id];
                    if (handlers) {
                        [handlers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            void (^block)(NSDictionary *dictionnary) = obj;
                            block(dic);
                        }];
                    }
                }

                if (_cmdObject.successBlock) {
                    _cmdObject.successBlock(dic);
                    _cmdObject = nil;
                }
            }
        } else {
            //既不是相机通知msg_id==7， 也不是上一条发出去的指令的回复，出错
            NSLog(@"既不是相机通知msg_id==7， 也不是上一条发出去的指令的回复，出错!!!!!!!!!!!!!!!!!!!!!");
        }
    }
}

#pragma private method
#pragma mark - 系统级命令监听器，主要影响cameraHAM中的参数
- (void)systemProbe
{
    //监听Start session
    NSString *msgID = [NSString stringWithFormat:@"%u", MSGID_START_SESSION];
    [self addSystemHandlerForMsgId:msgID success:^(id responseObject) {
        NSLog(@"------------START_SESSION success success---%@", responseObject);
        NSDictionary *dic = (NSDictionary *)responseObject;
        [ACSocketService shared].tokenNumber = [dic[@"param"] intValue];
    } failure:^(id errorObject) {

    }];

}

#pragma mark - system msg id handler register

- (void)addSystemHandlerForMsgId:(NSString *)msg_id
                    success:(void (^)(id responseObject))success
                    failure:(void (^)(id errorObject))failure
{
    NSMutableArray *successHandlers = (NSMutableArray *)self.successHandlers[msg_id];
    if (!successHandlers) {
        successHandlers = [NSMutableArray array];
        self.successHandlers[msg_id] = successHandlers;
    }
    if (success) {
        [successHandlers addObject:[success copy]];
    }
    
    NSMutableArray *failureHandlers = (NSMutableArray *)self.failureHanlders[msg_id];
    if (!failureHandlers) {
        failureHandlers = [NSMutableArray array];
        self.failureHanlders[msg_id] = failureHandlers;
    }
    if (failure) {
        [failureHandlers addObject:[failure copy]];
    }
}

- (void)userListenOnNotification:(NSString *)notification forTarget:(NSString *)target success:(void (^)(id))success failure:(void (^)(id))failure
{
    NSMutableDictionary *notifyListeners = self.notifyHanlders[notification];
    if (!notifyListeners) {
        notifyListeners = [NSMutableDictionary dictionary];
        self.notifyHanlders[notification] = notifyListeners;
    }
    [notifyListeners setObject:success forKey:target];
    
}

- (void)userRemoveListener:(NSObject *)notification forTarget:(NSString *)target
{
    NSMutableDictionary *notifyListeners = self.notifyHanlders[notification];
    if (notifyListeners) {
        [notifyListeners removeObjectForKey:target];
    }
}

- (BOOL)successHandlerIsSupport:(NSString *)msg_id
{
    NSArray *allKeys = [self.successHandlers allKeys];
    if ([allKeys containsObject:msg_id]) {
        return YES;
    }
    return NO;
}

- (BOOL)failureHandlerIsSupport:(NSString *)msg_id
{
    NSArray *allKeys = [self.failureHanlders allKeys];
    if ([allKeys containsObject:msg_id]) {
        return YES;
    }
    return NO;
}

- (void)sendCommandWithSocketObject:(ACSocketObject *)socketObj success:(void (^)(id))success failure:(void (^)(id))failure
{
    ACCommandObject *obj = [ACCommandObject objectWithSocketObject:socketObj success:success failure:failure];
    [self enQueue:obj];
}


@end
