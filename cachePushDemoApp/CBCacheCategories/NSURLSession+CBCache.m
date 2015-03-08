//
//  NSURLSession+CBCache.m
//  cachePushDemoApp
//
//  Created by Thiago Alencar on 2/12/15.
//  Copyright (c) 2015 Thiago Alencar. All rights reserved.
//

#import "NSURLSession+CBCache.h"
#import "RequestCacheModel.h"
#import <objc/runtime.h>

@implementation NSURLSession (CBCache)

static void * kComplyHeaderKey = @"ComplyHeaderKey";

-(void)setComplyToHttpHeaders:(BOOL)newAssociatedObject{
    objc_setAssociatedObject(self, kComplyHeaderKey, [NSNumber numberWithInt:newAssociatedObject], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(BOOL)complyToHttpHeaders{
    if (((NSNumber*)objc_getAssociatedObject(self, kComplyHeaderKey)).intValue == 1) return TRUE;
    else return FALSE;
}

-(void)setDatabaseObject:(CBLDatabase*)newAssociatedObject {
    objc_setAssociatedObject(self, @selector(databaseObject), newAssociatedObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(CBLDatabase*)databaseObject {
    return objc_getAssociatedObject(self, @selector(databaseObject));
}

-(void)setCacheContext:(NSString*)contextString {
    objc_setAssociatedObject(self, @selector(cacheContext), contextString, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSString*)cacheContext{
    return objc_getAssociatedObject(self, @selector(cacheContext));
}

-(NSURLSessionDataTask *)cbcache_dataTaskWithURL:(NSURL *)url
                       completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler
{
    NSURLSessionDataTask * dataTask;
    
    //here we're on main thread: be careful not to add long-running operations or it will drop FPS
    NSString * documentID = [url absoluteString];
    
    //NSDate * timingDate = [NSDate date];
    RequestCacheModel * existingCache = [[RequestCacheModel alloc] initFromExistingDocumentInDatabase:self.databaseObject withID:documentID];
    //NSLog(@"Time taken: %f", [[NSDate date] timeIntervalSinceDate: timingDate]);
    
    if (!existingCache) {
        
        //Otherwise proceed by simply forwarding the request to NSURLSession
        dataTask = [self dataTaskWithURL:url completionHandler:
                    ^(NSData *data, NSURLResponse *response, NSError *error) {
                        if (error){
                            NSLog(@"Error: %@", error);
                            completionHandler(data, response, error);
                        }
                        else if([((NSHTTPURLResponse*)response) statusCode] != 200)
                        {
                            NSLog(@"Status Code Error: %ld", (long)[((NSHTTPURLResponse*)response) statusCode]);
                            NSString * errorMessage = [NSString stringWithFormat:@"%@ %@",
                                                       NSLocalizedString(@"dataTaskWithURL was unsuccessful for:", nil),
                                                       [url absoluteString]];
                            NSString * reasonMessage = [NSString stringWithFormat:@"%@ %ld",
                                                        NSLocalizedString(@"UIImageView+CBCache requires response with status code 200, received: ", nil),
                                                        (long)[((NSHTTPURLResponse*)response) statusCode]];
                            NSDictionary *userInfo = @{
                                                       NSLocalizedDescriptionKey: errorMessage,
                                                       NSLocalizedFailureReasonErrorKey: reasonMessage,
                                                       };
                            NSError * statusCodeError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:userInfo];
                            if (completionHandler) completionHandler(data, response, statusCodeError);
                        }
                        else
                        {
                            //check if we're supposed to cache data based on http response header
                            if (self.complyToHttpHeaders) {
                                NSDictionary * responseHeaders = [((NSHTTPURLResponse*)response) allHeaderFields];
                                NSString * cacheControl = [NSString stringWithFormat:@"%@", [responseHeaders objectForKey:@"Cache-Control"]];
                                if ([cacheControl containsString:@"no-store"] || [cacheControl containsString:@"no-cache"]) {
                                    NSLog(@"Complying to http cache control and not caching response for %@", [url absoluteString]);
                                    NSLog(@"Header: %@", cacheControl);
                                    completionHandler(data, response, error);
                                    return;
                                }
                            }
                            
                            //code here isn't in the main thread, neither we'd like to be (otherwise we could affect the UI performance)
                            //since we consider the CBL database instance to be in the main thread, and since CBL iOS does not allow
                            //direct multi-thread access, we need to complete the operation with the CBL API's background block.
                            
                            CBLManager* mgr = self.databaseObject.manager;
                            NSString* name = self.databaseObject.name;
                            [mgr backgroundTellDatabaseNamed: name to: ^(CBLDatabase *bgdb)
                            {
                                NSLog(@"Create/update CBL cached document with new response for URL: %@", url);
                                //one might want to use [url lastPathComponent] instead of full path depending on the backend setup
                                RequestCacheModel * requestCache = [[RequestCacheModel alloc]
                                                                    initInDatabase:bgdb withID: documentID];
                                if([NSURLSession isStoredAsAttachmentForMimeType:response.MIMEType])
                                {
                                    [requestCache setAttachmentNamed:[url lastPathComponent]
                                                     withContentType:response.MIMEType
                                                             content:data];
                                }
                                else
                                    requestCache.responseData = data;
                                
                                requestCache.MIMEType = response.MIMEType;
                                requestCache.responseHeaders = ((NSHTTPURLResponse*)response).allHeaderFields;
                                requestCache.statusCode = [(NSHTTPURLResponse*)response statusCode];
                                requestCache.cbcacheCreationDate = [CBLJSON JSONObjectWithDate: [NSDate date]];
                                NSError * error;
                                if (self.cacheContext && ![self.cacheContext isEqualToString:@""]) {
                                    requestCache.channels = self.cacheContext;
                                }
                                
                                if(![requestCache save:&error]) NSLog(@"Error: %@", error.localizedDescription);
                                completionHandler(data, response, error);
                                
                            }];
                        }
                    }];
        
        return dataTask;
    }
    
    //Before forwarding to NSURLSession, check if we already have a cached response
    if(existingCache)
    {
        //NSLog(@"Found existing cache for URL : %@", url);
        NSHTTPURLResponse * httpUrlResponse = [[NSHTTPURLResponse alloc]
                                               initWithURL:url
                                               statusCode:existingCache.statusCode
                                               HTTPVersion:existingCache.httpVersion
                                               headerFields:existingCache.responseHeaders];
        
        if([NSURLSession isStoredAsAttachmentForMimeType:existingCache.MIMEType])
        {
            completionHandler([[existingCache attachmentNamed:[url lastPathComponent]] content], httpUrlResponse, nil);
        }
        else completionHandler(existingCache.responseData, httpUrlResponse, nil);
        
    }
    return nil;
}

-(NSURLSessionDataTask *)cbcache_dataTaskWithURL:(NSURL *)url
{
    return [self cbcache_dataTaskWithURL:url completionHandler:nil];
}

-(NSURLSessionDataTask *)cbcache_dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler
{
    return [self cbcache_dataTaskWithURL:[request URL] completionHandler:completionHandler];
}

-(NSURLSessionDataTask *)cbcache_dataTaskWithRequest:(NSURLRequest *)request
{
    return [self cbcache_dataTaskWithRequest:request completionHandler:nil];
}

/*Determine wether should store response as Attachment since binary data
 isn't stored efficiently in the NSData property of CBL Model*/
+(BOOL)isStoredAsAttachmentForMimeType:(NSString *) mimeType
{
    if ([mimeType containsString:@"image"] ||
        [mimeType containsString:@"video"] ||
        [mimeType containsString:@"audio"])
    {
        return FALSE; //TRUE; Disabled attachment for now (reason: not possible to modify/create attachments from shadow bucket)
    }
    return FALSE;
}

@end
