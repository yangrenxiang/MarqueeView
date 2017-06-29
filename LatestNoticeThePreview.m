//
//  LatestNoticeThePreview.m
//  LatestNoticeThePreview
//
//  Created by yangrenxiang on 2016/11/26.
//  Copyright © 2016年 yangrenxiang. All rights reserved.
//

#import "LatestNoticeThePreview.h"
@interface LatestNoticeThePreview () <UIScrollViewDelegate>

// 通知消息数据
@property (nonatomic ,strong) NSMutableArray *dates;
// GCD定时器
@property (nonatomic ,strong) dispatch_source_t timer;
// 左侧显示的图片
@property (nonatomic ,weak) UIImageView *leftImgV;
// 展示最新通知消息的view
@property (nonatomic ,weak) UIScrollView *notifPreview;
// 中间的label
@property (nonatomic ,weak) UILabel *centerLb;
// 下部的label
@property (nonatomic ,weak) UILabel *bottomLb;
// 当前显示的是第几个数据
@property (nonatomic ,assign) NSInteger curRow;

@end

@implementation LatestNoticeThePreview {
    
    dispatch_semaphore_t semaphore;
    CGRect _frame;
    BOOL _isValid;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if ([super initWithFrame:frame]) {
        _frame = frame;
        
        //=========默认属性初始化=============//
        self.dates = [[NSMutableArray alloc] init];
        semaphore = dispatch_semaphore_create(1);
        _curRow = 0;
        _textFont = [UIFont systemFontOfSize:15.0];
        _textColor = [UIColor redColor];
        _maxCapacity = 10;
        _standingTime = 3;
        [self notifPreview];
        self.alpha = 0.0;
        self.hidden = YES;
    }
    return self;
}

#pragma mark - 接收通知
- (void)receiveNotification:(NSNotification *)notify {
    if (self.hidden) {
        self.hidden = NO;
        [UIView animateWithDuration:1.0 animations:^{
           
            self.alpha = 1.0;
        }];
    }
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    [self.dates addObject:notify.userInfo[@"descrip"]];
    [self reload];
    dispatch_semaphore_signal(semaphore);
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y / self.bounds.size.height == 1) {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        _curRow ++;
        
        if (self.dates.count > _maxCapacity) {
            //当前消息缓存池已满，直接将已经过期的消息删除
            [self.dates removeObjectAtIndex:0];
            _curRow --;
        }
        //还原
        [self.notifPreview setContentOffset:CGPointZero];
        [self reload];
        if (_curRow >= self.dates.count - 1){
            _curRow = 0;
            [self.dates removeAllObjects];
            [self suspendTimer];
            [UIView animateWithDuration:1.0 delay:_standingTime options:0 animations:^{
                self.alpha = 0;
            } completion:^(BOOL finished) {
                self.hidden = YES;
            }];
        }
        dispatch_semaphore_signal(semaphore);
    }
}

#pragma mark - CustomMethod
- (void)reload {
    if (!self.dates.count) return;
    self.centerLb.text = self.dates[_curRow];
    self.bottomLb.text = self.dates[(_curRow + 1) % self.dates.count];
    
    if (!_timer) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_standingTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self startTimer];
        });
    }else {
        [self resumeTimer];
    }
}

- (UIScrollView *)notifPreview {
    
    if (!_notifPreview) {
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, _frame.size.width, _frame.size.height)];
        scrollView.delegate = self;
        scrollView.contentSize = CGSizeMake(0, 2 * _frame.size.height);
        scrollView.userInteractionEnabled = NO;
        scrollView.backgroundColor = [UIColor grayColor];
        [self addSubview:scrollView];
        _notifPreview = scrollView;
        for (NSInteger i = 0; i < 2; i++) {
            
            UILabel *Lb = [[UILabel alloc] initWithFrame:CGRectMake(0, scrollView.bounds.size.height * i, scrollView.bounds.size.width, scrollView.bounds.size.height)];
            Lb.textColor = self.textColor;
            Lb.font = self.textFont;
            [scrollView addSubview:Lb];
            
            if (i == 0) self.centerLb = Lb;
            else self.bottomLb = Lb;
        }
    }
    return _notifPreview;
}

- (void)setNotifName:(NSString *)notifName {
    
    _notifName = notifName;
    //接收通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:_notifName object:nil];
}

- (dispatch_source_t)timer {
    if (!_timer) {
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(0, 0));
        dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, _standingTime * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(_timer, ^{
            
            [self.notifPreview setContentOffset:CGPointMake(0, 1 * _frame.size.height) animated:YES];
        });
        dispatch_resume(_timer);
    }
    return _timer;
}
//开启定时器
- (void)startTimer {
    if (self.dates.count <= 1) return;
    if (_timer) return;
    [self timer];
    _isValid = YES;
}
//继续定时器
- (void)resumeTimer {

    if (!_timer) return;
    if (_isValid) return;
    dispatch_resume(_timer);
    _isValid = YES;
}
//暂停定时器
- (void)suspendTimer {
    if (!_timer) return;
    if (!_isValid) return;
    dispatch_suspend(_timer);
    _isValid = NO;
}

#pragma mark - dealloc
- (void)dealloc {
    if (_timer) {
        dispatch_source_cancel(_timer);
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
