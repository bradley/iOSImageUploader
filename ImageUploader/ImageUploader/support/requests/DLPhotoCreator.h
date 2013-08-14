//
//  DLPhotoCreator.h
//  ImageUploader
//
//  Created by Bradley Griffith on 8/7/13.
//  Copyright (c) 2013 Bradley Griffith. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ProgressBlock)(CGFloat progress);
typedef void (^CompletionBlock)(BOOL success, NSError *error);

@class Photo;

@interface DLPhotoCreator : NSObject

- (void)savePhoto:(Photo *)photo withProgress:(ProgressBlock)progressBlock completion:(CompletionBlock)completionBlock;

@end
