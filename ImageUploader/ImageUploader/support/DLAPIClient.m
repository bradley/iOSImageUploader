//
//  DLAPIClient.m
//  ImageUploader
//
//  Created by Bradley Griffith on 8/7/13.
//  Copyright (c) 2013 Bradley Griffith. All rights reserved.
//

#import "DLAPIClient.h"
#import "AFJSONRequestOperation.h"

#define BASE_URL @"http://localhost:9292"

@implementation DLAPIClient

+ (id)sharedClient {
    static DLAPIClient *__instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *baseUrl = [NSURL URLWithString:BASE_URL];
        __instance = [[DLAPIClient alloc] initWithBaseURL:baseUrl];
    });
    return __instance;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (self) {
        [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [self setDefaultHeader:@"Accept" value:@"application/json"];
    }
    return self;
}

@end