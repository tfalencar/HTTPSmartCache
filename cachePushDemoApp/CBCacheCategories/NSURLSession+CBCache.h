//
//  NSURLSession+CBCache.h
//  cachePushDemoApp
//
//  Created by Thiago Alencar on 2/12/15.
//  Copyright (c) 2015 Thiago Alencar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CouchbaseLite/CouchbaseLite.h>

@interface NSURLSession (CBCache)

-(NSURLSessionDataTask *)cbcache_dataTaskWithURL:(NSURL *)url
                              completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler;

-(NSURLSessionDataTask *)cbcache_dataTaskWithURL:(NSURL *)url;

-(NSURLSessionDataTask *)cbcache_dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler;
-(NSURLSessionDataTask *)cbcache_dataTaskWithRequest:(NSURLRequest *)request;


@property (nonatomic, retain) CBLDatabase * databaseObject;

//if TRUE, will not record if HTTP response header says so
@property (nonatomic) BOOL complyToHttpHeaders;

//concept of context maps to channels in couchbase mobile
//this can be used with filters to partition cache data depending
//on certain app conditions; This way it is possible for example
//to load/update just a small set of data on demand depending on e.g.
//where the user is on your application (e.g. pull.channels = @[@"mainMenu"])
@property (nonatomic, retain) NSString * cacheContext;

+(BOOL)isStoredAsAttachmentForMimeType:(NSString *) mimeType;


@end
