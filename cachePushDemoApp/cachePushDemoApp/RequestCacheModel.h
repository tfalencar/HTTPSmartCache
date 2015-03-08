//
//  RequestCacheModel.h
//  cachePushDemoApp
//
//  Created by Thiago Alencar on 2/4/15.
//  Copyright (c) 2015 Thiago Alencar. All rights reserved.
//

#import <CouchbaseLite/CouchbaseLite.h>

@interface RequestCacheModel : CBLModel

//Document ID holds URL
@property (strong) NSString* MIMEType;
//remembert to base64 response when generating this at server side
//or, change implementation to use e.g. Attachment instead of NSData
@property (strong) NSData* responseData;

//http-specific
@property (strong) NSDictionary * responseHeaders;
@property NSInteger statusCode;
@property (strong) NSString * httpVersion;
@property (strong) NSString * channels;
@property (strong) NSString * cbcacheCreationDate;

- (instancetype) initInDatabase: (CBLDatabase*)database
                         withID: (NSString*)docID;

-(instancetype) initFromExistingDocumentInDatabase: (CBLDatabase*) database withID: (NSString*)docID;

+(CBLQuery*)queryAllCacheFromDatabase:(CBLDatabase*)database;

+(NSString*) type;

@end
