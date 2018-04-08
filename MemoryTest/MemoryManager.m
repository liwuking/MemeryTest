//
//  MemoryManager.m
//  MemoryTest
//
//  Created by lbe on 2018/4/8.
//  Copyright © 2018年 liwuyang. All rights reserved.
//

#import "MemoryManager.h"
#import <objc/runtime.h>
#import <objc/message.h>
@implementation MemoryManager

-(void)testMemory {
    
    /*
     apple采用散列表来管理引用计数(以内存地址为key，引用计数为value)，这样做的的advantages：方便调试，只要引用计数表没有被破坏，就能够确认各内存块的位置，因为hashTable记录有各个内存块的地址，所以通过hashTable可以追溯到各对象的内存块。
     */
    
    /********** autorelease 所有调用了autorelease的对象实例，在pool废弃时都将调用release方法；
     autorelese的实质是将对象实例加入到pool的array里；
     在cocoa框架中，程序的主循环NSRunLoop会对NSAutoreleasePool进行生成、持有、废弃处理，所以开发时不一定非得手动生成pool；
     */
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSObject *obj = [[NSObject alloc] init];
    [obj autorelease] ;
    [pool drain];
    
    //******* 引用计数式的内存管理在ARC和MRC中是一致的，只是在ARC中，编译器帮我们做了内存管理部分的工作
    
    /****** 所有权修饰符（ARC模式下才有），分_strong、_weak、_unsafe_unretained、_autoreleasing四种。ARC有效时，id类型和对象类型必须附加所有权修饰符，_strong是默认的所有权修饰符；_strong、_weak、_autoreleasing类型变量初始化为nil；
     _strong表示强引用，持有强引用的变量在超出其作用域时被废弃，随着强引用的失效，引用的对象随之失效;
     _weak表示弱引用，可以解决循环引用的问题；持有某对象的弱引用时，若该对象被废弃，那_weak修饰的变量会被自动设置为nil，所以可以通过判断_weak变量是否为nil来判断对象是否被释放；在ios4中，必须使用_unsafe_unretained来代替_weak，如果赋值给_unsafe_unretained修饰的变量的对象不存在，则调用此变量的会引起崩溃；
     _autorelesing ARC有效时不能使用autorelease和NSAutoReleasePool，但仍可使用自动释放池，通过@autoreleasepool来代替NSAutoReleasePool生成、持有、废弃这一过程:
                                             @autoreleasepool {
                                                id __autoreleasing obj = [[NSObject alloc] init];
                                             }
     可非显示使用_autoreleasing的情况：
     1，在ARC有效时，编译器会检测方法名是否以alloc、new、copy、mutablecopy开头，如果不是则自动将返回的对象注册到autoreleasepool中；
     访问_weak修饰符修饰的对象时，必定访问注册到autoreleasepool中的对象。_weak修饰变量持有对象的弱引用，使用过程中可能对象已经废弃，如果把要访问的对象注册到@autoreleasepool中，那么在@autoreleasepool释放之前，该对象都是有效的；
     2，id或者对象的指针在没有显示指定时，会被附加上_autoreleasing修饰符:id *obj == id _autoreleasing *id / NSObject *obj == NSObject * _autoreleasing *obj
    
     不管ARC是否有效，推荐使用@autorelease，块级管理可读性更强；
     
     */
    
    //******** ARC有效时不能显示调用dealloc，[super dealloc]会报错。只能做些对象废弃后的处理；
    
    /********* _strong修饰符
     本质是编译器帮忙加了release --- objc_release(objc)；
     id objc = objc_msgSend(NSMutableArray, @selector(alloc));
     objc_msgSend(objc, @selector(init));
     objc_release(obj);
     
     可非显示使用_autoreleasing的第一种情况，函数返回值不会注册到autoreleasepool中，因为有最优化程序存在。objc_autoreleaseRetainValue和objc_retainedAutoreleaseRetainValue，两则都用于返回注册到autoreleasepool中的对象。objc_autoreleaseRetainValue会检查后续对象的消息列表中是否有objc_retainedAutoreleaseRetainValue，如果有则不将对象注册到autoreleasepool而是直接传递；
     id objc = objc_msgSend(NSMutableArray, @selector(array));
     objc_retainAutoreleasedReturnValue(objc);
     objc_release(obj);
     -----------------------------------
     +(NSMutableArray *)array {
     id objc = objc_msgSend(NSMutableArray, @selector(alloc));
     objc = objc_msgSend(objc, @selector(init));
     objc_autoreleaseReturnValue(objc);
     objc_release(obj);
     return objc;
     }
     
     */
    
    /****** _weak修饰符
     1，使用_weak修饰符的变量引用的对象被废弃时，自动赋值为nil
     2，使用_weak修饰符的变量即使用注册到autoreleasepool中的对象
     */

    
}


@end
