//
//  UIImageView+CBCache.m
//
//  Created by Thiago Alencar on 2/12/15.
//  Copyright (c) 2015 Thiago Alencar. All rights reserved.
//

#import "UIImageView+CBCache.h"
#import "RequestCacheModel.h"
#import "NSURLSession+CBCache.h"
#import <objc/runtime.h>

@implementation UIImageView (CBCache)

+ (NSURLSession *)cbcache_sharedNSURLSession {
    static NSURLSession *cbcache_sharedNSURLSession = nil;
    static dispatch_once_t cbcache_onceToken;
    dispatch_once(&cbcache_onceToken, ^{
        //for cbcache requests caching
        NSURLSessionConfiguration * configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.URLCache = [NSURLCache sharedURLCache];
        //cachePolicy: follow http protocol for recording
        configuration.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
        cbcache_sharedNSURLSession = [NSURLSession sessionWithConfiguration:configuration];
    });
    
    return cbcache_sharedNSURLSession;
}

+ (NSURLSession *)httpOnly_sharedNSURLSession {
    static NSURLSession *httpOnly_sharedNSURLSession = nil;
    static dispatch_once_t http_onceToken;
    dispatch_once(&http_onceToken, ^{
        //for http-based caching
        NSURLSessionConfiguration * configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.URLCache = [NSURLCache sharedURLCache];
        //cachePolicy: always use http-cached data (NSURLRequestReturnCacheDataElseLoad)
        configuration.requestCachePolicy = NSURLRequestReturnCacheDataElseLoad;
        httpOnly_sharedNSURLSession = [NSURLSession sessionWithConfiguration:configuration];
    });
    
    return httpOnly_sharedNSURLSession;
}

- (void)setCurrentURL:(NSString *)newCurrentURL
{
    objc_setAssociatedObject(self, @selector(currentURL), newCurrentURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)currentURL {
    return objc_getAssociatedObject(self, @selector(currentURL));
}

- (void)setDatabaseObject:(id)newAssociatedObject {
    objc_setAssociatedObject(self, @selector(databaseObject), newAssociatedObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)databaseObject {
    return objc_getAssociatedObject(self, @selector(databaseObject));
}

-(void)cbcache_setImageWithURL:(NSURL *)url placeHolderImage: (UIImage *)placeHolderImage
{
    [self cbcache_setImageWithURL:url placeHolderImage:placeHolderImage success:nil failure:nil];
}

-(void)cbcache_setImageWithURL:(NSURL *)url
              placeHolderImage: (UIImage *)placeHolderImage
                       success:(void (^) (UIImage * image))success
                       failure:(void (^) (NSError * error))failure
{
    self.currentURL = [url absoluteString];
    
    [self setImage:placeHolderImage];
    [self setNeedsLayout];
    
    __weak UIImageView * weakSelf = self;
    
    //fetch the image
    //here isMainThread
    
    NSURLSession * mySession = [[self class] cbcache_sharedNSURLSession];
    assert(self.databaseObject);
    [mySession setDatabaseObject:self.databaseObject];
    
    NSURLSessionDataTask *dataTask;
    
    dataTask = [mySession cbcache_dataTaskWithURL:url
                                completionHandler:^(NSData * data, NSURLResponse * response, NSError * responseError) {
                                    //this scope is not at main thread
                                    
                                    NSError * mimeError = [self imageTestFailsForMIMEType:[response MIMEType] fromURL:[url absoluteString]];
                                    
                                    if (responseError)
                                    {
                                        NSLog(@"responseError: %@", responseError);
                                        if(failure) failure(responseError);
                                        
                                    }
                                    else if(mimeError)
                                    {
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            {
                                                if(failure)
                                                {
                                                    if([self.currentURL isEqualToString:[url absoluteString]])
                                                        failure(mimeError);
                                                }
                                                else
                                                {
                                                    if(weakSelf && [self.currentURL isEqualToString:[url absoluteString]]) //test if update is still valid for this cell
                                                    {
                                                        //implement default action for load failure here
                                                        //an example would be creating an empty image or
                                                        //using an error place holder image
                                                        //__strong __typeof(weakSelf)strongSelf = weakSelf;
                                                        //strongSelf = image;
                                                    }
                                                }
                                            }
                                        });
                                    }
                                    else
                                    {
                                        //NSLog(@"Success: Data fetched.");
                                        UIImage * theImage = [[UIImage alloc] initWithData:data];
                                        
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            {
                                                if(success)
                                                {
                                                    //test if update is still valid for this cell
                                                    if([self.currentURL isEqualToString:[url absoluteString]])
                                                        success(theImage);
                                                }
                                                else
                                                {
                                                    if(weakSelf)
                                                    {
                                                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                                                        //test if update is still valid for this cell
                                                        if([self.currentURL isEqualToString:[url absoluteString]])
                                                            strongSelf.image = theImage;
                                                    }
                                                }
                                            }
                                        });
                                        
                                    }
                                }];
    if(dataTask)
        [dataTask resume];
}

