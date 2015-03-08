//
//  UIImageView+CBCache.h
//
//  Created by Thiago Alencar on 2/12/15.
//  Copyright (c) 2015 Thiago Alencar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CouchbaseLite/CouchbaseLite.h>

/*
 A very simple image loading category to demonstrate
 caching with Couchbase Mobile and NSURLSession+CBCache.h
 
 Performance Note:
 I compared the performance of this class versus other libraries such as
 SDWebImage and AFNetwork+UIImageCache (few and small-sized image) and the 
 difference were so minimal that I believe integrating one of those in conjunction
 with the caching described here is not worth it (I believe the performance was similar
 because in the end we're just loading data from the flash memory anyway.
 If you really need faster framerates I'd suggest then to use a memory mapped 
 library such as Path's Fast Image Cache (instead of AFNetwork+UIImageCache or SDWebImage).
 The reason is that NSURLCache caches responses, not the result of parsing them. 
 For intensive decoding tasks it might be best to cache the parsed objects in a custom cache 
 instead of relying on e.g. NSURLCache to simply store the raw response.
 
 This class is much simpler than AFNetworking because we don't need for example
 NSOperationQueues since the images should be loaded fast enough from local cached
 data. The point of NSOperationQueue in AFNetworking is to be able to prioritize 
 one request versus another (by pausing or canceling requests which went ouf of scope)
 Since loading local data is fast, using GCD and leaving all networking with NSURLSession
 seems enough when using the techniques presented here. However, it all always depends on
 your application's needs.
 */

//TODO: Benchmark speed of NSURLCache-based vs CBLCache-based data retrieval
 
@interface UIImageView (CBCache)

@property (nonatomic, weak) CBLDatabase * databaseObject;
@property (atomic, weak) NSString * currentURL;

/*methods with cbcache_ initial stores and retrieve data using
 Couchbase Lite; May be used to generate the cache documents*/
-(void)cbcache_setImageWithURL:(NSURL *)url placeHolderImage: (UIImage *)placeHolderImage;

/*implement custom completion blocks*/
-(void)cbcache_setImageWithURL:(NSURL *)url
              placeHolderImage: (UIImage *)placeHolderImage
                       success:(void (^) (UIImage * image))success
                       failure:(void (^) (NSError * error))failure;

/*methods below provides basic image lazy loading enforcing use
 of stored [NSURLCache sharedURLCache] data. It does NOT directly
 use the CBL cache documents. We inject cache data from the CBL documents
 into NSURLCache first. This is to levarege the caching memory management from
 NSURLCache without reimplementing such memory management system on our own.*/
-(void)setImageWithURL:(NSURL *)url
      placeHolderImage: (UIImage *)placeHolderImage;

-(void)setImageWithURL:(NSURL *)url
       placeHolderImage: (UIImage *)placeHolderImage
                success:(void (^) (UIImage * image))success
                failure:(void (^) (NSError * error))failure;
@end
