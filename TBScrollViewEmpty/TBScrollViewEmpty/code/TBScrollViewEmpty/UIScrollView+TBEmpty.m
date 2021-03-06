//
//  UIScrollView+TBEmpty.m
//  TBCoreData8
//
//  Created by hanchuangkeji on 2017/11/3.
//  Copyright © 2017年 hanchuangkeji. All rights reserved.
//

#import "UIScrollView+TBEmpty.h"
#import <objc/runtime.h>

@implementation NSObject (TBEmpty)

/**
 交换实例方法

 @param method1 目标函数
 @param method2 源函数
 */
+ (void)exchangeInstanceMethod1:(SEL)method1 method2:(SEL)method2
{
    method_exchangeImplementations(class_getInstanceMethod(self, method1), class_getInstanceMethod(self, method2));
}

@end


@implementation UIScrollView (TBEmpty)

static const char TBShowEmptyViewStoreKey = '\0'; // 是否显示emptyView的key
static const char TBSystemReloadKey = '\0'; // 系统布局tableView调用reloadData的key
static const char TBEmptyViewKey = '\0'; // emptyView的key
static const char TBEmptyDelegateKey = '\0'; // 代理的key
static const char TBNetworkReachabilityKey = '\0'; // 网络对象的key


static const BOOL tb_isShowEmptyViewDefalut = YES; // 默认显示emptyView

static const BOOL tb_isShowImagetView = YES; // 显示顶部图片

static const BOOL tb_isShowTitleLB = YES; // 显示标题

static const BOOL tb_isShowDetailLB = YES; // 显示详情

static const BOOL tb_isShowButton = NO; // 显示按钮

