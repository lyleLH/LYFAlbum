//
//  LPImageCutModel.h
//  LYFAlbum
//
//  Created by 六号 on 2019/8/1.
//  Copyright © 2019 李玉枫. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface LPImageCutModel : NSObject

@property (nonatomic,strong) UIImage * image;
@property (nonatomic,assign)CGFloat  scrale;
@property (nonatomic,assign)CGRect  originRect;
@property (nonatomic,assign)CGRect  corpRect;

@end

NS_ASSUME_NONNULL_END
