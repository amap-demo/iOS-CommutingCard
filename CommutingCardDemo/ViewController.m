//
//  ViewController.m
//
//  Created by zuola on 2019/5/10.
//  Copyright © 2019 zuola. All rights reserved.
//

#import "ViewController.h"
#import <MAMapKit/MAMapKit.h>
#import <AMapSearchKit/AMapSearchKit.h>
#import "MANaviRoute.h"
#import "CommonUtility.h"
#import "BusStateAnnotationView.h"
#import "MABusStopAnnotation.h"
#import "MAPolyLineSelectAnnotationView.h"
#import "CommonDefine.h"
#import "SettingViewController.h"

#define kLocationName @"您的位置"
#define kFirstBusStart @"kFirstBusStart"
#define kElseBusStart @"kElseBusStart"
#define kSelectPolyLine @"选择路线"
#define kAMapNaviRoutePlanPointAnnotationViewStartImageName  @"default_common_route_startpoint_normal"
#define kAMapNaviRoutePlanPointAnnotationViewEndImageName    @"default_common_route_endpoint_normal"

static const NSInteger RoutePlanningPaddingEdge                    = 20;
static const NSString *RoutePlanningViewControllerStartTitle       = @"起点";
static const NSString *RoutePlanningViewControllerDestinationTitle = @"终点";

@interface ViewController ()<MAMapViewDelegate, AMapSearchDelegate,SettingViewControllerDelegate>{
    CommutingCardType _type;
    UILabel *_titleLab;
    UIButton *_startBtn;
    UILabel *_timeLab;
    UILabel *_starLab;
    UILabel *_endLab;
    NSMutableArray *_busNams;
    NSMutableArray *_busViaStopsAno;
    NSMutableArray *_selectPolyLineAno;
}
@property (nonatomic, strong) MAMapView *mapView;
@property (nonatomic, strong) AMapSearchAPI *search;
/* 起始点经纬度. */
@property (nonatomic) CLLocationCoordinate2D startCoordinate;
/* 终点经纬度. */
@property (nonatomic) CLLocationCoordinate2D destinationCoordinate;
@property (nonatomic, strong) AMapRoute *route;
/* 用于显示当前路线方案. */
@property (nonatomic) MANaviRoute * naviRoute;
//驾驶路线方案
@property (nonatomic) NSMutableArray <MANaviRoute *>* driveNaviRoutes;
/*当前公交组合方案*/
@property (nonatomic, strong) AMapTransit *transit;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, assign) NSInteger seconds;
@property (nonatomic, strong) NSMutableArray *optionalPolyLines;
@property (nonatomic, assign) NSInteger selectedIndex;

