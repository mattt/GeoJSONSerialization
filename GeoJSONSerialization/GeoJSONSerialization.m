// GeoJSONSerialization.m
// 
// Copyright (c) 2014 Mattt Thompson
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "GeoJSONSerialization.h"

#pragma mark - Geometry Primitives

NSString * const GeoJSONSerializationErrorDomain = @"com.geojson.serialization.error";

static MKPointAnnotation * MKPointAnnotationFromGeoJSONPointFeature(NSDictionary *feature) {
    NSDictionary *geometry = feature[@"geometry"];

    NSCParameterAssert([geometry[@"type"] isEqualToString:@"Point"]);

    NSArray *coordinates = geometry[@"coordinates"];

    NSNumber *longitude = [coordinates firstObject];
    NSNumber *latitude = [coordinates lastObject];

    MKPointAnnotation *pointAnnotation = [[MKPointAnnotation alloc] init];
    pointAnnotation.coordinate = CLLocationCoordinate2DMake([latitude doubleValue], [longitude doubleValue]);

    NSDictionary *properties = [NSDictionary dictionaryWithDictionary:feature[@"properties"]];
    pointAnnotation.title = properties[@"title"];
    pointAnnotation.subtitle = properties[@"subtitle"];

    return pointAnnotation;
}

static MKPolyline * MKPolylineFromGeoJSONLineStringFeature(NSDictionary *feature) {
    NSDictionary *geometry = feature[@"geometry"];

    NSCParameterAssert([geometry[@"type"] isEqualToString:@"LineString"]);

    NSArray *coordinatePairs = geometry[@"coordinates"];

    NSUInteger count = [coordinatePairs count];
    CLLocationCoordinate2D polylineCoordinates[count];
    for (NSUInteger idx = 0; idx < count; idx++) {
        NSArray *coordinates = coordinatePairs[idx];
        NSNumber *longitude = [coordinates firstObject];
        NSNumber *latitude = [coordinates lastObject];

        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([latitude doubleValue], [longitude doubleValue]);
        polylineCoordinates[idx] = coordinate;
    }

    MKPolyline *polyLine = [MKPolyline polylineWithCoordinates:polylineCoordinates count:count];

    NSDictionary *properties = [NSDictionary dictionaryWithDictionary:feature[@"properties"]];
    polyLine.title = properties[@"title"];
    polyLine.subtitle = properties[@"subtitle"];

    return polyLine;
}

static MKPolygon * MKPolygonFromGeoJSONPolygonFeature(NSDictionary *feature) {
    NSDictionary *geometry = feature[@"geometry"];

    NSCParameterAssert([geometry[@"type"] isEqualToString:@"Polygon"]);

    NSArray *coordinateSets = geometry[@"coordinates"];

    NSMutableArray *mutablePolygons = [NSMutableArray arrayWithCapacity:[coordinateSets count]];
    for (NSArray *coordinatePairs in coordinateSets) {
        NSUInteger count = [coordinatePairs count];
        CLLocationCoordinate2D polygonCoordinates[count];
        for (NSUInteger idx = 0; idx < count; idx++) {
            NSArray *coordinates = coordinatePairs[idx];
            NSNumber *longitude = [coordinates firstObject];
            NSNumber *latitude = [coordinates lastObject];

            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([latitude doubleValue], [longitude doubleValue]);
            polygonCoordinates[idx] = coordinate;
        }

        MKPolygon *polygon = [MKPolygon polygonWithCoordinates:polygonCoordinates count:count];
        [mutablePolygons addObject:polygon];
    }

    MKPolygon *polygon = nil;
    switch ([mutablePolygons count]) {
        case 0:
            return nil;
        case 1:
            polygon = [mutablePolygons firstObject];
            break;
        default: {
            MKPolygon *exteriorPolygon = [mutablePolygons firstObject];
            NSArray *interiorPolygons = [mutablePolygons subarrayWithRange:NSMakeRange(1, [mutablePolygons count] - 1)];
            polygon = [MKPolygon polygonWithPoints:exteriorPolygon.points count:exteriorPolygon.pointCount interiorPolygons:interiorPolygons];
        }
            break;
    }

    NSDictionary *properties = [NSDictionary dictionaryWithDictionary:feature[@"properties"]];
    polygon.title = properties[@"title"];
    polygon.subtitle = properties[@"subtitle"];

    return polygon;
}

#pragma mark - Multipart Geometries

static NSArray * MKPointAnnotationsFromGeoJSONMultiPointFeature(NSDictionary *feature) {
    NSDictionary *geometry = geometry[@"geometry"];

    NSCParameterAssert([geometry[@"type"] isEqualToString:@"MultiPoint"]);

    NSArray *coordinatePairs = geometry[@"coordinates"];
    NSDictionary *properties = [NSDictionary dictionaryWithDictionary:feature[@"properties"]];

    NSMutableArray *mutablePointAnnotations = [NSMutableArray arrayWithCapacity:[coordinatePairs count]];
    for (NSArray *coordinates in coordinatePairs) {
        NSDictionary *subFeature = @{
                                     @"type": @"Feature",
                                     @"geometry": @{
                                             @"type": @"Point",
                                             @"coordinates": coordinates
                                             },
                                     @"properties": properties
                                     };

        [mutablePointAnnotations addObject:MKPointAnnotationFromGeoJSONPointFeature(subFeature)];
    }

    return [NSArray arrayWithArray:mutablePointAnnotations];
}