- (TBNetworkReachability *)internetReachability {
    
    TBNetworkReachability *internetReachability = objc_getAssociatedObject(self, &TBNetworkReachabilityKey);
    if (internetReachability == nil) {
        // 创建并且存储
        internetReachability = [TBNetworkReachability reachabilityForInternetConnection];
        objc_setAssociatedObject(self, &TBNetworkReachabilityKey,
                                 internetReachability, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [internetReachability startNotifier];
    }
    return internetReachability;
}

// 代理
- (void)setTb_EmptyDelegate:(id<TBSrollViewEmptyDelegate>)tb_EmptyDelegate {
    
    // 存储
    objc_setAssociatedObject(self, &TBEmptyDelegateKey,
                             tb_EmptyDelegate, OBJC_ASSOCIATION_ASSIGN);
}

- (id<TBSrollViewEmptyDelegate>)tb_EmptyDelegate {
    return objc_getAssociatedObject(self, &TBEmptyDelegateKey);
}

- (void)createEmptyView {
    
    CGRect rect = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
    UIView *emptyView = nil;
    
    if ([self.tb_EmptyDelegate respondsToSelector:@selector(tb_emptyView:network:)]) {
        
        // 自定义的emptyView
        emptyView = [self.tb_EmptyDelegate tb_emptyView:self network:[self networkdStatus]];
        [self addSubview:emptyView];
        [self bringSubviewToFront:emptyView];
        
        // 没有设置frame
        if (CGRectIsEmpty(emptyView.frame) || CGRectIsEmpty(emptyView.frame)) {
            emptyView.frame = rect;
        }
        
    }else {
        
        // 框架默认的
        TBEmptyView *tbEmptyView = [[TBEmptyView alloc] initWithFrame:rect];
        tbEmptyView.delegate = self;
        emptyView = tbEmptyView;
        [self addSubview:emptyView];
        [self bringSubviewToFront:emptyView];
        
        // 设置图片top
        if ([self.tb_EmptyDelegate respondsToSelector:@selector(tb_emptyImage:network:)]) {
            UIImage *image = [self.tb_EmptyDelegate tb_emptyImage:self network:[self networkdStatus]];
            if (image) {
                [tbEmptyView setImageView:image network:[self networkdStatus] isShow:YES];
            }
        }else {
            
            // 默认图片
            [tbEmptyView setImageView:nil network:[self networkdStatus] isShow:tb_isShowImagetView];
        }
        
        // 设置标题文字
        if ([self.tb_EmptyDelegate respondsToSelector:@selector(tb_emptyTitle:network:)]) {
            NSAttributedString *attributedText = [self.tb_EmptyDelegate tb_emptyTitle:self  network:[self networkdStatus]];
            if (attributedText) {
                [tbEmptyView setTitltString:attributedText network:[self networkdStatus] isShow:YES];
            } else if ([attributedText.string isEqualToString:@""]) {
                [tbEmptyView setTitltString:nil network:[self networkdStatus] isShow:YES];
            }
        }else {
            [tbEmptyView setTitltString:nil network:[self networkdStatus] isShow:tb_isShowTitleLB];
        }
        
        // 设置详情文字
        if ([self.tb_EmptyDelegate respondsToSelector:@selector(tb_emptyDetial:network:)]) {
            NSAttributedString *attributedText = [self.tb_EmptyDelegate tb_emptyDetial:self network:[self networkdStatus]];
            if (attributedText) {
                [tbEmptyView setDetailString:attributedText network:[self networkdStatus] isShow:YES];
            }else if ([attributedText.string isEqualToString:@""]) {
                [tbEmptyView setDetailString:nil network:[self networkdStatus] isShow:YES];
            }
        }else {
            [tbEmptyView setDetailString:nil network:[self networkdStatus] isShow:tb_isShowDetailLB];
        }
        
        // 设置按钮文字
        if ([self.tb_EmptyDelegate respondsToSelector:@selector(tb_emptyButtonTitle:network:)]) {
            NSAttributedString *attributedText = [self.tb_EmptyDelegate tb_emptyButtonTitle:self network:[self networkdStatus]];
            if (attributedText) {
                [tbEmptyView setButonTitle:attributedText network:[self networkdStatus] isShow:YES];
            }else if ([attributedText.string isEqualToString:@""]) {
                [tbEmptyView setButonTitle:nil network:[self networkdStatus] isShow:YES];
            }
        }else {
            [tbEmptyView setButonTitle:nil network:[self networkdStatus] isShow:tb_isShowButton];
        }
    }
    
    // emptyView设置key
    objc_setAssociatedObject(self, &TBEmptyViewKey,
                             emptyView, OBJC_ASSOCIATION_ASSIGN);
    
    // 设置偏移量
    if ([self.tb_EmptyDelegate respondsToSelector:@selector(tb_emptyViewOffset:network:)]) {
        CGPoint point = [self.tb_EmptyDelegate tb_emptyViewOffset:self network:[self networkdStatus]];
        CGRect newRect = CGRectMake(emptyView.frame.origin.x + point.x, emptyView.frame.origin.y + point.y, emptyView.frame.size.width, emptyView.frame.size.height);
        emptyView.frame = newRect;
    }
    
}

- (void)addOrMoveEmptyView {
    
    // 存储首次运行reloadData, 系统表格LayoutSubViews
    if (!objc_getAssociatedObject(self, &TBSystemReloadKey)) {
        // 存储
        objc_setAssociatedObject(self, &TBSystemReloadKey,
                                 @(YES), OBJC_ASSOCIATION_ASSIGN);
        return;
    }
    
    // 是否启动emptyView
    if ([self.tb_EmptyDelegate respondsToSelector:@selector(tb_showEmptyView:network:)]) {
        
        BOOL showEmptyView = [self.tb_EmptyDelegate tb_showEmptyView:self network:[self networkdStatus]];
        
        // 存储
        objc_setAssociatedObject(self, &TBShowEmptyViewStoreKey,
                                 @(showEmptyView), OBJC_ASSOCIATION_ASSIGN);
        if (!showEmptyView) {
            return;
        }
    } else if (!tb_isShowEmptyViewDefalut) {
        return;
    };
    
    UIView *emptyView = objc_getAssociatedObject(self, &TBEmptyViewKey);
    // 移除
    if (emptyView && [self tb_totalDataCount] > 0) {
        [emptyView removeFromSuperview];
        objc_setAssociatedObject(self, &TBEmptyViewKey,
                                 nil, OBJC_ASSOCIATION_ASSIGN);
    }else if ([self tb_totalDataCount] <= 0){
        
        // 移除旧的生成新的
        if (emptyView) {
            [emptyView removeFromSuperview];
            objc_setAssociatedObject(self, &TBEmptyViewKey,
                                     nil, OBJC_ASSOCIATION_ASSIGN);
        }
        
        [self createEmptyView];
    }
}

#pragma mark - 获取Data数量
- (NSInteger)tb_totalDataCount
{
    NSInteger totalCount = 0;
    if ([self isKindOfClass:[UITableView class]]) {
        UITableView *tableView = (UITableView *)self;
        
        for (NSInteger section = 0; section<tableView.numberOfSections; section++) {
            totalCount += [tableView numberOfRowsInSection:section];
        }
    } else if ([self isKindOfClass:[UICollectionView class]]) {
        UICollectionView *collectionView = (UICollectionView *)self;
        
        for (NSInteger section = 0; section<collectionView.numberOfSections; section++) {
            totalCount += [collectionView numberOfItemsInSection:section];
        }
    }
    return totalCount;
}

#pragma mark <TBEmptyViewDelegate>
-(void)btnClick:(UIButton *)btn {
    
    if ([self.tb_EmptyDelegate respondsToSelector:@selector(tb_emptyButtonClick:network:)]) {
        [self.tb_EmptyDelegate tb_emptyButtonClick:btn network:[self networkdStatus]];
    }
}

#pragma mark <网络状态>
- (TBNetworkStatus)networkdStatus {
    TBNetworkStatus netStatus = [[self internetReachability] currentReachabilityStatus];
    switch (netStatus)
    {
        case TBNetworkStatusNotReachable:
            break;
        case TBNetworkStatusReachableViaWWAN:        {
            break;
        }
        case TBNetworkStatusReachableViaWiFi:        {
            break;
        }
    }
    return netStatus;
}

@end

@implementation UITableView (TBEmpty)

+ (void)load
{
    [self exchangeInstanceMethod1:@selector(reloadData) method2:@selector(tb_reloadData)];
}

- (void)tb_reloadData
{
    [self tb_reloadData];
    
    [self addOrMoveEmptyView];
}
@end

@implementation UICollectionView (TBEmpty)

+ (void)load
{
    [self exchangeInstanceMethod1:@selector(reloadData) method2:@selector(tb_reloadData)];
}

- (void)tb_reloadData
{
    [self tb_reloadData];
    
    [self addOrMoveEmptyView];
}

@end
