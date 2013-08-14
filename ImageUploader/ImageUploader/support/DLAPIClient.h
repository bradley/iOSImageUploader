//
//  DLAPIClient.h
//  ImageUploader
//
//  Created by Bradley Griffith on 8/7/13.
//  Copyright (c) 2013 Bradley Griffith. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

@interface DLAPIClient : AFHTTPClient
+ (id)sharedClient;
@end