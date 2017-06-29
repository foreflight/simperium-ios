//
//  AJHitLogger.m
//  Simperium
//
//  Created by Anson Jablinski on 6/29/17.
//  Copyright © 2017 Simperium. All rights reserved.
//

#import "AJHitLogger.h"
#import "SPBucket.h"

typedef NSMutableDictionary<NSString *, NSNumber *> DictStringNumber;

@interface AJHitLogger ()

@property (nonatomic, strong) DictStringNumber *dataForAllTime;
@property (nonatomic, strong) DictStringNumber *dataSinceLastDump;

@end

@implementation AJHitLogger

- (instancetype)init {
    if (self = [super init]) {
        _dataForAllTime = [NSMutableDictionary dictionary];
        _dataSinceLastDump = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)recordHitForKey:(NSString *)key {
    @synchronized (self) {
        void (^incrementValueInDict)(NSMutableDictionary *, NSString *) = ^void(NSMutableDictionary *dictionary, NSString *keyToIncrement) {
            NSNumber *current = dictionary[keyToIncrement];
            NSNumber *new;
            if (current != nil) {
                new = @(current.integerValue + 1);
            } else {
                new = @(1);
            }
            dictionary[keyToIncrement] = new;
        };
        
        incrementValueInDict(self.dataForAllTime, key);
        incrementValueInDict(self.dataSinceLastDump, key);
        
        [self outputLines:@[[NSString stringWithFormat:@"hit %@", key]]];
    }
}

- (void)dumpHitSummary {
    @synchronized (self) {
        NSMutableArray<NSString *> *lines = [NSMutableArray array];
        [lines addObject:@"Logging hit summary:"];
        [lines addObject:@"all\t1 min\tkey"];
        
        NSArray<NSString *> *allKeys = [self.dataForAllTime.allKeys sortedArrayUsingSelector:@selector(compare:)];
        for (NSString *key in allKeys) {
            NSNumber *allTime = self.dataForAllTime[key];
            NSNumber *lastMin = self.dataSinceLastDump[key] ?: @(0);
            [lines addObject:[NSString stringWithFormat:@"%@\t%@\t%@", allTime, lastMin, key]];
        }
        
        [lines addObject:@"Logging hit summary -- done"];
        
        [self outputLines:lines.copy];
        
        self.dataSinceLastDump = [NSMutableDictionary dictionaryWithCapacity:self.dataForAllTime.count];
    }
}

// MARK: Class interface

+ (void)recordSendChangeForBucketName:(NSString *)bucket {
    [self recordHitForKey:[NSString stringWithFormat:@"send-%@", bucket]];
}

+ (void)recordReceivedAction:(NSString *)action forBucket:(SPBucket *)bucket {
    [self recordHitForKey:[NSString stringWithFormat:@"rec-%@-%@", action, bucket.name]];
}

+ (void)recordHitForKey:(NSString *)key {
    [[AJHitLogger sharedAJHitLogger] recordHitForKey:key];
}

+ (void)dumpHitSummary {
    [[AJHitLogger sharedAJHitLogger] dumpHitSummary];
}

// MARK: Helpers

- (void)outputLines:(NSArray<NSString *> *)lines {
    NSString *marker = @"simpnetwork";
    
    if (lines.count == 1){
        NSLog(@"%@: %@", marker, lines.firstObject);
        return;
    }
    
    NSMutableString *string = [NSMutableString stringWithString:marker];
    for (NSString *s in lines) {
        [string appendFormat:@"%@: %@\n", marker, s];
    }
    NSLog(@"%@", string);
}

+ (instancetype)sharedAJHitLogger
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

@end
