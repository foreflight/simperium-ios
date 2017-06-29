//
//  AJHitLogger.h
//  Simperium
//
//  Created by Anson Jablinski on 6/29/17.
//  Copyright © 2017 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SPBucket;

@interface AJHitLogger : NSObject

// MARK: Recording

+ (void)recordSendChangeForBucketName:(NSString *)bucket;

+ (void)recordReceivedAction:(NSString *)action forBucket:(SPBucket *)bucket;

+ (void)recordHitForKey:(NSString *)key;

// MARK: Results

+ (void)dumpHitSummary;

@end
