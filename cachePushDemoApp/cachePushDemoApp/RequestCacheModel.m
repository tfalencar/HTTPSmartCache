//
//  RequestCacheModel.m
//  cachePushDemoApp
//
//  Created by Thiago Alencar on 2/4/15.
//  Copyright (c) 2015 Thiago Alencar. All rights reserved.
//

#import "RequestCacheModel.h"
#define kRequestCacheType @"requestCache"

@implementation RequestCacheModel
@dynamic MIMEType, responseData;
@dynamic responseHeaders, statusCode, httpVersion;
@dynamic channels, cbcacheCreationDate;

+(CBLQuery*)queryAllCacheFromDatabase:(CBLDatabase*)database
{
    CBLView* view = [database viewNamed: @"lists"];
    if (!view.mapBlock) {
        // Register the map function, the first time we access the view:
        [view setMapBlock: MAPBLOCK({
            if ([doc[@"type"] isEqualToString:kRequestCacheType])
                emit(doc[@"_id"], nil);
        }) reduceBlock: nil version: @"1"]; // bump version any time you change the MAPBLOCK body!
    }
    return [view createQuery];
}

- (instancetype) initInDatabase: (CBLDatabase*)database
                         withID: (NSString*)docID
{
    assert(database);
    //documentWithID: creates new one if no one was found.
    //This is a good way to assure uniqueness of documents
    CBLDocument* doc = [database documentWithID: docID];
    self = [RequestCacheModel modelForDocument:doc];
    
    self.type = [[self class] type];
    
    return self;
}

-(instancetype) initFromExistingDocumentInDatabase: (CBLDatabase*) database
                                            withID: (NSString*)docID
{
    assert(database);
    
    CBLDocument * doc = [database existingDocumentWithID:docID];
    
    if (doc) {
        self = [RequestCacheModel modelForDocument:doc];
        return self;
    }
    else return nil;
}

+(NSString*) type{
    return @"requestCache";
}

@end
