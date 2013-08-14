//
//  DLStillCameraViewController.h
//  ImageUploader
//
//  Created by Bradley Griffith on 8/1/13.
//  Copyright (c) 2013 Bradley Griffith. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface DLStillCameraViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate, UIGestureRecognizerDelegate>

- (IBAction)dismissCamera:(id)sender;
- (IBAction)captureImage:(id)sender;
- (IBAction)retryCapture:(id)sender;
- (IBAction)useImage:(id)sender;

@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UIButton *captureImageButton;
@property (weak, nonatomic) IBOutlet UIButton *retryCaptureButton;
@property (weak, nonatomic) IBOutlet UIButton *useImageButton;

@end
