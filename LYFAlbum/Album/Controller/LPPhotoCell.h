//
//  LPPhotoCell.h
//  LYFAlbum
//
//  Created by 六号 on 2019/8/3.
//  Copyright © 2019 李玉枫. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LPPhotoEditModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface LPPhotoCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;

@property (nonatomic,strong)LPPhotoEditModel * photoModel ;

@end

NS_ASSUME_NONNULL_END
