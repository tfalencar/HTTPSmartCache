//
//  AppDelegate.m
//  cachePushDemoApp
//
//  Created by Thiago Alencar on 11/7/14.
//  Copyright (c) 2014 Thiago Alencar. All rights reserved.
//

#import "AppDelegate.h"
#import "CBLSyncManager.h"
#import "RequestCacheModel.h"

#define kDatabaseName @"localcache" 
//replace with your sync gateway url:
#define kRemoteCouchBaseURL @"http://ti.eng.br:4984/sync_gw_demo"

@implementation AppDelegate

@synthesize database;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    self.window.tintColor = [UIColor brownColor];
    
#pragma mark - Set app-wide shared cache
    NSUInteger cacheSizeMemory = 500*1024*1024; // 500 MB
    NSUInteger cacheSizeDisk = 1000*1024*1024; // 1000 MB
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:cacheSizeMemory diskCapacity:cacheSizeDisk diskPath:@"nsurlcache"];
    [NSURLCache setSharedURLCache:sharedCache];
    [sharedCache removeAllCachedResponses]; //for testing
    sleep(1);
    
#pragma mark - Initialize Couchbase Lite
    NSError* error;
    self.database = [[CBLManager sharedInstance] databaseNamed: kDatabaseName error: &error];
    if (!self.database) {
        NSLog(@"Couldn't open database: %@", error);
        return NO;
    }
    //show database location
    NSString *databaseLocation = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent]
     stringByAppendingString: @"/Library/Application Support/CouchbaseLite"];
    NSLog(@"Database %@ at %@", kDatabaseName,
          [NSString stringWithFormat:@"%@/%@%@", databaseLocation, kDatabaseName, @".cblite"]);
    
#pragma mark - Setup/update http cache injection with couchbase mobile
  
    //cache data / docs should be deleted and "purged" once they are not relevant anymore
    //There are several strategies that can be used to enforce this. One example would be
    //the server-side to 'delete' documents which are irrelevant, then here at the client we
    //purge all documents which have their "deleted" property set to true
    //cache document updates will be handled automatically
    
    sharedSyncManager = [CBLSyncManager sharedCBLSyncManager];
    [sharedSyncManager initSyncForDatabase:self.database withURL:[NSURL URLWithString:kRemoteCouchBaseURL]];
    //uncomment startPush if you have setup with your own sync gateway for creating docs (mine at ti.eng.br won't allow writing).
    //[sharedSyncManager startPush];
    [sharedSyncManager startPull];
    [sharedSyncManager injectAllCBCacheDataToNSURLCache];
    
    //the synced cached responses will cause the respective http request to respond instantly, otherwise it will
    //go through the normal HTTP request flow.
    
    return YES;
}

#pragma mark - App Events

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
