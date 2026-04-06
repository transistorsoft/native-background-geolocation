//
//  AllEventsSmokeTest.m
//  TSLocationManager
//
//  Created by Christopher Scott on 2025-09-02.
//  Copyright © 2025 Christopher Scott. All rights reserved.
//
// AllEventsSmokeTest.m
#import "AllEventsSmokeTest.h"
#import <TSLocationManager/TSLocationManager.h>

typedef NS_OPTIONS(NSUInteger, TSEventMask) {
    TSEventMaskLocation          = 1 << 0,
    TSEventMaskHttp              = 1 << 1,
    TSEventMaskGeofence          = 1 << 2,
    TSEventMaskHeartbeat         = 1 << 3,
    TSEventMaskMotionChange      = 1 << 4,
    TSEventMaskActivityChange    = 1 << 5,
    TSEventMaskProviderChange    = 1 << 6,
    TSEventMaskGeofencesChange   = 1 << 7,
    TSEventMaskSchedule          = 1 << 8,
    TSEventMaskPowerSaveChange   = 1 << 9,
    TSEventMaskConnectivityChange= 1 << 10,
    TSEventMaskEnabledChange     = 1 << 11,
    TSEventMaskAuthorization     = 1 << 12,
};

@implementation AllEventsSmokeTest
+ (void)runWithTimeout:(NSTimeInterval)timeoutSeconds {
    TSLocationManager *bg = [TSLocationManager sharedInstance];

    __block TSEventMask fired = 0;
    dispatch_queue_t q = dispatch_queue_create("com.transistorsoft.events.smoketest", DISPATCH_QUEUE_SERIAL);
    void (^mark)(TSEventMask, NSString *) = ^(TSEventMask bit, NSString *name){
        dispatch_async(q, ^{
            if (!(fired & bit)) {
                fired |= bit;
                NSLog(@"---> ✅ [%@] fired", name);
            }
        });
    };

    // 1) Register all listeners.
    [bg onLocation:^(TSLocationEvent * _Nonnull location) {
        mark(TSEventMaskLocation, @"location");
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"❌ [location] failure: %@", error);
    }];

    [bg onHttp:^(TSHttpEvent * _Nonnull event) {
        mark(TSEventMaskHttp, @"http");
    }];

    [bg onGeofence:^(TSGeofenceEvent * _Nonnull event) {
        mark(TSEventMaskGeofence, @"geofence");
    }];

    [bg onHeartbeat:^(TSHeartbeatEvent * _Nonnull event) {
        mark(TSEventMaskHeartbeat, @"heartbeat");
    }];

    [bg onMotionChange:^(TSLocationEvent * _Nonnull event) {
        mark(TSEventMaskMotionChange, @"motionchange");
    }];

    [bg onActivityChange:^(TSActivityChangeEvent * _Nonnull event) {
        mark(TSEventMaskActivityChange, @"activitychange");
    }];

    [bg onProviderChange:^(TSProviderChangeEvent * _Nonnull event) {
        mark(TSEventMaskProviderChange, @"providerchange");
    }];

    [bg onGeofencesChange:^(TSGeofencesChangeEvent * _Nonnull event) {
        mark(TSEventMaskGeofencesChange, @"geofenceschange");
    }];

    [bg onSchedule:^(TSScheduleEvent * _Nonnull event) {
        mark(TSEventMaskSchedule, @"schedule");
    }];

    [bg onPowerSaveChange:^(TSPowerSaveChangeEvent * _Nonnull event) {
        mark(TSEventMaskPowerSaveChange, @"powersavechange");
    }];

    [bg onConnectivityChange:^(TSConnectivityChangeEvent * _Nonnull event) {
        mark(TSEventMaskConnectivityChange, @"connectivitychange");
    }];

    [bg onEnabledChange:^(TSEnabledChangeEvent * _Nonnull event) {
        mark(TSEventMaskEnabledChange, @"enabledchange");
    }];

    [bg onAuthorization:^(TSAuthorizationEvent * _Nonnull event) {
        mark(TSEventMaskAuthorization, @"authorization");
    }];

    // 2) Optional: give the SDK a gentle “kick” to provoke events where possible.
    // These are safe no-ops if already configured. Adjust to your app context.
    [bg ready];
    [bg start];
    [bg changePace:YES];                        // can yield motionchange
    [bg requestPermission:^(NSNumber *status) { // can yield authorization/providerchange
        // no-op
    } failure:^(NSNumber *status) {}];

    // 3) After timeout, summarize results.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeoutSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        TSEventMask all = (TSEventMaskLocation |
                           TSEventMaskHttp |
                           TSEventMaskGeofence |
                           TSEventMaskHeartbeat |
                           TSEventMaskMotionChange |
                           TSEventMaskActivityChange |
                           TSEventMaskProviderChange |
                           TSEventMaskGeofencesChange |
                           TSEventMaskSchedule |
                           TSEventMaskPowerSaveChange |
                           TSEventMaskConnectivityChange |
                           TSEventMaskEnabledChange |
                           TSEventMaskAuthorization);

        if (fired == all) {
            NSLog(@"🎉 All 13 events fired at least once within %.0fs.", timeoutSeconds);
        } else {
            NSMutableArray<NSString *> *missing = [NSMutableArray new];
            if (!(fired & TSEventMaskLocation))            [missing addObject:@"location"];
            if (!(fired & TSEventMaskHttp))                [missing addObject:@"http"];
            if (!(fired & TSEventMaskGeofence))            [missing addObject:@"geofence"];
            if (!(fired & TSEventMaskHeartbeat))           [missing addObject:@"heartbeat"];
            if (!(fired & TSEventMaskMotionChange))        [missing addObject:@"motionchange"];
            if (!(fired & TSEventMaskActivityChange))      [missing addObject:@"activitychange"];
            if (!(fired & TSEventMaskProviderChange))      [missing addObject:@"providerchange"];
            if (!(fired & TSEventMaskGeofencesChange))     [missing addObject:@"geofenceschange"];
            if (!(fired & TSEventMaskSchedule))            [missing addObject:@"schedule"];
            if (!(fired & TSEventMaskPowerSaveChange))     [missing addObject:@"powersavechange"];
            if (!(fired & TSEventMaskConnectivityChange))  [missing addObject:@"connectivitychange"];
            if (!(fired & TSEventMaskEnabledChange))       [missing addObject:@"enabledchange"];
            if (!(fired & TSEventMaskAuthorization))       [missing addObject:@"authorization"];

            NSLog(@"⚠️ Missing events (within %.0fs): %@", timeoutSeconds, [missing componentsJoinedByString:@", "]);
        }
    });
}
@end