/* 起始点poi. */
@property (nonatomic,copy) NSString* startPOI;
/* 终点poi. */
@property (nonatomic,copy) NSString* destinationPOI;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(returnAction)];
    self.startCoordinate        = CLLocationCoordinate2DMake(39.903351, 116.473098);
    self.destinationCoordinate  = CLLocationCoordinate2DMake(40.018217, 116.418767);
    self.startPOI = @"国家广告产业园";
    self.destinationPOI = @"奥北家园";

    self.optionalPolyLines = [NSMutableArray new];
    _busNams = [NSMutableArray new];
    _busViaStopsAno = [NSMutableArray new];
    self.driveNaviRoutes = [NSMutableArray new];
    _selectPolyLineAno = [NSMutableArray new];
    _type = CommutingCardTypeBus;//CommutingCardTypeDrive;
    self.mapView = [[MAMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapView.delegate = self;
    
    [self.view addSubview:self.mapView];
    self.mapView.showTraffic = YES;
    
    // 开启定位
    self.mapView.showsUserLocation = YES;
    self.mapView.userTrackingMode = MAUserTrackingModeFollow;
    self.mapView.userLocation.title = kLocationName;
    
    self.search = [[AMapSearchAPI alloc] init];
    self.search.delegate = self;
    
    [self initControls];
    [self initStartAndEnd];

    if (_type == CommutingCardTypeBus) {
        [self searchRoutePlanningBus];
    }else if (_type == CommutingCardTypeDrive){
        [self searchRoutePlanningDrive];
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
}

- (void)addDefaultAnnotations
{
    MAPointAnnotation *startAnnotation = [[MAPointAnnotation alloc] init];
    startAnnotation.coordinate = self.startCoordinate;
    startAnnotation.title      = (NSString*)RoutePlanningViewControllerStartTitle;
    startAnnotation.subtitle   = [NSString stringWithFormat:@"{%f, %f}", self.startCoordinate.latitude, self.startCoordinate.longitude];
    MAPointAnnotation *destinationAnnotation = [[MAPointAnnotation alloc] init];
    destinationAnnotation.coordinate = self.destinationCoordinate;
    destinationAnnotation.title      = (NSString*)RoutePlanningViewControllerDestinationTitle;
    destinationAnnotation.subtitle   = [NSString stringWithFormat:@"{%f, %f}", self.destinationCoordinate.latitude, self.destinationCoordinate.longitude];
    
    [self.mapView addAnnotation:startAnnotation];
    [self.mapView addAnnotation:destinationAnnotation];
}

#pragma mark - do search
- (void)searchRoutePlanningDrive{
    AMapDrivingRouteSearchRequest *navi = [[AMapDrivingRouteSearchRequest alloc] init];
    navi.requireExtension = YES;
    /* 出发点. */
    navi.strategy = 10;
    navi.origin = [AMapGeoPoint locationWithLatitude:self.startCoordinate.latitude
                                           longitude:self.startCoordinate.longitude];
    /* 目的地. */
    navi.destination = [AMapGeoPoint locationWithLatitude:self.destinationCoordinate.latitude
                                                longitude:self.destinationCoordinate.longitude];
    
    [self.search AMapDrivingRouteSearch:navi];
}
- (void)searchRoutePlanningBus{
    AMapTransitRouteSearchRequest *navi = [[AMapTransitRouteSearchRequest alloc] init];
    navi.strategy = 5;
    navi.requireExtension = YES;
    navi.city             = @"beijing";
    /* 出发点. */
    navi.origin = [AMapGeoPoint locationWithLatitude:self.startCoordinate.latitude
                                           longitude:self.startCoordinate.longitude];
    /* 目的地. */
    navi.destination = [AMapGeoPoint locationWithLatitude:self.destinationCoordinate.latitude
                                                longitude:self.destinationCoordinate.longitude];
    [self.search AMapTransitRouteSearch:navi];
}

- (void)initControls{
    UIButton *btn1 = [UIButton new];
    btn1.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:1];
    btn1.layer.cornerRadius = 5;
    btn1.layer.masksToBounds = YES;
    btn1.frame = CGRectMake(10, 20, 60, 40);
    [btn1 setTitle:@"切为驾车" forState:UIControlStateNormal];
    [btn1 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    btn1.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    [btn1 addTarget:self action:@selector(setting:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn1];
}

- (void)initStartAndEnd{
    UIView *base = [[UIView alloc]initWithFrame:CGRectMake(75, 20, self.view.bounds.size.width - 70 - 50, 60)];
    base.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:base];
    _starLab = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 190, 30)];
    _starLab.text = [NSString stringWithFormat:@"起点:%@",self.startPOI];
    _starLab.textColor = [UIColor blackColor];
    _starLab.font = [UIFont systemFontOfSize:14];
    [base addSubview:_starLab];
    UIButton *startBtn = [[UIButton alloc]initWithFrame:CGRectMake(_starLab.bounds.origin.x + _starLab.bounds.size.width, 0, 70, 25)];
    startBtn.backgroundColor = [UIColor redColor];
    [startBtn setTitle:@"重选起点" forState:UIControlStateNormal];
    [startBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    startBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    [startBtn addTarget:self action:@selector(startBtn:) forControlEvents:UIControlEventTouchUpInside];
    [base addSubview:startBtn];

    _endLab = [[UILabel alloc]initWithFrame:CGRectMake(0, 30, 190, 30)];
    _endLab.text = [NSString stringWithFormat:@"终点:%@",self.destinationPOI];
    _endLab.textColor = [UIColor blackColor];
    _endLab.font = [UIFont systemFontOfSize:14];
    [base addSubview:_endLab];
    UIButton *endBtn = [[UIButton alloc]initWithFrame:CGRectMake(_endLab.bounds.origin.x + _endLab.bounds.size.width, 30, 70, 25)];
    endBtn.backgroundColor = [UIColor redColor];
    [endBtn setTitle:@"重选终点" forState:UIControlStateNormal];
    [endBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    endBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    [endBtn addTarget:self action:@selector(endBtn:) forControlEvents:UIControlEventTouchUpInside];
    [base addSubview:endBtn];
}

- (void)startBtn:(UIButton *)sender{
    SettingViewController *startVC = [SettingViewController new];
    startVC.delegate = self;
    startVC.type = 0;
    [self.navigationController pushViewController:startVC animated:YES];
}
- (void)endBtn:(UIButton *)sender{
    SettingViewController *endVC = [SettingViewController new];
    endVC.delegate = self;
    endVC.type = 1;
    [self.navigationController pushViewController:endVC animated:YES];
}

- (void)setting:(UIButton *)sender{
    if (CommutingCardTypeDrive == _type) {
        _type = CommutingCardTypeBus;
        [sender setTitle:@"切为驾车" forState:UIControlStateNormal];
        [self searchRoutePlanningBus];
    }else{
        _type = CommutingCardTypeDrive;
        [sender setTitle:@"切为公交" forState:UIControlStateNormal];
        [self searchRoutePlanningDrive];
    }
    
}

/* 展示当前路线方案. */
- (void)presentCurrentCourse{
    [self.mapView removeOverlays:self.mapView.overlays];
    if (_type == CommutingCardTypeBus) {
        self.naviRoute = [MANaviRoute naviRouteForTransit:self.transit startPoint:[AMapGeoPoint locationWithLatitude:self.startCoordinate.latitude longitude:self.startCoordinate.longitude] endPoint:[AMapGeoPoint locationWithLatitude:self.destinationCoordinate.latitude longitude:self.destinationCoordinate.longitude]];
        [self.naviRoute addToMapView:self.mapView];
        
        /* 缩放地图使其适应polylines的展示. */
        [self.mapView setVisibleMapRect:[CommonUtility mapRectForOverlays:self.naviRoute.routePolylines]
                            edgePadding:UIEdgeInsetsMake(RoutePlanningPaddingEdge, RoutePlanningPaddingEdge, RoutePlanningPaddingEdge, RoutePlanningPaddingEdge)
                               animated:YES];
    }else if (_type == CommutingCardTypeDrive){
        [self.optionalPolyLines removeAllObjects];
        MANaviAnnotationType type = MANaviAnnotationTypeDrive;
        [self.driveNaviRoutes removeAllObjects];
        for (AMapPath *path in self.route.paths) {
            MANaviRoute*navi = [MANaviRoute naviRouteForPath:path withNaviType:type showTraffic:YES startPoint:[AMapGeoPoint locationWithLatitude:self.startCoordinate.latitude longitude:self.startCoordinate.longitude] endPoint:[AMapGeoPoint locationWithLatitude:self.destinationCoordinate.latitude longitude:self.destinationCoordinate.longitude]];
            if (self.driveNaviRoutes.count == self.selectedIndex) {
                navi.selected = YES;
            }
            for (id<MAOverlay> poly in navi.routePolylines) {
                if ([poly isKindOfClass:[CustomMAMultiPolyline class]]) {
                    [self.optionalPolyLines addObject:poly];
                }
            }
            [self.driveNaviRoutes addObject:navi];
        }
        MANaviRoute* selectnavi = nil;////把已经选中的路线，全部移除，再添加到最后，就会显示在最上面，
        for (MANaviRoute* navi in self.driveNaviRoutes) {
            if (!navi.selected) {
                [navi addToMapView:self.mapView];
            }else{
                selectnavi = navi;
            }
        }
        [selectnavi addToMapView:self.mapView];
        
        /* 缩放地图使其适应polylines的展示. */
        [self.mapView setVisibleMapRect:[CommonUtility mapRectForOverlays:self.driveNaviRoutes[self.selectedIndex].routePolylines]
                            edgePadding:UIEdgeInsetsMake(RoutePlanningPaddingEdge, RoutePlanningPaddingEdge, RoutePlanningPaddingEdge, RoutePlanningPaddingEdge)
                               animated:YES];
        [self fetchSelectPolyLineAno];
        
    }
}

#pragma mark - event handling
- (void)returnAction {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)updateBottomViewInfo{
    [self.view addSubview:self.bottomView];
    [self updateBottomInfo];
}

- (void)updateBottomInfo{
    NSMutableString *transline = [NSMutableString new];
    if (_type == CommutingCardTypeDrive){
        _seconds =  (self.route.paths[self.selectedIndex]).duration;
    }else{
        NSInteger i = 0;
        for (NSString *nam in _busNams) {
            [transline appendString:nam];
            if (i != _busNams.count - 1) {
                [transline appendString:@"->"];
            }
            i ++;
        }
    }
    long nowtim = [CommonUtility getNowTimeTimestamp];
    long forevertime = nowtim + _seconds;
    NSString *fortime = [CommonUtility getForeverTime:forevertime];
    NSInteger hour = _seconds / 3600;
    NSInteger minite = (_seconds - hour * 3600) / 60;
    _titleLab.text = hour > 0 ? [NSString stringWithFormat:@"全程%ld小时%ld分钟  %@",(long)hour, minite, transline] : [NSString stringWithFormat:@"全程%ld分钟  %@", minite, transline];
    _timeLab.text = [NSString stringWithFormat:@"预计%@到达",fortime];
}

- (void)addBusDepartureStopAnnotation:(NSArray<AMapBusLine*>*)buslines{
    NSInteger i = 0;
    NSMutableArray *visStops = [NSMutableArray new];
    for (AMapBusLine *busLine in buslines) {
        AMapBusStop *departureStop = busLine.departureStop;
        MAPointAnnotation *annotation = [[MAPointAnnotation alloc] init];
        annotation.coordinate = CLLocationCoordinate2DMake(departureStop.location.latitude, departureStop.location.longitude);
        if (i == 0){
            annotation.title = kFirstBusStart;
        }else{
            annotation.title = kElseBusStart;
        }
        [self.mapView addAnnotation:annotation];
        
        MABusStopAnnotation *busAno = [[MABusStopAnnotation alloc] init];
        busAno.coordinate = CLLocationCoordinate2DMake(departureStop.location.latitude, departureStop.location.longitude);
        if ([busLine.name componentsSeparatedByString:@"("].count > 0) {
            NSString *busNam = [[busLine.name componentsSeparatedByString:@"("] firstObject];
            busAno.busName = busNam;
        }
        busAno.stopName = i != 0 ? departureStop.name : [NSString stringWithFormat:@"%@(上车)",departureStop.name];
        [self.mapView addAnnotation:busAno];
        [visStops addObjectsFromArray:busLine.viaBusStops];
        i ++;
    }
    for (AMapBusStop *stop in visStops) {
        MABusStopAnnotation *busAno = [[MABusStopAnnotation alloc] init];
        busAno.coordinate = CLLocationCoordinate2DMake(stop.location.latitude, stop.location.longitude);
        busAno.stopName = stop.name;
        [_busViaStopsAno addObject:busAno];
    }
}

- (UIView *)bottomView{
    if (_bottomView == nil) {
        _bottomView = [[UIView alloc]initWithFrame:CGRectMake(10, self.view.bounds.size.height - 60, self.view.bounds.size.width - 20, 60)];
        _bottomView.backgroundColor = [UIColor whiteColor];
        _bottomView.layer.cornerRadius = 5;
        _bottomView.layer.masksToBounds = YES;
        UILabel *title = [[UILabel alloc]initWithFrame:CGRectMake(20, 0, _bottomView.bounds.size.width - 20, 30)];
        title.textColor = [UIColor blackColor];
        title.font = [UIFont systemFontOfSize:13];
        title.textAlignment = NSTextAlignmentLeft;
        _titleLab = title;
        [_bottomView addSubview:title];
        
        _startBtn = [[UIButton alloc] initWithFrame:CGRectMake(_bottomView.bounds.size.width - 60, 0, 50, 40)];
        _startBtn.backgroundColor = [UIColor blueColor];
        [_startBtn setTitle:@"出发" forState:UIControlStateNormal];
        [_startBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_bottomView addSubview:_startBtn];
        [_startBtn addTarget:self action:@selector(goStart) forControlEvents:UIControlEventTouchUpInside];
        
        _timeLab = [[UILabel alloc]initWithFrame:CGRectMake(20, 30, _bottomView.bounds.size.width - 20, 30)];
        _timeLab.textColor = [UIColor blackColor];
        _timeLab.font = [UIFont systemFontOfSize:13];
        _timeLab.textAlignment = NSTextAlignmentLeft;
        [_bottomView addSubview:_timeLab];
    }
    
    if (_type == CommutingCardTypeDrive){
        _startBtn.hidden = NO;
    }else{
        _startBtn.hidden = YES;
    }
    return _bottomView;
}

- (void)goStart{
    AMapNaviConfig *config = [AMapNaviConfig new];
    config.appName = [CommonUtility getApplicationName];
    config.appScheme = [CommonUtility getApplicationScheme];
    config.destination = self.destinationCoordinate;
    config.strategy = AMapDrivingStrategyFastest;
    
    if (![AMapURLSearch openAMapNavigation:config]) {
        [AMapURLSearch getLatestAMapApp];
    }
}

- (void)fetchSelectPolyLineAno{
    NSInteger current =  (self.route.paths[self.selectedIndex]).duration;
    [self.mapView removeAnnotations:_selectPolyLineAno];
    [_selectPolyLineAno removeAllObjects];
    for (NSInteger i= 0; i < self.optionalPolyLines.count; i ++) {
        if (i != self.selectedIndex) {
            NSInteger kdurtion =  (self.route.paths[i]).duration;
            NSString *tip = @"";
            if (labs(kdurtion - current) < 60) {
                tip = @"时间相近";
            }else{
                tip = kdurtion > current ? [NSString stringWithFormat:@"慢%ld分钟",(kdurtion - current) / 60] : [NSString stringWithFormat:@"快%ld分钟",(current - kdurtion) / 60];
            }
            CLLocationCoordinate2D pp = [CommonUtility fetchPointPolylinePoints:self.optionalPolyLines mapView:self.mapView index:i selected:self.selectedIndex];
            if (CLLocationCoordinate2DIsValid(pp)) {
                MAPointAnnotation *Ano = [[MAPointAnnotation alloc] init];
                Ano.coordinate = pp;
                Ano.title = tip;
                Ano.subtitle = kSelectPolyLine;
                [_selectPolyLineAno addObject:Ano];
            }
        }
    }
    [self.mapView addAnnotations:_selectPolyLineAno];
}

#pragma mark - MAMapViewDelegate
- (void)mapViewRequireLocationAuth:(CLLocationManager *)locationManager
{
    [locationManager requestAlwaysAuthorization];
}

- (void)mapView:(MAMapView *)mapView didChangeUserTrackingMode:(MAUserTrackingMode)mode animated:(BOOL)animated
{
    
}

- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
    if (updatingLocation)
    {
        NSLog(@"userlocation :%@", userLocation.location);
    }
}

- (void)mapView:(MAMapView *)mapView mapDidZoomByUser:(BOOL)wasUserAction{
    if (mapView.zoomLevel > 14) {
        [mapView addAnnotations:_busViaStopsAno];
    }else{
        [mapView removeAnnotations:_busViaStopsAno];
    }
}

- (void)mapView:(MAMapView *)mapView didSingleTappedAtCoordinate:(CLLocationCoordinate2D)coordinate{
    //如果没有备选路线，不处理
    if(!self.optionalPolyLines || self.optionalPolyLines.count <= 1) {
        return;
    }
    __block NSInteger hitIndex = -1;
    [self.optionalPolyLines enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CustomMAMultiPolyline *polyline = (CustomMAMultiPolyline *)obj;
        BOOL hit = [CommonUtility polylineHitTestWithCoordinate:coordinate
                                                        mapView:self.mapView
                                                 polylinePoints:polyline.points
                                                     pointCount:polyline.pointCount
                                                      lineWidth:25];
        if(hit) {
            hitIndex = (NSInteger)idx;
            *stop = YES;
        }
    }];
    if(hitIndex >= 0 && self.selectedIndex != hitIndex) {
        self.selectedIndex = hitIndex;
        [self presentCurrentCourse];
        [self updateBottomInfo];
    }
}

