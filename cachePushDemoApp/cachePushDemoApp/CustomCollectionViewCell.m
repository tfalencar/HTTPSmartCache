//
//  CustomCollectionViewCell.m
//  cachePushDemoApp
//
//  Created by Thiago Alencar on 11/11/14.
//  Copyright (c) 2014 Thiago Alencar. All rights reserved.
//

#import "CustomCollectionViewCell.h"

@implementation CustomCollectionViewCell


-(void)setImageOffsetForY:(CGFloat) yValue
{
    CGRect frame = _imageView.bounds;
    CGRect offsetFrame = CGRectOffset(frame, _imageView.frame.origin.x, yValue);
    _imageView.frame = offsetFrame;
}

-(void)setImageOffsetForX:(CGFloat) xValue
{
    CGRect frame = _imageView.bounds;
    CGRect offsetFrame = CGRectOffset(frame, xValue, _imageView.frame.origin.y);
    _imageView.frame = offsetFrame;
}

- (void)setImageOffset:(CGPoint)imageOffset
{
    // Grow image view
    CGRect frame = _imageView.bounds;
    CGRect offsetFrame = CGRectOffset(frame, imageOffset.x, imageOffset.y);
    _imageView.frame = offsetFrame;
}

@end
