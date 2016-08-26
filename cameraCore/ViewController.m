//
//  ViewController.m
//  cameraCore
//
//  Created by neo on 16/8/16.
//  Copyright © 2016年 xy. All rights reserved.
//

#import "ViewController.h"
#import "ACSocketService.h"
#import "Masonry.h"
#import "UIControl+BlocksKit.h"
#import "ACCommandService.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[ACSocketService shared] startCommandSocketSession];
    
    UIButton *button = [UIButton new];
    [button setTitle:@"click" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:button];
    [button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.view);
        make.top.mas_equalTo(self.view.mas_top).offset(40);
        make.height.mas_equalTo(50);
    }];
    
    [button bk_addEventHandler:^(id sender) {
        [ACCommandService execute:MSGID_GET_ALL_CURRENT_SETTINGS params:nil success:^(id responseObject) {
            NSLog(@"res: %@", responseObject);
        } failure:^(id error) {
            
        }];
    } forControlEvents:UIControlEventTouchUpInside];
}

@end
