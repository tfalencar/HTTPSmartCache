//
//  ProductTableViewCell.h
//  cachePushDemoApp
//
//  Created by Thiago Alencar on 11/7/14.
//  Copyright (c) 2014 Thiago Alencar. All rights reserved.
//

@class CBLDatabase;

#import <UIKit/UIKit.h>
#import "ProductModel.h"
#import "UIImageView+CBCache.h"

@interface ProductTableViewCell : UITableViewCell <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *brandLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *imagesCollectionView;

@property (weak, nonatomic) NSString * cellContext;

@property CGFloat tableOffsetY;

@property (weak, nonatomic) CBLDatabase * cblDatabase;

@property (weak, nonatomic) ProductModel * currentProduct;

-(void)configureCellForProduct:(ProductModel *)product;
-(void)setImageOffsetForY:(CGFloat)imageOffset;


@end