#pragma mark - MAMapViewDelegate
- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id<MAOverlay>)overlay
{
    if ([overlay isKindOfClass:[LineDashPolyline class]])
    {
        MAPolylineRenderer *polylineRenderer = [[MAPolylineRenderer alloc] initWithPolyline:((LineDashPolyline *)overlay).polyline];
        polylineRenderer.lineWidth  = 8;
        polylineRenderer.lineDashType = kMALineDashTypeSquare;
        polylineRenderer.strokeColor = [UIColor redColor];
        
        return polylineRenderer;
    }
    if ([overlay isKindOfClass:[MANaviPolyline class]])
    {
        MANaviPolyline *naviPolyline = (MANaviPolyline *)overlay;
        MAPolylineRenderer *polylineRenderer = [[MAPolylineRenderer alloc] initWithPolyline:naviPolyline.polyline];
        
        polylineRenderer.lineWidth = 10;
        
        if (naviPolyline.type == MANaviAnnotationTypeWalking)
        {
            polylineRenderer.lineDashType = kMALineDashTypeSquare;
            polylineRenderer.strokeColor = self.naviRoute.walkingColor;
        }
        else if (naviPolyline.type == MANaviAnnotationTypeRailway)
        {
            polylineRenderer.strokeColor = self.naviRoute.railwayColor;
        }
        else
        {
            polylineRenderer.strokeColor = self.naviRoute.routeColor;
        }
        return polylineRenderer;
    }
    if ([overlay isKindOfClass:[CustomMAMultiPolyline class]])
    {
        MAMultiTexturePolylineRenderer * polylineRenderer = [[MAMultiTexturePolylineRenderer alloc] initWithMultiPolyline:overlay];
        polylineRenderer.lineJoinType = kMALineJoinRound;

        if (overlay == self.optionalPolyLines[self.selectedIndex]) {
            polylineRenderer.lineWidth = 30;
            polylineRenderer.strokeTextureImages =((CustomMAMultiPolyline*)overlay).mutablePolylineTexturesSelect;
        }else{
            polylineRenderer.lineWidth = 30*0.8;
            polylineRenderer.strokeTextureImages =((CustomMAMultiPolyline*)overlay).mutablePolylineTextures;
        }
        return polylineRenderer;
    }
    return nil;
}

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MAPointAnnotation class]])
    {
        static NSString *routePlanningCellIdentifier = @"RoutePlanningCellIdentifier";
        
        MAAnnotationView *poiAnnotationView = (MAAnnotationView*)[self.mapView dequeueReusableAnnotationViewWithIdentifier:routePlanningCellIdentifier];
        if (poiAnnotationView == nil)
        {
            poiAnnotationView = [[MAAnnotationView alloc] initWithAnnotation:annotation
                                                             reuseIdentifier:routePlanningCellIdentifier];
        }
        
        poiAnnotationView.canShowCallout = YES;
        poiAnnotationView.image = nil;
        if ([annotation isKindOfClass:[MABusStopAnnotation class]]) {
            if ([_busViaStopsAno containsObject:annotation]) {
                static NSString *busPlanningCellIdentifier = @"busPlanningCellIdentifier";
                BusStateAnnotationView *busAnnotationView = (BusStateAnnotationView*)[self.mapView dequeueReusableAnnotationViewWithIdentifier:busPlanningCellIdentifier];
                if (busAnnotationView == nil)
                {
                    busAnnotationView = [[BusStateAnnotationView alloc] initWithAnnotation:annotation
                                                                           reuseIdentifier:busPlanningCellIdentifier];
                }
                busAnnotationView.canShowCallout = NO;
                busAnnotationView.image = [UIImage imageNamed:@"circle"];;
                busAnnotationView.stopName = [(MABusStopAnnotation*)annotation stopName];
                busAnnotationView.busName = @"";
                busAnnotationView.centerOffset = CGPointMake(0, 0);
                return busAnnotationView;
            }else{
                static NSString *busPlanningCellIdentifier = @"busPlanningCellIdentifier1";
                BusStateAnnotationView *busAnnotationView = (BusStateAnnotationView*)[self.mapView dequeueReusableAnnotationViewWithIdentifier:busPlanningCellIdentifier];
                if (busAnnotationView == nil)
                {
                    busAnnotationView = [[BusStateAnnotationView alloc] initWithAnnotation:annotation
                                                                           reuseIdentifier:busPlanningCellIdentifier];
                }
                busAnnotationView.canShowCallout = NO;
                busAnnotationView.image = nil;
                busAnnotationView.busName = [(MABusStopAnnotation*)annotation busName];
                busAnnotationView.stopName = [(MABusStopAnnotation*)annotation stopName];
                busAnnotationView.centerOffset = CGPointMake(60, -40);
                return busAnnotationView;
            }
        }
        if ([annotation.title isEqualToString:kFirstBusStart]) {
            poiAnnotationView.canShowCallout = NO;
            poiAnnotationView.image = [UIImage imageNamed:@"busstate"];
        }else if ([annotation.title isEqualToString:kElseBusStart]){
            poiAnnotationView.canShowCallout = NO;
            poiAnnotationView.image = [UIImage imageNamed:@"transforstop"];
        }else if ([annotation.subtitle isEqualToString:kSelectPolyLine]){
            static NSString *busPlanningCellIdentifier = @"busPlanningCellIdentifier2";
            MAPolyLineSelectAnnotationView *busAnnotationView = (MAPolyLineSelectAnnotationView*)[self.mapView dequeueReusableAnnotationViewWithIdentifier:busPlanningCellIdentifier];
            if (busAnnotationView == nil)
            {
                busAnnotationView = [[MAPolyLineSelectAnnotationView alloc] initWithAnnotation:annotation
                                                                               reuseIdentifier:busPlanningCellIdentifier];
            }
            busAnnotationView.canShowCallout = NO;
            busAnnotationView.image = nil;
            busAnnotationView.tip = ((MAPointAnnotation*)annotation).title;
            return busAnnotationView;
        }
        
        /* 起点. */
        if ([[annotation title] isEqualToString:(NSString*)RoutePlanningViewControllerStartTitle])
        {
            poiAnnotationView.image = [UIImage imageNamed:kAMapNaviRoutePlanPointAnnotationViewStartImageName];
        }
        /* 终点. */
        else if([[annotation title] isEqualToString:(NSString*)RoutePlanningViewControllerDestinationTitle])
        {
            poiAnnotationView.image = [UIImage imageNamed:kAMapNaviRoutePlanPointAnnotationViewEndImageName];
        }
        
        return poiAnnotationView;
    }
    
    return nil;
}
#pragma mark - AMapSearchDelegate
- (void)AMapSearchRequest:(id)request didFailWithError:(NSError *)error
{

}

