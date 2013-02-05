/*
 * Copyright 2013 StackMob
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "SMPredicate.h"

@interface SMPredicate ()

@property (strong, nonatomic) NSDictionary *predicateDictionary;
@property (nonatomic) SMPredicateOperatorType sm_predicateOperatorType;

@end


@implementation SMPredicate

@synthesize predicateDictionary = _predicateDictionary;
@synthesize sm_predicateOperatorType = _sm_predicateOperatorType;

- (id)init {
    
    if (!(self = [super init]))
        return nil;
    
    return self;
}

+(SMPredicate *)predicateWhere:(NSString *)field isWithin:(CLLocationDistance)kilometers kilometersOf:(CLLocationCoordinate2D)point {

    SMPredicate *predicate = [[SMPredicate alloc] init];
    
    NSNumber *latitude = [NSNumber numberWithDouble:point.latitude];
    NSNumber *longitude = [NSNumber numberWithDouble:point.longitude];
    
    NSDictionary *coordinate = [NSDictionary dictionaryWithObjectsAndKeys:latitude, @"latitude", longitude, @"longitude", nil];
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:1];
    [dictionary setValue:field forKey:GEOQUERY_FIELD];
    [dictionary setValue:[NSNumber numberWithDouble:kilometers] forKey:GEOQUERY_KILOMETERS];
    [dictionary setValue:coordinate forKey:GEOQUERY_COORDINATE];
    
    predicate.predicateDictionary = [NSDictionary dictionaryWithDictionary:dictionary];
    predicate.sm_predicateOperatorType = SMGeoQueryWithinKilometersOperatorType;
    
    return predicate;
}

+(SMPredicate *)predicateWhere:(NSString *)field isWithin:(CLLocationDistance)miles milesOf:(CLLocationCoordinate2D)point {
   
    SMPredicate *predicate = [[SMPredicate alloc] init];
    
    NSNumber *latitude = [NSNumber numberWithDouble:point.latitude];
    NSNumber *longitude = [NSNumber numberWithDouble:point.longitude];
    
    NSDictionary *coordinate = [NSDictionary dictionaryWithObjectsAndKeys:latitude, GEOQUERY_LAT, longitude, GEOQUERY_LONG, nil];
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:1];
    [dictionary setValue:field forKey:GEOQUERY_FIELD];
    [dictionary setValue:[NSNumber numberWithDouble:miles] forKey:GEOQUERY_MILES];
    [dictionary setValue:coordinate forKey:GEOQUERY_COORDINATE];
    
    
    predicate.predicateDictionary = [NSDictionary dictionaryWithDictionary:dictionary];
    predicate.sm_predicateOperatorType = SMGeoQueryWithinMilesOperatorType;
    
    return predicate;
}

+(SMPredicate *)predicateWhere:(NSString *)field isWithinBoundsWithSWCorner:(CLLocationCoordinate2D)sw andNECorner:(CLLocationCoordinate2D)ne {
    
    SMPredicate *predicate = [[SMPredicate alloc] init];
    
    NSNumber *swLatitude = [NSNumber numberWithDouble:sw.latitude];
    NSNumber *swLongitude = [NSNumber numberWithDouble:sw.longitude];
    NSDictionary *swCoordinate = [NSDictionary dictionaryWithObjectsAndKeys:swLatitude, GEOQUERY_LAT, swLongitude, GEOQUERY_LONG, nil];
    
    NSNumber *neLatitude = [NSNumber numberWithDouble:ne.latitude];
    NSNumber *neLongitude = [NSNumber numberWithDouble:ne.longitude];
    NSDictionary *neCoordinate = [NSDictionary dictionaryWithObjectsAndKeys:neLatitude, GEOQUERY_LAT, neLongitude, GEOQUERY_LONG, nil];
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:1];
    [dictionary setValue:field forKey:GEOQUERY_FIELD];
    [dictionary setValue:swCoordinate forKey:GEOQUERY_SW_BOUND];
    [dictionary setValue:neCoordinate forKey:GEOQUERY_NE_BOUND];
    
    predicate.predicateDictionary = [NSDictionary dictionaryWithDictionary:dictionary];
    predicate.sm_predicateOperatorType = SMGeoQueryWithinBoundsOperatorType;
    
    return predicate;
}

+(SMPredicate *)predicateWhere:(NSString *)field near:(CLLocationCoordinate2D)point {
    
    SMPredicate *predicate = [[SMPredicate alloc] init];
    
    NSNumber *latitude = [NSNumber numberWithDouble:point.latitude];
    NSNumber *longitude = [NSNumber numberWithDouble:point.longitude];
    
    NSDictionary *coordinate = [NSDictionary dictionaryWithObjectsAndKeys:latitude, GEOQUERY_LAT, longitude, GEOQUERY_LONG, nil];
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:1];
    [dictionary setValue:field forKey:GEOQUERY_FIELD];
    [dictionary setValue:coordinate forKey:GEOQUERY_COORDINATE];
    
    predicate.predicateDictionary = [NSDictionary dictionaryWithDictionary:dictionary];
    predicate.sm_predicateOperatorType = SMGeoQueryNearOperatorType;
    
    return predicate;
}

@end
