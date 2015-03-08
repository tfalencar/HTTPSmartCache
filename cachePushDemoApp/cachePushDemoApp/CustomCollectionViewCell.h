//
//  CustomCollectionViewCell.h
//  cachePushDemoApp
//
//  Created by Thiago Alencar on 11/11/14.
//  Copyright (c) 2014 Thiago Alencar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

-(void)setImageOffsetForY:(CGFloat) yValue;
-(void)setImageOffsetForX:(CGFloat) xValue;

- (void)setImageOffset:(CGPoint)imageOffset;

@end
