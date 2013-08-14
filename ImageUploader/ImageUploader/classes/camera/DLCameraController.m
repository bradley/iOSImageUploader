//
//  DLCameraController.m
//  ImageUploader
//
//  Created by Bradley Griffith on 8/7/13.
//  Copyright (c) 2013 Bradley Griffith. All rights reserved.
//

#import "DLCameraController.h"
#import "DLRingCreator.h"
#import "UIImage+Resize.h"
#import "BlocksKit.h"
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>

@interface DLCameraController()
@property (nonatomic, strong)UIView *previewView;
@property (nonatomic, strong)AVCaptureSession *session;
@property (nonatomic, strong)AVCaptureDevice *device;
@property (nonatomic, strong)AVCaptureDeviceInput *input;
@property (nonatomic, strong)AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong)AVCaptureVideoDataOutput *videoDataOutput;
@property dispatch_queue_t videoDataOutputQueue;
@property (nonatomic, strong)AVCaptureVideoPreviewLayer *previewLayer;
@property CGFloat effectiveScale;
@property (nonatomic, strong)UIView *flashView;
@property (nonatomic, strong)DLRingCreator *ringCreator;
@end

@implementation DLCameraController

- (void)setupCamera {
    // Create session.
	_session = [AVCaptureSession new];
    // TODO: Medium quality is suitable for wifi sharing. If we dont need this, go ahead and set to high.
    _session.sessionPreset = AVCaptureSessionPresetMedium;
    
    // Find suitable device
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // Create and add a device input
    // TODO: Update to handle error appropriately.
    NSError *error = nil;
    _input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&error];
    
    if ([_session canAddInput:_input]) {
		[_session addInput:_input];
    }
    
    // Make a still image output
	_stillImageOutput = [AVCaptureStillImageOutput new];
    [_stillImageOutput addObserver:self
                        forKeyPath:@"capturingStillImage"
                           options:NSKeyValueObservingOptionNew
                           context:@"AVCaptureStillImageIsCapturingStillImageContext"];
	if ([_session canAddOutput:_stillImageOutput]) {
		[_session addOutput:_stillImageOutput];
    }
    
    // Make a video data output
	_videoDataOutput = [AVCaptureVideoDataOutput new];
	
    // we want BGRA, both CoreGraphics and OpenGL work well with 'BGRA'
	NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
									   [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
	[_videoDataOutput setVideoSettings:rgbOutputSettings];
	[_videoDataOutput setAlwaysDiscardsLateVideoFrames:YES]; // discard if the data output queue is blocked (as we process the still image)
    
    // create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured
    // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
    // see the header doc for setSampleBufferDelegate:queue: for more information
	_videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
	[_videoDataOutput setSampleBufferDelegate:self queue:_videoDataOutputQueue];
    
    if ( [_session canAddOutput:_videoDataOutput] ) {
		[_session addOutput:_videoDataOutput];
    }
	[[_videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:NO];
    
    _effectiveScale = 1.0;
	_previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
	[_previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
	[_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
	CALayer *rootLayer = [_previewView layer];
	[rootLayer setMasksToBounds:NO];
	[_previewLayer setFrame:[rootLayer bounds]];
	[rootLayer addSublayer:_previewLayer];
    
    // Add a single tap gesture to focus on the point tapped, then lock focus
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToAutoFocus:)];
    [singleTap setDelegate:self];
    [singleTap setNumberOfTapsRequired:1];
    [_previewView addGestureRecognizer:singleTap];
    
    // Add a double tap gesture to focus on the point tapped, then lock focus and exposure
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToAutoFocusAndExpose:)];
    [doubleTap setDelegate:self];
    [doubleTap setNumberOfTapsRequired:2];
    [_previewView addGestureRecognizer:doubleTap];
    
    // Start the session. This is done asychronously since -startRunning doesn't return until the session is running.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_session startRunning];
    });
}

