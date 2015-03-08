//
//  AppDelegate.h
//  cachePushDemoApp
//
//  Created by Thiago Alencar on 11/7/14.
//  Copyright (c) 2014 Thiago Alencar. All rights reserved.
//

//@class CBLSyncManager;

#import <UIKit/UIKit.h>
#import <CouchbaseLite/CouchbaseLite.h>

@class CBLSyncManager;

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    CBLSyncManager * sharedSyncManager;
}

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) CBLDatabase *database;


@end

