//
//  BusStateAnnotationView.h
//  MAMapKit_3D_Demo
//
//  Created by zuola on 2019/5/7.
//  Copyright © 2019 Autonavi. All rights reserved.
//

#import <MAMapKit/MAMapKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BusStateAnnotationView : MAAnnotationView
@property (nonatomic, copy) NSString *stopName;
@property (nonatomic, copy) NSString *busName;

@end

NS_ASSUME_NONNULL_END
