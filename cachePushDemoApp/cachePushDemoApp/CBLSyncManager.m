//
//  CBLSyncManager.m
//  cachePushDemoApp
//
//  Created by Thiago Alencar on 2/3/15.
//  Copyright (c) 2015 Thiago Alencar. All rights reserved.
//

#import "CBLSyncManager.h"
#import "RequestCacheModel.h"

@implementation CBLSyncManager

+(CBLSyncManager*)sharedCBLSyncManager {
    static CBLSyncManager *_sharedCBLSyncManager = nil;
    static dispatch_once_t syncManager_onceToken;
    dispatch_once(&syncManager_onceToken, ^{
        _sharedCBLSyncManager = [[CBLSyncManager alloc] init];
    });
    return _sharedCBLSyncManager;
}

- (void)initSyncForDatabase:(CBLDatabase*)database
                             withURL:(NSURL*)remoteURL {
    _database = database;
    _remoteURL = remoteURL;
    
    pull = [_database createPullReplication:_remoteURL];
    push = [_database createPushReplication:_remoteURL];
    //one strategy to sync only specific cache is to create a pull filter in the pull replication itself
    //this will make the server "push" cache data only content for the respective channels.
    //make sure you have no cached data (e.g. delete the app first) to see effect of this
    //the channels here reflect the calls from the popUp dialog sorting by price etc
    //e.g.:
    //pull.channels = [[NSArray alloc] initWithObjects:@"popularity", @"brand", nil];
    pull.continuous = push.continuous = YES;
    
    [self listenForReplicationEvents:push];
    [self listenForReplicationEvents:pull];
}

-(void)setCurrentContext: (NSString*) contextName
{
    /*To understand anything is to make sense of its context. What we may see as obvious and self-evident, 
     is all but unknown to someone without our frame of reference. Our inability to truly understand or 
     appreciate the differences in perspective and information between ourselves and others is perhaps our most basic shortcoming.
     So, make sure you set the right context ;)*/
    
    [pull stop];
    currentContext = contextName;
    pull.channels = [[NSArray alloc] initWithObjects:contextName, nil];
    [pull start];

}

-(void)addCacheChangesObserver: (id) observer selector: (SEL) _selector name: (NSString*) _name
{
    [[NSNotificationCenter defaultCenter] addObserver: observer
                                             selector: _selector
                                                 name: _name
                                               object: self.database];
}

-(void)removeCacheChangesObserver: (id) observer
{
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
}

-(void)startPull { [pull start]; }
-(void)startPush { [push start]; }
-(void)stopPull  { [pull stop];  }
-(void)stopPush  { [push stop];  }

-(void)databaseChanged: (NSNotification*) dbNotification
{
    int docsChangedCounter = 0;
    for (CBLDatabaseChange* change in dbNotification.userInfo[@"changes"])
    {
        CBLDocument * changedDoc = [_database documentWithID:change.documentID];
        NSString * type = changedDoc[@"type"];
        if ([type isEqualToString: [RequestCacheModel type]]) {
            docsChangedCounter++;
            RequestCacheModel * model = [RequestCacheModel modelForDocument: [_database documentWithID:change.documentID]];
            [self injectRequestCache: model];
            //NSLog(@"db changed with docID: %@", change.documentID);
        }
    }
    NSLog(@"Injected %i item(s) from dbChanges..", docsChangedCounter);
}

-(void)setAuthorizationCookieToValue: (NSString *)sessionValue
{
    NSLog(@"Setting authorization cookie");
    [pull setCookieNamed:@"SyncGatewaySession" withValue:sessionValue path:nil expirationDate:nil secure:NO];
    [push setCookieNamed:@"SyncGatewaySession" withValue:sessionValue path:nil expirationDate:nil secure:NO];
}

