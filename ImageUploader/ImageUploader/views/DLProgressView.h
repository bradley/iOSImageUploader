//
//  DLProgressView.h
//  ImageUploader
//
//  Created by Bradley Griffith on 8/7/13.
//  Copyright (c) 2013 Bradley Griffith. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DLProgressView : UIView

+ (id)presentInWindow:(UIWindow *)window;

- (void)dismiss;
- (void)setProgress:(CGFloat)progress;

@end