//
//  DLMenuViewController.m
//  ImageUploader
//
//  Created by Bradley Griffith on 7/31/13.
//  Copyright (c) 2013 Bradley Griffith. All rights reserved.
//

#import "DLMenuViewController.h"

@interface DLMenuViewController ()
@end

@implementation DLMenuViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    // Enable photo adding if camera is available.
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        _addPhotoButton.enabled = YES;
        [_addPhotoButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    }
}
- (IBAction)addPhoto:(id)sender {
    // You know.
}

@end
