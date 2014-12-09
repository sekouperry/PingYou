//
//  MapViewController.m
//  PingYou
//
//  Created by André Hansson on 15/10/14.
//  Copyright (c) 2014 PingPal AB. All rights reserved.
//

#import "MapViewController.h"
#import "Mapbox.h"
#import "DataStore.h"

#define FirstTimeTip @"Please wait for the location to arrive\n\nIf you go back the ping will be canceled"

@interface MapViewController (){
    
    RMMapView *mapView;
    
    // Loading view
    UIActivityIndicatorView *activityView;
    UIView *loadingView;
    UILabel *loadingLabel;
}

- (IBAction)backButtonClicked:(UIButton *)sender;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

// The view in storyboard I use as a container view for the map.
@property (weak, nonatomic) IBOutlet UIView *viewForMap;

@end

@implementation MapViewController

-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        // Create a weak reference to self that we will use in the pingInbox block to avoid a retain cycle
        __weak typeof(self) weakSelf = self;
        
        // Setup the pingInbox block. This is where we will be receiving the locations from our contacts.
        _pingInbox = ^(NSMutableDictionary *payload, NSMutableDictionary *options, Outbox *outbox) {
            NSLog(@"PingInbox Payload: %@. Options: %@", payload, options);
            
            // Make a strong reference to the weak reference. This will make sure the weak reference isn't released before the end of the block.
            __strong typeof(self) strongSelf = weakSelf;
            
            // Make sure strongSelf exists
            if (strongSelf)
            {
                // Remove the loading view.
                if ([strongSelf->activityView isAnimating]) {
                    [strongSelf->activityView stopAnimating];
                    [strongSelf->loadingView removeFromSuperview];
                }
                
                // If the contact wasn't allowed to ping.
                if (payload[@"accessDenied"]) {
                    NSLog(@"accessDenied");
                    [[[UIAlertView alloc]initWithTitle:@"ACCESS DENIED" message:@"THE USER YOU TRIED TO PING HAS NOT APPROVED YOU" delegate:strongSelf cancelButtonTitle:@"OK" otherButtonTitles:nil]show];
                    return;
                }
                
                NSDictionary *dict = payload[@"location"];
                
                // Create a CLLocation object from the information in the message. We only need the latitude and longitude. Other information is available as well.
                CLLocation *location = [[CLLocation alloc]initWithLatitude:[dict[@"latitude"]doubleValue] longitude:[dict[@"longitude"]doubleValue]];
                
                // Make sure the mapView was created
                if (strongSelf->mapView)
                {
                    // Set the center of the map
                    [strongSelf->mapView setZoom:15 atCoordinate:location.coordinate animated:YES];
                    
                    // Create the annotation
                    RMPointAnnotation *point = [[RMPointAnnotation alloc]initWithMapView:strongSelf->mapView coordinate:CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude) andTitle:strongSelf.name];
                    
                    // Add the annotation
                    [strongSelf->mapView addAnnotation:point];
                }
            }
        };
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Set the name at the top
    [_nameLabel setText:self.name];
    
    // Create tilesoure
    RMMapboxSource *tileSource = [[RMMapboxSource alloc] initWithMapID:@"andrehansson.k6fbp4no"];
    
    // Create mapView
    mapView = [[RMMapView alloc]initWithFrame:CGRectMake(0, 0, _viewForMap.frame.size.width, _viewForMap.frame.size.height) andTilesource:tileSource];
    
    // Caused problems with the mapViews size.
    [mapView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    // Add the mapView
    [_viewForMap addSubview:mapView];
    
    // Setup constraints for the mapView
    NSLayoutConstraint *mapViewTop = [NSLayoutConstraint constraintWithItem:mapView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_viewForMap attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
    NSLayoutConstraint *mapViewBottom = [NSLayoutConstraint constraintWithItem:mapView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_viewForMap attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
    NSLayoutConstraint *mapViewLeft = [NSLayoutConstraint constraintWithItem:mapView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_viewForMap attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
    NSLayoutConstraint *mapViewRight = [NSLayoutConstraint constraintWithItem:mapView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_viewForMap attribute:NSLayoutAttributeRight multiplier:1.0 constant:0];
    
    [self.view addConstraints:@[mapViewTop, mapViewBottom, mapViewLeft, mapViewRight]];
    
    // Create and present the loadingView
    loadingView = [[UIView alloc] initWithFrame:CGRectMake(75, 155, 170, 170)];
    loadingView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
    loadingView.clipsToBounds = YES;
    loadingView.layer.cornerRadius = 10.0;
    
    activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityView.frame = CGRectMake(65, 40, activityView.bounds.size.width, activityView.bounds.size.height);
    [loadingView addSubview:activityView];
    
    loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 115, 130, 22)];
    loadingLabel.backgroundColor = [UIColor clearColor];
    loadingLabel.textColor = [UIColor whiteColor];
    loadingLabel.adjustsFontSizeToFitWidth = YES;
    loadingLabel.textAlignment = NSTextAlignmentCenter;
    loadingLabel.text = @"PLEASE WAIT";
    [loadingView addSubview:loadingLabel];
    
    [loadingView setCenter:self.view.center];
    
    [self.view addSubview:loadingView];
    [activityView startAnimating];
    
    // If the tip has not been showed before, show it.
    if (![DataStore hasShownFirstTimeMapViewTip])
    {
        [[[UIAlertView alloc]initWithTitle:[FirstTimeTip uppercaseString] message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil]show];
        // Save that we has shown the tip.
        [DataStore setHasShownFirstTimeMapViewTip:YES];
    }
}

- (IBAction)backButtonClicked:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end