static NSArray * MKPolylinesFromGeoJSONMultiLineStringFeature(NSDictionary *feature) {
    NSDictionary *geometry = geometry[@"geometry"];

    NSCParameterAssert([geometry[@"type"] isEqualToString:@"MultiLineString"]);

    NSArray *coordinateSets = geometry[@"coordinates"];
    NSDictionary *properties = [NSDictionary dictionaryWithDictionary:feature[@"properties"]];

    NSMutableArray *mutablePolylines = [NSMutableArray arrayWithCapacity:[coordinateSets count]];
    for (NSArray *coordinatePairs in coordinateSets) {
        NSDictionary *subFeature = @{
                                     @"type": @"Feature",
                                     @"geometry": @{
                                             @"type": @"LineString",
                                             @"coordinates": coordinatePairs
                                             },
                                     @"properties": properties
                                     };

        [mutablePolylines addObject:MKPolylineFromGeoJSONLineStringFeature(subFeature)];
    }

    return [NSArray arrayWithArray:mutablePolylines];
}

static NSArray * MKPolygonsFromGeoJSONMultiPolygonFeature(NSDictionary *feature) {
    NSDictionary *geometry = geometry[@"geometry"];

    NSCParameterAssert([geometry[@"type"] isEqualToString:@"MultiPolygon"]);

    NSArray *coordinateGroups = geometry[@"coordinates"];
    NSDictionary *properties = [NSDictionary dictionaryWithDictionary:feature[@"properties"]];

    NSMutableArray *mutablePolylines = [NSMutableArray arrayWithCapacity:[coordinateGroups count]];
    for (NSArray *coordinateSets in coordinateGroups) {
        NSDictionary *subFeature = @{
                                     @"type": @"Feature",
                                     @"geometry": @{
                                             @"type": @"Polygon",
                                             @"coordinates": coordinateSets
                                             },
                                     @"properties": properties
                                     };

        [mutablePolylines addObject:MKPolygonFromGeoJSONPolygonFeature(subFeature)];
    }

    return [NSArray arrayWithArray:mutablePolylines];
}

#pragma mark -

static id MKShapeFromGeoJSONFeature(NSDictionary *feature) {
    NSCParameterAssert([feature[@"type"] isEqualToString:@"Feature"]);

    NSDictionary *geometry = feature[@"geometry"];
    NSString *type = geometry[@"type"];
    if ([type isEqualToString:@"Point"]) {
        return MKPointAnnotationFromGeoJSONPointFeature(feature);
    } else if ([type isEqualToString:@"LineString"]) {
        return MKPolylineFromGeoJSONLineStringFeature(feature);
    } else if ([type isEqualToString:@"Polygon"]) {
        return MKPolygonFromGeoJSONPolygonFeature(feature);
    } else if ([type isEqualToString:@"MultiPoint"]) {
        return MKPointAnnotationsFromGeoJSONMultiPointFeature(feature);
    } else if ([type isEqualToString:@"MultiLineString"]) {
        return MKPolylinesFromGeoJSONMultiLineStringFeature(feature);
    } else if ([type isEqualToString:@"MultiPolygon"]) {
        return MKPolygonsFromGeoJSONMultiPolygonFeature(feature);
    }

    return nil;
}

static NSArray * MKShapesFromGeoJSONFeatureCollection(NSDictionary *featureCollection) {
    NSCParameterAssert([featureCollection[@"type"] isEqualToString:@"FeatureCollection"]);

    NSMutableArray *mutableShapes = [NSMutableArray array];
    for (NSDictionary *feature in featureCollection[@"features"]) {
        id shape = MKShapeFromGeoJSONFeature(feature);
        if (shape) {
            [mutableShapes addObject:shape];
        }
    }
    
    return [NSArray arrayWithArray:mutableShapes];
}

#pragma mark -


@implementation GeoJSONSerialization

+ (MKShape *)shapeFromGeoJSONFeature:(NSDictionary *)feature
                               error:(NSError * __autoreleasing *)error
{
    @try {
        return MKShapeFromGeoJSONFeature(feature);
    }
    @catch (NSException *exception) {
        if (error) {
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey: exception.name,
                                       NSLocalizedFailureReasonErrorKey: exception.reason
                                       };

            *error = [NSError errorWithDomain:GeoJSONSerializationErrorDomain code:-1 userInfo:userInfo];
        }

        return nil;
    }
}

+ (NSArray *)shapesFromGeoJSONFeatureCollection:(NSDictionary *)featureCollection
                                          error:(NSError * __autoreleasing *)error
{
    @try {
        return MKShapesFromGeoJSONFeatureCollection(featureCollection);
    }
    @catch (NSException *exception) {
        if (error) {
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey: exception.name,
                                       NSLocalizedFailureReasonErrorKey: exception.reason
                                       };

            *error = [NSError errorWithDomain:GeoJSONSerializationErrorDomain code:-1 userInfo:userInfo];
        }

        return nil;
    }
}

#pragma mark -

//+ (NSDictionary *)GeoJSONFeatureFromShape:(MKShape *)shape
//                               properties:(NSDictionary *)properties
//                                    error:(NSError * __autoreleasing *)error
//{
//    return nil;
//}

//+ (NSDictionary *)GeoJSONFeatureCollectionFromShapes:(NSArray *)shapes
//                                          properties:(NSArray *)arrayOfProperties
//                                               error:(NSError * __autoreleasing *)error
//{
//    return nil;
//}

@end