/* 路径规划搜索回调. */
- (void)onRouteSearchDone:(AMapRouteSearchBaseRequest *)request response:(AMapRouteSearchResponse *)response
{
    if (response.route == nil)
    {
        return;
    }
    if (_type == CommutingCardTypeDrive && response.route.paths == nil)
    {
        return;
    }
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView removeOverlays:self.mapView.overlays];
    [self addDefaultAnnotations];
    [_busNams removeAllObjects];
    self.route = response.route;
    self.transit = self.route.transits.firstObject;
    if (response.count > 0)
    {
        [self presentCurrentCourse];
        if (_type == CommutingCardTypeBus) {
            NSMutableArray <AMapBusLine*>*busLines = [NSMutableArray new];
            
            for (AMapSegment *seg in self.transit.segments) {
                if (seg.buslines.count) {
                    [busLines addObject:seg.buslines.firstObject];
                }
                _seconds += (seg.taxi.duration + seg.walking.duration + seg.buslines.firstObject.duration);
            }
            for (AMapBusLine *busLine in busLines) {
                if ([busLine.name componentsSeparatedByString:@"("].count > 0) {
                    NSString *busNam = [[busLine.name componentsSeparatedByString:@"("] firstObject];
                    [_busNams addObject:busNam];
                }
            }
            [self addBusDepartureStopAnnotation:busLines];
        }else if (_type == CommutingCardTypeDrive){
            _seconds =  (self.route.paths[self.selectedIndex]).duration;
        }
        [self updateBottomViewInfo];
    }
}

- (void)updateLocation:(AMapTip *)tip type:(NSInteger)ktype{
    if (ktype == 0) {
        self.startCoordinate        = CLLocationCoordinate2DMake(tip.location.latitude, tip.location.longitude);
        self.startPOI = tip.name;
        _starLab.text = [NSString stringWithFormat:@"起点:%@",self.startPOI];
    }else{
        self.destinationCoordinate        = CLLocationCoordinate2DMake(tip.location.latitude, tip.location.longitude);
        self.destinationPOI = tip.name;
        _endLab.text = [NSString stringWithFormat:@"终点:%@",self.destinationPOI];
    }
    if (_type == CommutingCardTypeBus) {
        [self searchRoutePlanningBus];
    }else if (_type == CommutingCardTypeDrive){
        [self searchRoutePlanningDrive];
    }
}


@end

