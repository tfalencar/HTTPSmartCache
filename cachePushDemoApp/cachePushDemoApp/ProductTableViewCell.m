//
//  ProductTableViewCell.m
//  cachePushDemoApp
//
//  Created by Thiago Alencar on 11/7/14.
//  Copyright (c) 2014 Thiago Alencar. All rights reserved.
//

#import "ProductTableViewCell.h"
#import "CustomCollectionViewCell.h"
#import "RequestCacheModel.h"

//added CBLSyncManager and RequestCacheModel to get live changes
#import "CBLSyncManager.h"
#import "RequestCacheModel.h"

#define IMAGE_HEIGHT 218
#define IMAGE_WIDTH 150
#define IMAGE_OFFSET_SPEED 10

@implementation ProductTableViewCell
@synthesize cblDatabase, tableOffsetY;
@synthesize cellContext;

- (void)awakeFromNib {
    // Initialization code
    NSLog(@"cell's initialization code..");
    
    _imagesCollectionView.delegate = self;
    _imagesCollectionView.dataSource = self;
    
    //configure observer so that cache image changes are reflected immediatelly
    [[CBLSyncManager sharedCBLSyncManager] addCacheChangesObserver:self
                                                          selector:@selector(databaseChanged_:)
                                                              name:kCBLDatabaseChangeNotification];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

#pragma mark Collection View delegates

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CustomCollectionViewCell * customCell;
    
    customCell = [_imagesCollectionView dequeueReusableCellWithReuseIdentifier:@"imageCellCollection" forIndexPath:indexPath];
    
    NSDictionary * imageDataArray = [_currentProduct.imagesURLs objectAtIndex:indexPath.row];
    
    assert(cblDatabase);
    
    [customCell.imageView setDatabaseObject: cblDatabase];
    
    [customCell.imageView setImageWithURL: [NSURL URLWithString:imageDataArray[@"path"]]
                                 placeHolderImage: [UIImage imageNamed:@"placeholder.png"]
//                                      withContext: cellContext
                                          success: ^(UIImage *image) {
                                              //using completion block to make custom transition effect
                                              [UIView transitionWithView:customCell.imageView
                                                                duration:0.2
                                                                 options:UIViewAnimationOptionTransitionCrossDissolve
                                                              animations:^{
                                                                  customCell.imageView.image = image;
                                                              }
                                                              completion:NULL];
                                              
                                          } failure:^(NSError *error) {
                                              NSLog(@"Fetch image error: %@; Displaying gray image", error.localizedDescription);
                                              CGSize imageSize = CGSizeMake(64, 64);
                                              UIColor *fillColor = [UIColor grayColor];
                                              UIGraphicsBeginImageContextWithOptions(imageSize, YES, 0);
                                              CGContextRef context = UIGraphicsGetCurrentContext();
                                              [fillColor setFill];
                                              CGContextFillRect(context, CGRectMake(0, 0, imageSize.width, imageSize.height));
                                              UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
                                              UIGraphicsEndImageContext();
                                              customCell.imageView.image = image;
                                          }];
    
    
    customCell.imageView.clipsToBounds = YES;
    
    //configure initial parallax
    [self scrollViewDidScroll:nil];
    
    return customCell;
}

-(void)configureCellForProduct:(ProductModel *) product
{
    _currentProduct = product;
    
    [_nameLabel setText:product.name];
    [_priceLabel setText:product.price];
    [_brandLabel setText:product.brand];
    
    [_imagesCollectionView reloadData];
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [_currentProduct.imagesURLs count];
}

#pragma mark Image changes handler

-(void)databaseChanged_: (NSNotification*) dbNotification
{
    CBLDatabase * database = [[CBLSyncManager sharedCBLSyncManager] database];
    
    int docsChangedCounter = 0;
    
    for (CBLDatabaseChange* change in dbNotification.userInfo[@"changes"])
    {
        CBLDocument * changedDoc = [database documentWithID:change.documentID];
        
        NSString * type = changedDoc[@"type"];
        if(![type isEqualToString: [RequestCacheModel type]])
            return;
        
        docsChangedCounter++;
        RequestCacheModel * model = [RequestCacheModel modelForDocument: [database documentWithID:change.documentID]];
        
        if(![model.MIMEType containsString:@"image"]) //in this demo we just refresh images content
            return;
        
        NSArray *paths = [self.imagesCollectionView indexPathsForVisibleItems];
        
        for (NSIndexPath *path in paths) {
            //for each cell check if the image is currently show, if so reload it
            CustomCollectionViewCell * collectionCell = (CustomCollectionViewCell*)[self.imagesCollectionView cellForItemAtIndexPath:path];
            if([collectionCell.imageView.currentURL isEqualToString: change.documentID])
            {
                //found a match, request reload now.
                [collectionCell.imageView setImageWithURL: [NSURL URLWithString:change.documentID]
                                         placeHolderImage:nil
                                                  success:^(UIImage *image) {
                                                      //using completion block to make custom transition effect
                                                      [UIView transitionWithView:collectionCell.imageView
                                                                        duration:0.7 //use smoother transition for updates
                                                                         options:UIViewAnimationOptionTransitionCrossDissolve
                                                                      animations:^{
                                                                          collectionCell.imageView.image = image;
                                                                      }
                                                                      completion:NULL];
                                                      
                                                  } failure:^(NSError *error) {
                                                      NSLog(@"Fetch image error: %@; Display blue image", error.localizedDescription);
                                                      CGSize imageSize = CGSizeMake(64, 64);
                                                      UIColor *fillColor = [UIColor blueColor]; //blue to represent failure upon update
                                                      UIGraphicsBeginImageContextWithOptions(imageSize, YES, 0);
                                                      CGContextRef context = UIGraphicsGetCurrentContext();
                                                      [fillColor setFill];
                                                      CGContextFillRect(context, CGRectMake(0, 0, imageSize.width, imageSize.height));
                                                      UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
                                                      UIGraphicsEndImageContext();
                                                      collectionCell.imageView.image = image;
                                                  }];
            }
        }
        
        //NSLog(@"db changed with docID: %@", change.documentID);
        
    }
}

#pragma mark Parallax Effect
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    for(CustomCollectionViewCell *viewCell in _imagesCollectionView.visibleCells) {
        
        CGFloat xOffset = ((_imagesCollectionView.contentOffset.x - viewCell.frame.origin.x) / IMAGE_WIDTH) * IMAGE_OFFSET_SPEED;
        [viewCell setImageOffsetForX:xOffset];
        [viewCell setImageOffsetForY:tableOffsetY]; //use last known table offset
    }
}

-(void)setImageOffsetForY:(CGFloat)imageOffset
{
    tableOffsetY = imageOffset;
    
    for(CustomCollectionViewCell *viewCell in _imagesCollectionView.visibleCells) {
        [viewCell setImageOffsetForY:imageOffset];
    }
    [self scrollViewDidScroll:nil];
}

-(void)dealloc
{
    NSLog(@"cell being destroyed..");
    [[CBLSyncManager sharedCBLSyncManager] removeCacheChangesObserver:self];
}

@end