-(void)injectAllCBCacheDataToNSURLCache{
    
    //Sync existing local docs with NSURLCache's storeCachedResponse:forRequest:
    NSLog(@"injectAllCBCacheDataToNSURLCache");
    NSError* error;

    CBLQueryEnumerator *cacheEnum = [[RequestCacheModel queryAllCacheFromDatabase:_database] run:&error];
    if (cacheEnum)  
    {
        for (CBLQueryRow* row in cacheEnum)
        {
            RequestCacheModel * model = [RequestCacheModel modelForDocument: row.document];
            [self injectRequestCache:model];
        }
    }
}

-(void)injectRequestCache:(RequestCacheModel*) model
{
    //create NSCachedURLResponse from doc
    NSURL * url = [NSURL URLWithString:model.document.documentID];
    //NSLog(@"Injecting request: %@", model.document.documentID);
    //NSMutableDictionary * fakeHeaders = [model.responseHeaders mutableCopy];
    //[fakeHeaders setValue:@"public, max-age=31536000" forKey:@"Cache-Control"];
    //[fakeHeaders setValue:@"Mon, 23 Feb 2015 14:06:04 GMT" forKey:@"Date"];
    //[fakeHeaders setValue:@"Mon, 23 Feb 2016 14:06:04 GMT" forKey:@"Expires"];
    //[fakeHeaders setValue:@"Mon, 17 Feb 2015 14:06:04 GMT" forKey:@"Last-Modified"];
    NSHTTPURLResponse * response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:model.statusCode HTTPVersion:model.httpVersion headerFields:model.responseHeaders];
    
    NSData * responseData;
    //if images stored as attachments:
    //CBLAttachment * attachment = [model attachmentNamed:[url lastPathComponent]];
    //if(attachment)
    //    responseData = [attachment content];
    //else
    responseData = model.responseData;
    
    NSCachedURLResponse * cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:responseData];
    NSURLRequest * request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];
    [[NSURLCache sharedURLCache] storeCachedResponse:cachedResponse forRequest:request];
}

#pragma mark Replication Events


- (void) listenForReplicationEvents: (CBLReplication*) repl
{
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(replicationProgress:)
                                                 name: kCBLReplicationChangeNotification
                                               object: repl];
}

- (void) replicationProgress: (NSNotificationCenter*)n {
    bool active = false;
    unsigned completed = 0, total = 0;
    CBLReplicationStatus status = kCBLReplicationStopped;
    NSError* error = nil;
    for (CBLReplication* repl in @[pull]) {
        NSLog(@"current status: %i for repl: %@", repl.status, repl);
        status = MAX(status, repl.status);
        if (!error)
            error = repl.lastError;
        if (repl.status == kCBLReplicationActive) {
            active = true;
            completed += repl.completedChangesCount;
            total += repl.changesCount;
        }
    }
    
    //[self updateActivityForStatus:status];
    //TODO: need to be removed after 'CBLReplicationStatus' in CBL SDK will be fixed.
    if(total == completed)
    {
        NSLog(@"COMPLETED SYNCING.");
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        static BOOL changesInstalled = FALSE;
        if (!changesInstalled) {
            changesInstalled = TRUE;
            //observe database changes in order to inject new response cache data as they become available
            [[NSNotificationCenter defaultCenter] addObserver: self
                                                     selector: @selector(databaseChanged:)
                                                         name: kCBLDatabaseChangeNotification
                                                       object: self.database];
        }
        
        //        CBLQuery* query = [self.db createAllDocsQuery];
        //        query.allDocsMode = kCBLOnlyConflicts;
        //        CBLQueryEnumerator* result = [query run: &error];
        //        for (CBLQueryRow* row in result) {
        //            if (row.conflictingRevisions != nil) {
        //                NSLog(@"!!! Conflict in document %@", row.documentID);
        //                [self beginConflictResolution: row.document];
        //            }
        //        }
    }
    else
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
    
    if (active != _active || completed != _completed || total != _total || status != _status
        || error != _error) {
        _active = active;
        _completed = completed;
        _total = total;
        _progress = (completed / (float)MAX(total, 1u));
        _status = status;
        _error = error;
        NSLog(@"SYNCMGR: active=%d; status=%d; %u/%u; %@",
              active, status, completed, total, error.localizedDescription); //FIX: temporary logging
    }
}

@end
