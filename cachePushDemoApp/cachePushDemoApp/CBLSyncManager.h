//
//  CBLSyncManager.h
//  cachePushDemoApp
//
//  Created by Thiago Alencar on 2/3/15.
//  Copyright (c) 2015 Thiago Alencar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CouchbaseLite/CouchbaseLite.h>

@interface CBLSyncManager : NSObject
{
    CBLReplication *pull;
    CBLReplication *push;
    NSString * currentContext;
}

@property (readonly) CBLDatabase *database;
@property (readonly) NSURL *remoteURL;

@property (nonatomic, readonly) unsigned completed, total;
@property (nonatomic, readonly) float progress;
@property (nonatomic, readonly) bool active;
@property (nonatomic, readonly) CBLReplicationStatus status;
@property (nonatomic, readonly) NSError* error;

-(void)startPull;
-(void)startPush;
-(void)stopPull;
-(void)stopPush;

- (void)initSyncForDatabase:(CBLDatabase*)database
                             withURL:(NSURL*)remoteURL;

-(void)setCurrentContext: (NSString*) contextName;

-(void)setAuthorizationCookieToValue: (NSString *)sessionValue;

-(void)injectAllCBCacheDataToNSURLCache;

-(void)addCacheChangesObserver: (id) observer selector: (SEL) _selector name: (NSString*) _name;

-(void)removeCacheChangesObserver: (id) observer;


+(CBLSyncManager*)sharedCBLSyncManager;

@end
