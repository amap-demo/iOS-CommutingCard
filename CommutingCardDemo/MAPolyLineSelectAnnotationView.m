//
//  MAPolyLineSelectAnnotationView.m
//  MAMapKit_3D_Demo
//
//  Created by zuola on 2019/5/8.
//  Copyright © 2019 Autonavi. All rights reserved.
//

#import "MAPolyLineSelectAnnotationView.h"
#define kWidth  150.f
#define kHeight 30.f

@interface MAPolyLineSelectAnnotationView ()
@property (nonatomic, strong) UILabel *tipLabel;
    
@end

@implementation MAPolyLineSelectAnnotationView
    
-(void)setTip:(NSString *)tip{
    self.tipLabel.text = tip;
    long width = tip.length * 16;
    long left = (kWidth - width)/2;
    self.tipLabel.frame = CGRectMake(left, self.tipLabel.frame.origin.y, width, self.tipLabel.frame.size.height);
}

- (id)initWithAnnotation:(id<MAAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
    {
        self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
        
        if (self)
        {
            self.bounds = CGRectMake(0.f, 0.f, kWidth, kHeight);
            self.backgroundColor = [UIColor clearColor];
            self.tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(20,0,0,30)];
            self.tipLabel.backgroundColor  = [[UIColor whiteColor] colorWithAlphaComponent:1];
            self.tipLabel.textAlignment    = NSTextAlignmentCenter;
            self.tipLabel.textColor        = [UIColor blackColor];
            self.tipLabel.font             = [UIFont systemFontOfSize:14.f];
            self.tipLabel.layer.cornerRadius = self.tipLabel.bounds.size.height/2;
            self.tipLabel.layer.masksToBounds = YES;
            self.tipLabel.userInteractionEnabled = NO;
            [self addSubview:self.tipLabel];
        }
        return self;
    }
    

@end
