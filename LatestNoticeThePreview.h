//
//  LatestNoticeThePreview.h
//  LatestNoticeThePreview
//
//  Created by yangrenxiang on 2016/11/26.
//  Copyright © 2016年 yangrenxiang. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LatestNoticeThePreview : UIView

/** 接收通知名称 */
@property (nonatomic ,copy) NSString *notifName;

//===============自定义属性

/** 最大容量，默认最大限制4个 */
@property (nonatomic ,assign) NSInteger maxCapacity;

/** 每个通知停留时间,默认2s */
@property (nonatomic ,assign) NSTimeInterval standingTime;

/** 文字颜色 */
@property (nonatomic ,strong) UIColor *textColor;

/** 图片(默认是喇叭) */
@property (nonatomic ,copy) NSString *imgName;

/** 字体 */
@property (nonatomic ,strong) UIFont *textFont;


//================Method
#warning 注意在视图已经消失的时候暂停定时器，在视图已经显示的时候继续定时器
/** 暂停定时器 */
- (void)suspendTimer;
/** 继续开启定时器 */
- (void)resumeTimer;

@end
