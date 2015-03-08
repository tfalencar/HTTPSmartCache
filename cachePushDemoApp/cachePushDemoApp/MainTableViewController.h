//
//  MainTableViewController.h
//  cachePushDemoApp
//
//  Created by Thiago Alencar on 11/7/14.
//  Copyright (c) 2014 Thiago Alencar. All rights reserved.
//

@class CBLDatabase;

#import <UIKit/UIKit.h>
#import "ProductModel.h"
#import "ProductTableViewCell.h"
#import "PickerViewController.h"
#import "NSURLSession+CBCache.h"

typedef enum {kPopularity, kName, kPrice, kBrand} sortTypeEnum;
typedef enum {kASC, kDESC} orderingTypeEnum;

@interface MainTableViewController : UITableViewController<UIPickerViewDataSource, UIPickerViewDelegate, UIPopoverPresentationControllerDelegate>
{
    int numberOfResults;
    int pageLoadedCount;
    BOOL jsonLoaded;
    BOOL requestInProgress;
    PickerViewController * filterPickerViewController;
    CBLDatabase * database;
    NSString * currentContext;
}

- (IBAction)filterButtonTouched:(id)sender;

//@property (nonatomic) NSMutableArray * jsonString;
@property (nonatomic, retain) NSMutableString * currentRequestURL;

@property (nonatomic, retain) NSMutableArray * productsList; //contains ProductModel objects

@property (nonatomic, retain) NSDictionary * sortApiStrings;
@property (nonatomic, retain) NSDictionary * orderApiStrings;

@property (nonatomic, assign) sortTypeEnum sortTypeSelection;
@property (nonatomic, assign) orderingTypeEnum orderTypeSelection;


@end
