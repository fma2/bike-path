//
//  ResultsMapViewController.m
//  bikepath
//
//  Created by Farheen Malik on 8/14/14.
//  Copyright (c) 2014 Bike Path. All rights reserved.
//

#import "ResultsMapViewController.h"
#import <GoogleMaps/GoogleMaps.h>
#import <MapKit/MapKit.h>
#import <Foundation/Foundation.h>

@implementation ResultsMapViewController


- (IBAction)unwindToSearchPage:(UIStoryboardSegue *)segue{
    
}
- (void)viewDidLoad
{
    // Checking to see if search item object is here
    NSLog(@"%@", self.item.searchQuery);
    NSLog(@"%f", self.item.lati);
    NSLog(@"%f", self.item.longi);
    NSLog(@"%@", self.item.address);
    
    // calling information from the search item object
    // self.searchItem = self.item.searchQuery;
    // self.searchItemLati = self.item.lati
    // self.searchItemLongi = self.item.longi
    // self.searchItemAddress = self.item.address
    

    //placing it on the map
    GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = CLLocationCoordinate2DMake(self.item.lati, self.item.longi);
    marker.title = self.item.searchQuery;
    marker.icon = [GMSMarker markerImageWithColor:[UIColor redColor]];
    marker.map = self.mapView;
    
    
    
    self.mapView.mapType = kGMSTypeNormal;
    
    self.mapView.myLocationEnabled          = YES;
    self.mapView.settings.compassButton     = YES;
    self.mapView.settings.myLocationButton  = YES;
    self.mapView.settings.zoomGestures      = YES;
    self.mapView.settings.scrollGestures    = YES;
    self.mapView.delegate                   = self;
    
    GMSCoordinateBounds *bounds =
    [[GMSCoordinateBounds alloc] initWithCoordinate:marker.position coordinate:CLLocationCoordinate2DMake(40.706809, -74.009077)];
    // zoom camera to show origin (hard coded) and destination
    GMSCameraPosition *originToDestination = [self.mapView cameraForBounds:bounds insets:UIEdgeInsetsZero];
    
    [self.mapView setCamera:originToDestination];
    
    NSURL *url = [NSURL URLWithString:@"http://www.citibikenyc.com/stations/json"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data, NSError *connectionError)
     {
         if (data.length > 0 && connectionError == nil)
         {
             NSDictionary *greeting = [NSJSONSerialization JSONObjectWithData:data
                                                                      options:0
                                                                        error:NULL];
             NSArray *stations = [greeting objectForKey:@"stationBeanList"];
             CLLocationDistance smallestDistance = DBL_MAX;
             CLLocation *closestLocation;
             NSDictionary *closestStation;
             
             for(id st in stations) {
                 NSDictionary *station      = (NSDictionary *)st;
                 NSString *lati             = [station objectForKey:@"latitude"];
                 NSString *longi            = [station objectForKey:@"longitude"];

                 CLLocation *bikeStop           = [[CLLocation alloc] initWithLatitude:[lati doubleValue] longitude:[longi doubleValue]];
                 CLLocation *currentLocation    = self.mapView.myLocation;
                 
                 NSMutableArray *locations = [[NSMutableArray alloc] init];
                 [locations addObject:bikeStop];
                 
                    for (CLLocation *location in locations) {
                        CLLocationDistance distance = [currentLocation distanceFromLocation:location];
    
                        if (distance < smallestDistance) {
                            smallestDistance    = distance;
                            closestLocation     = location;
                            closestStation      = station;
                        }
                    }
                 
             }
             NSLog(@"%f", closestLocation.coordinate.latitude);
             NSLog(@"%f", closestLocation.coordinate.longitude);
             
             NSString *title            = [closestStation objectForKey:@"stationName"];
             NSString *availableBikes   = [[closestStation objectForKey:@"availableBikes"] stringValue];
             NSNumber *numBikes         = @([[closestStation objectForKey:@"availableBikes"] intValue]);
             
             GMSMarker *citiMarker  = [[GMSMarker alloc] init];
             
             if ([numBikes intValue] > 0) {
                 citiMarker.icon    = [GMSMarker markerImageWithColor:[UIColor greenColor]];
                 citiMarker.snippet = availableBikes;
             } else {
                 citiMarker.icon    = [GMSMarker markerImageWithColor:[UIColor redColor]];
                 citiMarker.snippet = @"No bikes available at this location.";
             };
             
             citiMarker.title       = title;
             citiMarker.position    = closestLocation.coordinate;
             citiMarker.map         = self.mapView;
        }
     }];
}

@end
