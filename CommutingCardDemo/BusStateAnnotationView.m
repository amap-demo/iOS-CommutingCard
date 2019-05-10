//
//  BusStateAnnotationView.m
//  MAMapKit_3D_Demo
//
//  Created by zuola on 2019/5/7.
//  Copyright © 2019 Autonavi. All rights reserved.
//

#import "BusStateAnnotationView.h"

#define kWidth  150.f
#define kHeight 40.f

@interface BusStateAnnotationView ()
@property (nonatomic, strong) UILabel *busLabel;
@property (nonatomic, strong) UILabel *stopLabel;

@end
@implementation BusStateAnnotationView

- (void)setBusName:(NSString *)busName{
    self.busLabel.text = busName;
    long width = busName.length * 14;
    self.busLabel.frame = CGRectMake(self.busLabel.frame.origin.x, self.busLabel.frame.origin.y, width, self.busLabel.frame.size.height);
}
    
- (void)setStopName:(NSString *)stopName{
    self.stopLabel.text = stopName;
}
    
#pragma mark - Life Cycle
    
- (id)initWithAnnotation:(id<MAAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
    {
        self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
        
        if (self)
        {
            self.bounds = CGRectMake(0.f, 0.f, kWidth, kHeight);
            self.backgroundColor = [UIColor clearColor];
            
            self.stopLabel = [[UILabel alloc] initWithFrame:CGRectMake(20,0,130,20)];
            self.stopLabel.backgroundColor  = [UIColor clearColor];
            self.stopLabel.textAlignment    = NSTextAlignmentLeft;
            self.stopLabel.textColor        = [UIColor blackColor];
            self.stopLabel.font             = [UIFont boldSystemFontOfSize:12];
            [self addSubview:self.stopLabel];
            
            self.busLabel = [[UILabel alloc] initWithFrame:CGRectMake(20,20,0,20)];
            self.busLabel.backgroundColor  = [[UIColor blueColor] colorWithAlphaComponent:0.4];
            self.busLabel.textAlignment    = NSTextAlignmentCenter;
            self.busLabel.textColor        = [UIColor whiteColor];
            self.busLabel.font             = [UIFont systemFontOfSize:12.f];
            self.busLabel.layer.cornerRadius = self.busLabel.bounds.size.height/2;
            self.busLabel.layer.masksToBounds = YES;
            [self addSubview:self.busLabel];
            self.centerOffset = CGPointMake(60, -40);
        }
        return self;
}

@end