// Convert from view coordinates to camera coordinates, where {0,0} represents the top left of the picture area, and {1,1} represents
// the bottom right in landscape mode with the home button on the right.
- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates
{
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize = _previewView.frame.size;
    
    if ([_previewLayer.connection isVideoMirrored]) {
        viewCoordinates.x = frameSize.width - viewCoordinates.x;
    }
    
    if ( [[_previewLayer videoGravity] isEqualToString:AVLayerVideoGravityResize] ) {
		// Scale, switch x and y, and reverse x
        pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.f - (viewCoordinates.x / frameSize.width));
    } else {
        CGRect cleanAperture;
        for (AVCaptureInputPort *port in [_input ports]) {
            if ([port mediaType] == AVMediaTypeVideo) {
                cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
                CGSize apertureSize = cleanAperture.size;
                CGPoint point = viewCoordinates;
                
                CGFloat apertureRatio = apertureSize.height / apertureSize.width;
                CGFloat viewRatio = frameSize.width / frameSize.height;
                CGFloat xc = .5f;
                CGFloat yc = .5f;
                
                if ( [[_previewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspect] ) {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = frameSize.height;
                        CGFloat x2 = frameSize.height * apertureRatio;
                        CGFloat x1 = frameSize.width;
                        CGFloat blackBar = (x1 - x2) / 2;
						// If point is inside letterboxed area, do coordinate conversion; otherwise, don't change the default value returned (.5,.5)
                        if (point.x >= blackBar && point.x <= blackBar + x2) {
							// Scale (accounting for the letterboxing on the left and right of the video preview), switch x and y, and reverse x
                            xc = point.y / y2;
                            yc = 1.f - ((point.x - blackBar) / x2);
                        }
                    } else {
                        CGFloat y2 = frameSize.width / apertureRatio;
                        CGFloat y1 = frameSize.height;
                        CGFloat x2 = frameSize.width;
                        CGFloat blackBar = (y1 - y2) / 2;
						// If point is inside letterboxed area, do coordinate conversion. Otherwise, don't change the default value returned (.5,.5)
                        if (point.y >= blackBar && point.y <= blackBar + y2) {
							// Scale (accounting for the letterboxing on the top and bottom of the video preview), switch x and y, and reverse x
                            xc = ((point.y - blackBar) / y2);
                            yc = 1.f - (point.x / x2);
                        }
                    }
                } else if ([[_previewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
					// Scale, switch x and y, and reverse x
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                        xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2; // Account for cropped height
                        yc = (frameSize.width - point.x) / frameSize.width;
                    } else {
                        CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                        yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2); // Account for cropped width
                        xc = point.y / frameSize.height;
                    }
                }
                
                pointOfInterest = CGPointMake(xc, yc);
                break;
            }
        }
    }
    
    return pointOfInterest;
}

// Auto focus at a particular point. The focus mode will change to locked once the auto focus happens.
- (void)tapToAutoFocus:(UIGestureRecognizer *)gestureRecognizer
{
    if ([_device isFocusPointOfInterestSupported] && [_previewLayer superlayer]) {
        CGPoint tapPoint = [gestureRecognizer locationInView:_previewView];
        CGPoint convertedFocusPoint = [self convertToPointOfInterestFromViewCoordinates:tapPoint];
        
        [_ringCreator animateRingAtPoint:tapPoint];
        [self autoFocusAtPoint:convertedFocusPoint];
    }
}

// Auto focus at a particular point. The focus mode will change to locked once the auto focus happens.
- (void)tapToAutoFocusAndExpose:(UIGestureRecognizer *)gestureRecognizer
{
    if ([_device isFocusPointOfInterestSupported] && [_device isExposurePointOfInterestSupported] && [_previewLayer superlayer]) {
        CGPoint tapPoint = [gestureRecognizer locationInView:_previewView];
        CGPoint convertedFocusPoint = [self convertToPointOfInterestFromViewCoordinates:tapPoint];
        
        [self autoExposeAtPoint:convertedFocusPoint];
    }
}

