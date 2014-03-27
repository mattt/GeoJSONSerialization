GeoJSONSerialization
====================

`GeoJSONSerialization` encodes and decodes between [GeoJSON](http://geojson.org) and [MapKit](https://developer.apple.com/library/ios/documentation/MapKit/Reference/MapKit_Framework_Reference/_index.html) shapes, following the API conventions of Foundation's `NSJSONSerialization` class.

## Usage

### Decoding

```objective-c
#import <MapKit/MapKit.h>
#import "GeoJSONSerialization.h"

NSURL *URL = [[NSBundle mainBundle] URLForResource:@"map" withExtension:@"geojson"];
NSData *data = [NSData dataWithContentsOfURL:URL];
NSDictionary *geoJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
NSArray *shapes = [GeoJSONSerialization shapesFromGeoJSONFeatureCollection:geoJSON error:nil];

for (MKShape *shape in shapes) {
    if ([shape isKindOfClass:[MKPointAnnotation class]]) {
        [mapView addAnnotation:shape];
    } else if ([shape conformsToProtocol:@protocol(MKOverlay)]) {
        [mapView addOverlay:(id <MKOverlay>)shape];
    }
}
```

> After implementing the necessary `MKMapViewDelegate` methods, the resulting map will look [something like this](https://github.com/mattt/GeoJSONSerialization/blob/master/Example/iOS%20Example/map.geojson).

---

## Contact

Mattt Thompson

- http://github.com/mattt
- http://twitter.com/mattt
- m@mattt.me

## License

GeoJSONSerialization is available under the MIT license. See the LICENSE file for more info.
