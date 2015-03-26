//
//  STLocationManager.m
//  STKit
//
//  Created by SunJiangting on 14-5-13.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STLocationManager.h"
#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <STKit/STPersistence.h>

@interface STLocationManager () <CLLocationManagerDelegate>

@property(nonatomic, strong) CLLocationManager * locationManager;

@property(nonatomic, strong) STLocationHandler locationHandler;

@property(nonatomic, strong) CLGeocoder *geocoder;

@property(nonatomic, assign) BOOL updatingLocation;

@property(nonatomic, strong) NSMutableArray *locationHandlers;
@property(nonatomic, strong) NSMutableArray *geocodeHandlers;

@end

@implementation STLocationManager

- (void)dealloc {
    self.locationManager.delegate = nil;
}

static STLocationManager *_sharedManager;
+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ _sharedManager = [[self alloc] init]; });
    return _sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.locationHandlers = [NSMutableArray arrayWithCapacity:1];
        self.geocodeHandlers = [NSMutableArray arrayWithCapacity:1];

        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.geocoder = [[CLGeocoder alloc] init];

        NSData *locationData = [[STPersistence standardPersistence] valueForKey:@"st-location"];
        if (locationData) {
            self.location = [NSKeyedUnarchiver unarchiveObjectWithData:locationData];
        }
        NSData *placemarkData = [[STPersistence standardPersistence] valueForKey:@"st-placemark"];
        if (placemarkData) {
            self.placemark = [NSKeyedUnarchiver unarchiveObjectWithData:placemarkData];
        }
        NSData *error = [[STPersistence standardPersistence] valueForKey:@"st-location-error"];
        if (error) {
            self.error = [NSKeyedUnarchiver unarchiveObjectWithData:error];
        }
    }
    return self;
}

- (void)requestWhenInUseAuthorization {
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
}
- (void)requestAlwaysAuthorization {
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }
}

- (void)obtainLocationWithHandler:(STLocationHandler)handler {
    [self obtainLocationWithHandler:handler reverseGeocodeHandler:NULL];
}

- (void)obtainLocationWithGeoHandler:(STGeoReverseHandler)geoReverseHandler {
    [self obtainLocationWithHandler:NULL reverseGeocodeHandler:geoReverseHandler];
}

- (void)reverseLocation:(CLLocation *)location reverseHandler:(STGeoReverseHandler)geoReverseHandler {
    [self.geocoder reverseGeocodeLocation:location
                        completionHandler:^(NSArray *placemarks, NSError *error) {
                            CLPlacemark *placemark = (placemarks.count > 0) ? placemarks[0] : nil;

                            if (geoReverseHandler) {
                                geoReverseHandler(placemark, error);
                            }
                        }];
}

- (void)obtainLocationWithHandler:(STLocationHandler)handler reverseGeocodeHandler:(STGeoReverseHandler)geoReverseHandler {
    if (handler) {
        [self.locationHandlers addObject:handler];
    }
    if (geoReverseHandler) {
        [self.geocodeHandlers addObject:geoReverseHandler];
    }
    if (!self.updatingLocation) {
        self.updatingLocation = YES;
        [self.locationManager startUpdatingLocation];
    }
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    [self didObtainLocation:newLocation error:nil];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];
    [self didObtainLocation:location error:nil];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self didObtainLocation:nil error:error];
}

#pragma mark - Private Method
- (void)didObtainLocation:(CLLocation *)location error:(NSError *)error {
    if (location) {
        //检测时间是为了屏蔽缓存位置点, 系统为了快速给出点, 往往头两个点是系统缓存点, 可能存在问题, 比如从A地移动到B地, 初始的两个点很大可能依旧在A地;
        NSTimeInterval duration = fabs([location.timestamp timeIntervalSinceNow]);
        CGFloat accuracy = location.horizontalAccuracy;
        if (duration < 10.0 && accuracy < 3000.0) {
            self.updatingLocation = NO;
            if (!error) {
                self.location = location;
            }
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:location];
            [[STPersistence standardPersistence] setValue:data forKey:@"st-location"];

            [self.locationManager stopUpdatingLocation];
            [self.locationHandlers enumerateObjectsUsingBlock:^(STLocationHandler handler, NSUInteger idx, BOOL *stop) { handler(location, error); }];
            [self.locationHandlers removeAllObjects];
            [self.geocoder reverseGeocodeLocation:location
                                completionHandler:^(NSArray *placemarks, NSError *error) {
                                    CLPlacemark *placemark = (placemarks.count > 0) ? placemarks[0] : nil;
                                    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:placemark];
                                    [[STPersistence standardPersistence] setValue:data forKey:@"st-placemark"];

                                    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:5];
                                    [userInfo setValue:placemark forKey:@"placemark"];
                                    [userInfo setValue:error forKey:@"error"];
                                    NSNotification *notification =
                                        [NSNotification notificationWithName:STLocationDidReverseNotification object:nil userInfo:userInfo];
                                    [[NSNotificationCenter defaultCenter] postNotification:notification];

                                    if (!error && placemark) {
                                        self.placemark = placemark;
                                    }
                                    [self.geocodeHandlers enumerateObjectsUsingBlock:^(STGeoReverseHandler handler, NSUInteger idx, BOOL *stop) {
                                        handler(placemark, error);
                                    }];
                                    [self.geocodeHandlers removeAllObjects];
                                }];
        }
    } else {
        self.error = error;

        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:error];
        [[STPersistence standardPersistence] setValue:data forKey:@"st-location-error"];

        self.updatingLocation = NO;
        [self.locationManager stopUpdatingLocation];
        [self.locationHandlers enumerateObjectsUsingBlock:^(STLocationHandler handler, NSUInteger idx, BOOL *stop) { handler(nil, error); }];
        [self.locationHandlers removeAllObjects];
        [self.geocodeHandlers enumerateObjectsUsingBlock:^(STGeoReverseHandler handler, NSUInteger idx, BOOL *stop) { handler(nil, error); }];
        [self.geocodeHandlers removeAllObjects];
    }
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:5];
    [userInfo setValue:location forKey:@"location"];
    [userInfo setValue:error forKey:@"error"];
    NSNotification *notification = [NSNotification notificationWithName:STLocationDidObtainNotification object:nil userInfo:userInfo];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

@end

NSString *const STLocationDidObtainNotification = @"STLocationDidObtainNotification";
NSString *const STLocationDidReverseNotification = @"STLocationDidReverseNotification";
