//
//  MainTableViewController.m
//  cachePushDemoApp
//
//  Created by Thiago Alencar on 11/7/14.
//  Copyright (c) 2014 Thiago Alencar. All rights reserved.
//

#import "MainTableViewController.h"
#import "AppDelegate.h"
#import "CBLSyncManager.h"

#import <CommonCrypto/CommonDigest.h>

#define kServerURL @"http://ti.eng.br:8586/api/v1.0/?"

#define IMAGE_HEIGHT 218
#define IMAGE_OFFSET_SPEED 15

#define MAX_LOAD_ITEMS_PER_REQUEST @"5"

@implementation MainTableViewController

@synthesize productsList, currentRequestURL;
@synthesize sortTypeSelection, orderTypeSelection, sortApiStrings, orderApiStrings;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    database = appDelegate.database;
    
    if(!productsList)
        productsList = [[NSMutableArray alloc] init];
    
    //defaults
    sortTypeSelection = kPopularity;
    orderTypeSelection = kDESC;
    
    sortApiStrings = [[NSDictionary alloc] initWithObjectsAndKeys:
                      @"popularity", [NSNumber numberWithUnsignedInteger: kPopularity],
                      @"name", [NSNumber numberWithUnsignedInteger: kName],
                      @"price", [NSNumber numberWithUnsignedInteger: kPrice],
                      @"brand", [NSNumber numberWithUnsignedInteger: kBrand],
                      nil];
    
    orderApiStrings = [[NSDictionary alloc] initWithObjectsAndKeys:
                       @"asc", [NSNumber numberWithUnsignedInteger: kASC],
                       @"desc", [NSNumber numberWithUnsignedInteger: kDESC], nil];
    
    NSString * sortString = [sortApiStrings objectForKey:
                             [NSNumber numberWithUnsignedInteger: sortTypeSelection]];
    NSString * ascDescString = [orderApiStrings objectForKey:
                                [NSNumber numberWithUnsignedInteger: orderTypeSelection]];
    
    currentRequestURL = [NSMutableString stringWithFormat:@"%@maxitems=%@&sort=%@&dir=%@",kServerURL,
                         MAX_LOAD_ITEMS_PER_REQUEST, sortString, ascDescString];
    
    pageLoadedCount = 1;
    
    [self requestDataToServer];
    
    [self.tableView setEstimatedRowHeight:286];
    [self.tableView setRowHeight:UITableViewAutomaticDimension];
    
}

-(void)requestDataToServer
{
    if (requestInProgress) return;
    
    requestInProgress = TRUE;
    
    NSString * completeURL = [NSString stringWithFormat:@"%@&page=%i",currentRequestURL, pageLoadedCount];
    NSLog(@"requestString: %@", completeURL);
    
    //generate a unique identifier for this page/request > context
    //currentContext = [MainTableViewController md5:currentRequestURL];
    //reload/update context
    //[[CBLSyncManager sharedCBLSyncManager] setCurrentContext:currentContext];
    //disabled context as its deactivated in the server
    
    NSURL *requestURL = [NSURL URLWithString:completeURL];
    
    NSLog(@"Starting download..");
    
    NSURLSessionConfiguration * configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.URLCache = [NSURLCache sharedURLCache];
    //adjust cachePolicy according to your needs (carefully)
    //since in the demo we have control and keep data for these requests updated,
    //we can safely use NSURLRequestReturnCacheDataElseLoad here
    configuration.requestCachePolicy = NSURLRequestReturnCacheDataElseLoad;
    
    NSURLSession * mySession = [NSURLSession sessionWithConfiguration:configuration];
    
    [mySession setDatabaseObject: database];
    //cbcache will do its work with NO in the method below.
    //otherwise it depends on the response headers from the server
    [mySession setComplyToHttpHeaders:NO];
    [mySession setCacheContext:@"main_menu"];
    
    NSDate *previousTime = [NSDate date];
    
    NSURLSessionDataTask *dataTask = [mySession dataTaskWithURL:requestURL completionHandler:
                                      ^(NSData *data, NSURLResponse *response, NSError *error)
                                      {
                                          //this scope is not at main thread
                                          if (error) {
                                              NSLog(@"Implement error handling: %@", error);
                                              requestInProgress = FALSE;
                                          } else {
                                              
                                              jsonLoaded = TRUE;
                                              
                                              NSDate *currentTime = [NSDate date];
                                              NSTimeInterval timeDifference =  [currentTime timeIntervalSinceDate:previousTime];
                                              
                                              NSLog(@"Response came in %f", timeDifference);
                                              
                                              //NSLog(@"DiskCache: %@ of %@", @([[NSURLCache sharedURLCache] currentDiskUsage]), @([[NSURLCache sharedURLCache] diskCapacity]));
                                              //NSLog(@"MemoryCache: %@ of %@", @([[NSURLCache sharedURLCache] currentMemoryUsage]), @([[NSURLCache sharedURLCache] memoryCapacity]));
                                              
                                              [self parseJSONwithData:data];
                                          }
                                      }];
    if(dataTask)
        [dataTask resume];
    
    NSLog(@"DiskCache: %@ of %@", @([[NSURLCache sharedURLCache] currentDiskUsage]), @([[NSURLCache sharedURLCache] diskCapacity]));
    NSLog(@"MemoryCache: %@ of %@", @([[NSURLCache sharedURLCache] currentMemoryUsage]), @([[NSURLCache sharedURLCache] memoryCapacity]));

}

