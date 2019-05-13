//
//  SettingViewController.h
//  CommutingCardDemo
//
//  Created by zuola on 2019/5/12.
//  Copyright © 2019 zuola. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommonDefine.h"
#import <AMapSearchKit/AMapSearchKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SettingViewControllerDelegate <NSObject>
- (void)updateLocation:(AMapTip *)tip type:(NSInteger)ktype;
@end

@interface SettingViewController : UIViewController
@property (nonatomic, assign)NSInteger type;
@property (nonatomic, weak)id<SettingViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
