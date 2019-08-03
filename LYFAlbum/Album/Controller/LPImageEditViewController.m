//
//  LPImageEditViewController.m
//  LYFAlbum
//
//  Created by 六号 on 2019/7/31.
//  Copyright © 2019 李玉枫. All rights reserved.
//

#import "LPImageEditViewController.h"
#import "LYFAlbumViewController.h"
#import "UIView+Additions.h"
#import "LPPhotoCell.h"
#import "LPPhotoEditModel.h"
@interface LPImageEditViewController ()<UICollectionViewDelegate,UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic,strong)NSMutableArray <LPPhotoEditModel *>* dataSource;
@end

@implementation LPImageEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
//    self.currentImageView.image = self.images[0];
   
}


- (NSMutableArray<LPPhotoEditModel *> *)dataSource {
    if(!_dataSource){
        
        _dataSource = [NSMutableArray new];
    }
    return _dataSource;
}

- (void)setImages:(NSMutableArray<UIImage *> *)images {
    [self.dataSource removeAllObjects];
    for (NSInteger i = 0 ; i < images.count; i ++) {
        LPPhotoEditModel * model = [[LPPhotoEditModel alloc] init];
        model.image = images[i];
        [self.dataSource addObject:model];
        
    }
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView reloadData];
    _images = images;
    
}

#pragma mark - delegate
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 10.0f;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.dataSource.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    LPPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LPPhotoCell"
                                                                         forIndexPath:indexPath];
    LPPhotoEditModel *model = self.dataSource[indexPath.row];
    
    cell.photoModel = model;
    
//    cell.blockActionSingleTap = ^{
//        [self hiddenViewAniamtion];
//    };
    return cell;
}


-(void)setCollectionView:(UICollectionView *)collectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
    layout.itemSize = collectionView.bounds.size;
    [collectionView registerClass:[LPPhotoCell class]
     forCellWithReuseIdentifier:NSStringFromClass([LPPhotoCell class])];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    //开启会影响手势
    //        collectionView.pagingEnabled = YES;
    
    _collectionView = collectionView;
}
@end
