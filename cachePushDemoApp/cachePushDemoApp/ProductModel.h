//
//  ProductModel.h
//  cachePushDemoApp
//
//  Created by Thiago Alencar on 11/7/14.
//  Copyright (c) 2014 Thiago Alencar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ProductModel : NSObject

@property (strong) NSString * name;
@property (strong) NSString * price;
@property (strong) NSString * brand;
@property (strong) NSArray * imagesURLs; //NSString objects

@end
