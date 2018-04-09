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
     
     id __weak obj1 = self.obj;
     编译器模拟代码
         id obj1;
         objc_initWeak(&obj1,_obj);
         id teamp = objc_loadWeakRetained(&obj1);
         objc_autorelease(teamp);
         objc_destroyWeak(&obj1);
         通过objc_initWeak函数初始化附有__weak修饰符的obj1，在变量作用域结束时通过objc_destroyWeak释放该变量;
         objc_loadWeakRetained函数取出赋值给weak变量的对象并retain；objc_autorelease将对象注册到autoreleasepool中；
     等同：
         id obj1;
         obj1 = 0；
         objc_storeWeak(&obj1,_obj);
         objc_storeWeak(&obj1,0);
     
         objc_storeWeak将第二参数的赋值对象的地址作为value，将第一参数附有_weak修饰符的变量的地址作为key，保存到weak表中。一个对象可对应多个_weak变量
     
     对象被废弃时的动作如下：
         1，从weak表中获取废弃对象的地址作为value的记录；
         2，将包含在记录中的_weak变量的地址都置为nil;
         3，从weak表中删除该记录；
         4，从引用计数表中删除废弃对象的地址作为key的记录；
     
     得出结论1，2；
     
     如果大量使用weak，则会消耗cpu资源，尽量只在解决循环引用的时候使用；
     如果大量使用weak变量，则注册到autoreleasepool中的对象也会相应增加，所以先暂时赋值给_strong类型变量，然后赋值给_weak变量就可以解决此类问题；
     
     */

    /****** _autoreleasing. ARC下将对象赋值给附有_autoreleasing修饰符的变量等同于MRC下调用对象的autorelease方法;
     id pool = objc_autoreleasePoolPush();
     id objc = msg_send(NSMutableArray,@selector(alloc));
     objc = msg_send(objc,@selector(init));
     objc_autorelease(objc);
     objc_autoreleasePoolPop(pool);
     
     id pool = objc_autoreleasePoolPush();
     id objc = msg_send(NSMutableArray,@selector(array));
     retainAutoreleasedRetainvalue(objc);
     objc_autorelease(objc);
     objc_autoreleasePoolPop(pool);
     持有对象的方法由alloc变为retainAutoreleasedRetainvalue；
     */
    /****** 获取引用计数数值的方法
     _objc_rootRetainCount(obj);不能完全信任该方法，对于已释放或者不正确的对象地址，有时候也返回‘1’，在多线程环境中，因为存在竞态条件的问题，所以取得的数值不一定可信；此方法在调试时很有用，但需要考虑它的局限性；
     */
    
}


@end