-(void)parseJSONwithData:(NSData *)data
{
    //create products list
    
    NSError * error;
    
    NSDictionary * jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if (error)
    {
        NSLog(@"JSONObjectWithData error: %@", error);
        return;
    }
    
    if([jsonDictionary isKindOfClass:[NSDictionary class]]){
        
        NSDictionary * metadata = jsonDictionary[@"metadata"];
        
        NSLog(@"Product count: %@", metadata[@"product_count"]);
        
        NSDictionary * results = metadata[@"results"];
        
        NSLog(@"Number of results from query: %lu", (unsigned long)[results count]);
        
        NSMutableArray * loadedProductsArray = [[NSMutableArray alloc] init];
        
        //iterate results
        
        for(NSDictionary * component in results)
        {
            NSArray * imagesURLs = component[@"images"];
            //NSLog(@"images: %@", imagesURLs);
            
            NSDictionary * dataDictionary = component[@"data"];
            
            //NSLog(@"Name: %@", dataDictionary[@"name"]);
            //NSLog(@"Brand: %@", dataDictionary[@"brand"]);
            //NSLog(@"Price: %@", dataDictionary[@"price"]);
            
            ProductModel * loadedProduct = [[ProductModel alloc] init];
            
            loadedProduct.name = dataDictionary[@"name"];
            loadedProduct.price = dataDictionary[@"price"];
            loadedProduct.brand = dataDictionary[@"brand"];
            loadedProduct.imagesURLs = imagesURLs;
            
            [loadedProductsArray addObject:loadedProduct];
        }
        
        pageLoadedCount++;
        
        [self insertDownloadedItems:loadedProductsArray];
    }
    else
    {
        NSLog(@"Aborting.");
        return;
    }
}

-(void)insertDownloadedItems: (NSMutableArray *) dataToAdd
{
    //go back to UI thread now
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        
        // build the index paths for insertion
        NSMutableArray *indexPaths = [NSMutableArray array];
        NSInteger currentCount = productsList.count;
        for (int i = 0; i < dataToAdd.count; i++) {
            [indexPaths addObject:[NSIndexPath indexPathForRow:currentCount+i inSection:0]];
        }
        
        // insert to data source
        [productsList addObjectsFromArray:dataToAdd];
        
        // uptable table view
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
        
        requestInProgress = FALSE;
        
        //set initial parallax position
        [self scrollViewDidScroll:nil];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)filterButtonTouched:(id)sender
{
    UIStoryboard *storyboard = self.storyboard;
    filterPickerViewController = [storyboard instantiateViewControllerWithIdentifier:@"filterView"];
    
    //if a navigation controller / bar is desired:
    //filterPickerViewController.pickerView = pickerView;
    //UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:filterPickerViewController];
    
    filterPickerViewController.modalPresentationStyle = UIModalPresentationPopover;
    filterPickerViewController.popoverPresentationController.delegate = self;
    
    //also for navBar, do instead: UIPopoverPresentationController * popPC = navController.popoverPresentationController;
    UIPopoverPresentationController * popPC = filterPickerViewController.popoverPresentationController;
    
    //the barButton is used to indicate the origin / arrow of the pop over
    UIBarButtonItem * theButton = sender;
    popPC.barButtonItem = theButton;
    popPC.delegate = self;
    popPC.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    // filterPickerView.popoverPresentationController.barButtonItem = sender;
    //popPC.barButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"test" style:UIBarButtonItemStyleDone target:nil action:nil];
    
    [self presentViewController:filterPickerViewController animated:YES completion:
     ^{
         //pickerView is actually nil until presented, so we configure it here
         filterPickerViewController.pickerView.delegate = self;
         filterPickerViewController.pickerView.dataSource = self;
         [filterPickerViewController.pickerView reloadAllComponents];
         [filterPickerViewController.pickerView selectRow:sortTypeSelection inComponent:0 animated:NO];
         [filterPickerViewController.pickerView selectRow:orderTypeSelection inComponent:1 animated:NO];
     }];
    
}

