//
//  DLPhotoCreator.m
//  ImageUploader
//
//  Created by Bradley Griffith on 8/7/13.
//  Copyright (c) 2013 Bradley Griffith. All rights reserved.
//

#import "DLPhotoCreator.h"
#import "DLAPIClient.h"
#import "BlocksKit.h"
#import "Photo.h"

@implementation DLPhotoCreator

- (void)savePhoto:(Photo *)photo withProgress:(ProgressBlock)progressBlock completion:(CompletionBlock)completionBlock {
    
    NSURLRequest *postRequest = [[DLAPIClient sharedClient] multipartFormRequestWithMethod:@"POST"
                                                                                      path:@"/photos.json"
                                                                                parameters:nil
                                                                 constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                                                     [formData appendPartWithFileData:photo.photoData
                                                                                                 name:@"photo[image]"
                                                                                             fileName:@"photo.jpeg"
                                                                                             mimeType:@"image/jpeg"];
                                                                 }];
    
    AFHTTPRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:postRequest];
    
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        CGFloat progress = ((CGFloat)totalBytesWritten) / totalBytesExpectedToWrite;
        progressBlock(progress);
    }];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (operation.response.statusCode == 200 || operation.response.statusCode == 201) {
            NSLog(@"Created, %@", responseObject);
            completionBlock(YES, nil);
        } else {
            completionBlock(NO, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", error);
        completionBlock(NO, error);
    }];
    
    [[DLAPIClient sharedClient] enqueueHTTPRequestOperation:operation];
}

@end
