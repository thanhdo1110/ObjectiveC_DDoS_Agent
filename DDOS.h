// file .h
// Project: DDOS
// Created by @dothanh1110 on 1/2/2025.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

@interface DDOS : NSObject

@property (nonatomic, strong) NSString *currentURL;
@property (nonatomic, assign) BOOL isDDOSming;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (nonatomic, assign) NSInteger threads;
@property (nonatomic, assign) NSTimeInterval delay;
@property (nonatomic, strong) NSString *requestType;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTask;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, assign) BOOL isAlertShowing;
@property (nonatomic, strong) NSString *deviceUUID;  
- (void)setLink:(NSString *)link;
+ (instancetype)sharedClient;
- (NSString *)getLink;
- (void)startDDOS;
- (void)stopDDOSming;
- (void)checkURL;
- (void)handleJSONResponse:(NSDictionary *)json;
- (void)showAlertWithText:(NSString *)text andLink:(NSString *)link;
@end