//-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {}

-(void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    //NSLog(@"MainTableViewController.m: willTransitionToTrait: %@", newCollection);
}

-(UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    //important: implement this so that our popover actually looks like a popover as well in the iPhone
    return UIModalPresentationNone;
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    NSLog(@"MainTableViewController.m  : viewWillTransitionToSize: w: %f h :%f", size.width, size.height);
}

#pragma mark - Picker View
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerVieww
{
    return 2;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (component == 0) return 4; //sort types
    else return 2; //ordering (asc,desc)
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if(component == 0)
    {
        switch (row) {
            case kPrice:
                sortTypeSelection = kPrice;
                break;
            case kPopularity:
                sortTypeSelection = kPopularity;
                break;
            case kName:
                sortTypeSelection = kName;
                break;
            case kBrand:
                sortTypeSelection = kBrand;
                break;
            default:
                break;
        }
    }
    else if (component == 1) {
        orderTypeSelection = (int)row;
    }
    
    //clean-up
    jsonLoaded = false;
    numberOfResults = 0;
    pageLoadedCount = 1;
    
    [productsList removeAllObjects];
    [self.tableView reloadData];
    
    NSString * sortString = [sortApiStrings objectForKey:
                             [NSNumber numberWithUnsignedInteger: sortTypeSelection]];
    NSString * ascDescString = [orderApiStrings objectForKey:
                                [NSNumber numberWithUnsignedInteger: orderTypeSelection]];
    
    currentRequestURL = [NSMutableString stringWithFormat:@"%@maxitems=%@&sort=%@&dir=%@",kServerURL,
                         MAX_LOAD_ITEMS_PER_REQUEST, sortString, ascDescString];
    
    [self requestDataToServer];
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (component==0) {
        switch (row) {
            case kPrice:
                return NSLocalizedString(@"Price", @"");
                break;
            case kPopularity:
                return NSLocalizedString(@"Popularity", @"");
                break;
            case kName:
                return NSLocalizedString(@"Name", @"");
                break;
            case kBrand:
                return NSLocalizedString(@"Brand", @"");
                break;
            default:
                return @"Undefined";
                break;
        }
    }
    
    return row == kASC ? NSLocalizedString(@"Ascending",@"") : NSLocalizedString(@"Descending", @"");
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if(!jsonLoaded) return 1; //loading cell..
    else
    {
        //TODO: check whether we reached the end of the list (didn't find the information in the JSON response)
        int endOfList = 1;
        
        return [productsList count] + endOfList;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(!jsonLoaded && indexPath.row == 0)
    {
        return [tableView dequeueReusableCellWithIdentifier:@"loadingCell" forIndexPath:indexPath];
        //UI note regarding loadingCell:
        //from my experiments, it should to be the same height as the height provided
        //to tableView's estimatedRowHeight, otherwise there will be a miscalculation
        //during the animated's row insertion which causes a distracting glicth where
        //the user looses notion of the tableView's last position.
        //See for yourself by removing the loadinCells's label's top/bottom's space
        //distance to superview constraint.
    }
    
    if(jsonLoaded && indexPath.row == [productsList count])
    {
        //load more data..
        //TODO: Check if already at last item (missing server REST API doc)
        NSLog(@"End of table reached.....");
        [self requestDataToServer];
        return [tableView dequeueReusableCellWithIdentifier:@"loadingCell" forIndexPath:indexPath];
    }
    
    //display already loaded data
    ProductTableViewCell *productCell = [tableView dequeueReusableCellWithIdentifier:@"productCell" forIndexPath:indexPath];
    
    //set context
    [productCell setCellContext:currentContext];
    
    //set initial parallax
    [productCell scrollViewDidScroll:nil];
    
    ProductModel * currentProduct = [productsList objectAtIndex:indexPath.row];
    [productCell setCblDatabase:database];
    [productCell.imagesCollectionView setContentOffset:CGPointZero animated:NO];

    [productCell configureCellForProduct:currentProduct];
    
    //set initial parallax
    [self scrollViewDidScroll:nil];
    

    
    return productCell;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    for(ProductTableViewCell *productTableCell in self.tableView.visibleCells)
    {
        if(![productTableCell isKindOfClass: [ProductTableViewCell class]]) return;
        
        CGFloat yOffset = ((self.tableView.contentOffset.y - productTableCell.frame.origin.y) / IMAGE_HEIGHT) * IMAGE_OFFSET_SPEED;
        [productTableCell setImageOffsetForY: yOffset];
    }
}

#pragma mark - Utilities

+ (NSString *) md5:(NSString *) input
{
    const char *cStr = [input UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, (unsigned int)strlen(cStr), digest ); // This is the md5 call
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    return  output;
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
