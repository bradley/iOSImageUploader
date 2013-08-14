//
//  DLStillCameraViewController.m
//  ImageUploader
//
//  Created by Bradley Griffith on 8/1/13.
//  Copyright (c) 2013 Bradley Griffith. All rights reserved.
//

#import "DLStillCameraViewController.h"
#import "DLCameraController.h"
#import "DLProgressView.h"
#import "DLPhotoCreator.h"
#import "Photo.h"
#import "SVProgressHUD.h"

@interface DLStillCameraViewController ()
@property (nonatomic, strong)DLCameraController *cameraController;
@property (nonatomic, strong)UIImageView *imagePreview;
@property (nonatomic, strong)Photo *capturedPhoto;
@property (nonatomic, strong)DLPhotoCreator *photoCreator;
@end

@implementation DLStillCameraViewController

- (IBAction)captureImage:(id)sender {
    [_cameraController captureImage:^(UIImage *image) {
        _capturedPhoto = [[Photo alloc] init];
        _capturedPhoto.photoData = UIImagePNGRepresentation(image);
        
        _imagePreview = [[UIImageView alloc] initWithImage:image];
        [_previewView addSubview:_imagePreview];
        
        [self toggleCapturedWithState:YES];
        [_cameraController teardownCamera];
        
    } failure:^(NSString *errorMessage) {
        [_cameraController teardownCamera];
    }];
}

- (IBAction)retryCapture:(id)sender {
    [self toggleCapturedWithState:NO];
    [_cameraController setupCamera];
}

- (IBAction)useImage:(id)sender {
    DLProgressView *progressView = [DLProgressView presentInWindow:self.view.window];
    
    [_photoCreator savePhoto:_capturedPhoto withProgress:^(CGFloat progress) {
        [progressView setProgress:progress];
    } completion:^(BOOL success, NSError *error) {
        [progressView dismiss];
        if (success) {
            [self dismissCamera:nil];
        } else {
            NSLog(@"ERROR: %@", error);
            [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
        }
    }];
}

- (IBAction)dismissCamera:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)toggleCapturedWithState:(BOOL)captureState {
    if (captureState == YES) {
        _retryCaptureButton.hidden = NO;
        _useImageButton.hidden = NO;
        _captureImageButton.hidden = YES;
    }
    else {
        _retryCaptureButton.hidden = YES;
        _useImageButton.hidden = YES;
        _captureImageButton.hidden = NO;
        if (_imagePreview) {
            [_imagePreview removeFromSuperview];
            _imagePreview = nil;
        }
        if (_capturedPhoto) {
            _capturedPhoto = nil;
        }
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _cameraController = [[DLCameraController alloc] initWithPreviewView:_previewView];
    _photoCreator = [[DLPhotoCreator alloc] init];
    
    [self toggleCapturedWithState:NO];
    [_cameraController setupCamera];
}

@end