// perform a flash bulb animation using KVO to monitor the value of the capturingStillImage property of the AVCaptureStillImageOutput class
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ( context == @"AVCaptureStillImageIsCapturingStillImageContext" ) {
		BOOL isCapturingStillImage = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
		
		if ( isCapturingStillImage ) {
			// do flash bulb like animation
			_flashView = [[UIView alloc] initWithFrame:[_previewView bounds]];
			[_flashView setBackgroundColor:[UIColor whiteColor]];
			[_flashView setAlpha:0.f];
            [_previewView addSubview:_flashView]; // TODO/ISSUE: Should we add the subview to the window as per apple's example?
			
			[UIView animateWithDuration:.4f
							 animations:^{
								 [_flashView setAlpha:1.f];
							 }];
		}
		else {
			[UIView animateWithDuration:.4f
							 animations:^{
								 [_flashView setAlpha:0.f];
							 }
							 completion:^(BOOL finished){
								 [_flashView removeFromSuperview];
								 _flashView = nil;
							 }];
		}
	}
}

- (void)captureImage:(ImageCapturedBlock)success failure:(ImageCaptureFailureBlock)failure {
    AVCaptureConnection *stillImageConnection = [_stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    [stillImageConnection setVideoScaleAndCropFactor:_effectiveScale];
    
    [_stillImageOutput setOutputSettings:[NSDictionary dictionaryWithObject:AVVideoCodecJPEG
                                                                     forKey:AVVideoCodecKey]];
    
    [_stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection
                                                   completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                                                       if (error) {
                                                           // TODO: Update to handle error appropriately.
                                                           failure(@"An error occured while taking the photo.");
                                                       }
                                                       else {
                                                           // TODO: Update to use PNG rather than JPEG. You will also need to update the request to the server.
                                                           NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                                                           
                                                           UIImage *croppedImage = [self cropImage:[UIImage imageWithData:jpegData] to:_previewLayer.bounds];
                                                           
                                                           success(croppedImage);
                                                       }
                                                   }];
}

- (UIImage *)cropImage:(UIImage *)image to:(CGRect)rect {
    
    CGSize newSize = rect.size;
    UIImage *resizedImage = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill
                                                        bounds:CGSizeMake(newSize.width, newSize.height)
                                          interpolationQuality:kCGInterpolationHigh];
    
    CGRect cropRect = CGRectMake(round((resizedImage.size.width - newSize.width) / 2),
                                 round((resizedImage.size.height - newSize.height) / 2),
                                 newSize.width,
                                 newSize.height);
    UIImage *croppedImage = [resizedImage croppedImage:cropRect];
    
    return croppedImage;
}

// clean up capture setup
- (void)teardownCamera {
    // Stop the session. This is done asychronously since -stopRunning doesn't return until the session is stopped.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_session stopRunning];
    });
    NSLog(@"URGENT BUG FIX HERE");
    // TODO/URGENT: There is a bug here. If the user attempts to take photos too quickly, before the camera is setup,
    // the app crashes. This needs to be fixed. The UI should not show until the camera is ready.
	[_stillImageOutput removeObserver:self forKeyPath:@"capturingStillImage"];
	[_previewLayer removeFromSuperlayer];
}

#pragma mark Camera Properties

// Perform an auto focus at the specified point. The focus mode will automatically change to locked once the auto focus is complete.
- (void) autoFocusAtPoint:(CGPoint)point {
    if ([_device isFocusPointOfInterestSupported] && [_device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        NSError *error;
        if ([_device lockForConfiguration:&error]) {
            [_device setFocusPointOfInterest:point];
            [_device setFocusMode:AVCaptureFocusModeAutoFocus];
            [_device unlockForConfiguration];
        }
    }
}

- (void)autoExposeAtPoint:(CGPoint)point {
    if ([_device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
        NSError *error;
        if ([_device lockForConfiguration:&error]) {
            [_device setExposurePointOfInterest:point];
            [_device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            [_device unlockForConfiguration];
        }
    }
}

#pragma mark - AVCaptureVideoDataOutput delegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    // If we wanted to do any frame processing, such as placing indicators over detected
    // faces, we could do so here.
}

#pragma mark - View lifecycle

- (id)init {
    [NSException raise:@"Wrong init method called."
                format:@"Call initWithPreviewView: instead and pass a UIView."];
    return nil;
}

- (id)initWithPreviewView:(UIView *)previewView {
    self = [super init];
    if (self) {
        _previewView = previewView;
        _ringCreator = [[DLRingCreator alloc] initWithSuperView:_previewView];
    }
    return self;
}

@end