-(void)setImageWithURL:(NSURL *)url
      placeHolderImage: (UIImage *)placeHolderImage
{
    [self setImageWithURL:url placeHolderImage:placeHolderImage success:nil failure:nil];
}

-(void)setImageWithURL:(NSURL *)url
      placeHolderImage: (UIImage *)placeHolderImage
               success:(void (^) (UIImage * image))success
               failure:(void (^) (NSError * error))failure
{
    self.currentURL = [url absoluteString];
    
    [self setImage:placeHolderImage];
    [self setNeedsLayout];
    
    __block __weak UIImageView * weakSelf = self;
    
    //fetch the image
    //here is main thread
    
    NSURLSession * mySession = [[self class] httpOnly_sharedNSURLSession];
    [mySession setDatabaseObject:self.databaseObject];
    
    NSURLSessionDataTask *dataTask;
    
    dataTask = [mySession dataTaskWithURL:url
                        completionHandler:^(NSData * data, NSURLResponse * response, NSError * responseError) {
                            //this scope is not at main thread
                            
                            NSError * mimeError = [self imageTestFailsForMIMEType:[response MIMEType] fromURL:[url absoluteString]];
                            
                            if (responseError)
                            {
                                NSLog(@"responseError: %@", responseError);
                                if(failure) failure(responseError);
                                
                            }
                            else if(mimeError)
                            {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    {
                                        if(failure)
                                        {
                                            if([self.currentURL isEqualToString:[url absoluteString]])
                                                failure(mimeError);
                                        }
                                        else
                                        {
                                            if(weakSelf && [self.currentURL isEqualToString:[url absoluteString]]) //test if update is still valid for this cell
                                            {
                                                //implement default action for load failure here
                                                //an example would be creating an empty image or
                                                //using an error place holder image
                                                //__strong __typeof(weakSelf)strongSelf = weakSelf;
                                                //strongSelf = image;
                                            }
                                        }
                                    }
                                });
                            }
                            else
                            {
                                //NSLog(@"Success: Data fetched.");
                                UIImage * theImage = [[UIImage alloc] initWithData:data];
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    {
                                        if(success)
                                        {
                                            //test if update is still valid for this cell
                                            if([self.currentURL isEqualToString:[url absoluteString]])
                                                success(theImage);
                                        }
                                        else
                                        {
                                            if(weakSelf)
                                            {
                                                __strong __typeof(weakSelf)strongSelf = weakSelf;
                                                //test if update is still valid for this cell
                                                if([self.currentURL isEqualToString:[url absoluteString]])
                                                    strongSelf.image = theImage;
                                            }
                                        }
                                    }
                                });
                            }
                        }];
    if(dataTask)
        [dataTask resume];
}

-(NSError*)imageTestFailsForMIMEType:(NSString*) mimeType fromURL:(NSString*)theURL
{
    NSSet * acceptableContentTypes = [[NSSet alloc] initWithObjects:@"image/jpeg", @"image/png", nil];
    
    if(![acceptableContentTypes containsObject:mimeType])
    {
        //NSLog(@"Warning: Currently unsupported image format");
        NSMutableDictionary *mutableUserInfo = [@{
                                                  NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Request failed: unsupported content-type '%@' for %@", mimeType, theURL],
                                                  NSURLErrorFailingURLErrorKey:theURL,
                                                  @"cbcache.imageDecodingError": theURL,
                                                  } mutableCopy];
        
        NSError * error = [NSError errorWithDomain:@"cbcache.imageDecodingError"
                                              code:NSURLErrorCannotDecodeContentData
                                          userInfo:mutableUserInfo];
        return error;
    }
    
    return nil;
}

@end
