本工程为基于高德地图iOS SDK进行封装，实现通勤卡片。
## 前述 ##
- [高德官网申请Key](http://lbs.amap.com/dev/#/).
- 阅读[开发指南](http://lbs.amap.com/api/ios-sdk/summary/).
- 工程基于iOS 3D地图SDK实现

## 功能描述 ##
基于3D地图SDK，实现通勤卡片demo。

## 核心类/接口 ##
| 类    | 接口  | 说明   | 版本  |
| -----|:-----:|:-----:|:-----:|
| AMapSearchAPI	| - (void)AMapDrivingRouteSearch:(AMapDrivingRouteSearchRequest *)request;; | 驾车路径规划查询接口 | v4.0.0 |
| AMapSearchAPI | - (void)AMapTransitRouteSearch:(AMapTransitRouteSearchRequest *)request;; | 公交路径规划查询接口 | v4.0.0 |


## 核心难点 ##

`Objective-C`

```

/* 公交路径规划查询接口 */
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

/*驾车路径规划查询接口*/
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
```

`Swift`

```
/* 公交路径规划查询接口 */
    func searchRoutePlanningBus() -> Void {
        let startAnnotation = MAPointAnnotation.init()
        startAnnotation.coordinate = startCoordinate
        startAnnotation.title = RoutePlanningViewControllerStartTitle
        let destinationAnnotation = MAPointAnnotation.init()
        destinationAnnotation.coordinate = destinationCoordinate
        destinationAnnotation.title = RoutePlanningViewControllerDestinationTitle
        mapView.addAnnotation(startAnnotation)
        mapView.addAnnotation(destinationAnnotation)
    }
    /*驾车路径规划查询接口*/
    func searchRoutePlanningDrive() -> Void {
        let navi = AMapDrivingRouteSearchRequest.init()
        navi.requireExtension = true
        navi.strategy = 10
        navi.origin = AMapGeoPoint.location(withLatitude: CGFloat(startCoordinate!.latitude), longitude: CGFloat(startCoordinate!.longitude))
        navi.destination = AMapGeoPoint.location(withLatitude: CGFloat(destinationCoordinate!.latitude), longitude: CGFloat(destinationCoordinate!.longitude))
        search.aMapDrivingRouteSearch(navi)
    }

```
