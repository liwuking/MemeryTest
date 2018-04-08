//
//  ViewController.m
//  MemoryTest
//
//  Created by lbe on 2018/4/8.
//  Copyright © 2018年 liwuyang. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property(nonatomic,strong) id obj;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.obj = [[NSObject alloc] init];
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
