//
//  LYFAlbumViewController.h
//  LYFAlbum
//
//  Created by 李玉枫 on 2018/12/6.
//  Copyright © 2018 李玉枫. All rights reserved.
//

#import <UIKit/UIKit.h>
#define SCALEMAX 2.0 //放缩的最大值
#define WIDTHHEIGHTLIMETSCALE 3.0/4.0 //限制得到图片的 长宽比例


#define kScreenWidth  [[UIScreen mainScreen] bounds].size.width
#define kScreenHeight [[UIScreen mainScreen] bounds].size.height

typedef void(^LYFAlbumViewControllerConfirmAction)(void);

@interface LYFAlbumViewController : UIViewController

/// 确定事件
@property (nonatomic, copy) LYFAlbumViewControllerConfirmAction confirmAction;

@end
