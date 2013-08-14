//
//  DLCameraController.h
//  ImageUploader
//
//  Created by Bradley Griffith on 8/7/13.
//  Copyright (c) 2013 Bradley Griffith. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef void (^ImageCapturedBlock)(UIImage *image);
typedef void (^ImageCaptureFailureBlock)(NSString *errorMessage);

@interface DLCameraController : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate, UIGestureRecognizerDelegate>

- (id)initWithPreviewView:(UIView *)previewView;
- (void)setupCamera;
- (void)teardownCamera;
- (void)captureImage:(ImageCapturedBlock)success failure:(ImageCaptureFailureBlock)failure;

@end
