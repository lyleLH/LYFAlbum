//
//  LYFAlbumViewController.m
//  LYFAlbum
//
//  Created by 李玉枫 on 2018/12/6.
//  Copyright © 2018 李玉枫. All rights reserved.
//

#import "LYFAlbumViewController.h"
#import "LYFAlbumCollectionViewCell.h"
#import "LYFAlbumModel.h"
#import "LYFPhotoManger.h"
#import "LYFAlbumView.h"
#import "LYFPhotoModel.h"

#define kScreenWidth  [[UIScreen mainScreen] bounds].size.width
#define kScreenHeight [[UIScreen mainScreen] bounds].size.height

@interface LYFAlbumViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>


/// 显示相册按钮
@property (nonatomic, strong) UIButton *showAlbumButton;
/// 取消按钮
@property (nonatomic, strong) UIButton *cancelButton;
/// 确定按钮
@property (nonatomic, strong) UIButton *confirmButton;

/// 预览图
@property (nonatomic, strong) UIImageView *currentImagePreview;
/// 预览图背景视图
@property (nonatomic,strong)UIView *previewBgView;

/// 相册列表
@property (nonatomic, strong) UICollectionView *albumCollectionView;
/// 相册数组
@property (nonatomic, strong) NSMutableArray<LYFAlbumModel *> *assetCollectionList;
/// 当前相册
@property (nonatomic, strong) LYFAlbumModel *albumModel;

@end

static NSString *albumCollectionViewCell = @"LYFAlbumCollectionViewCell";

@implementation LYFAlbumViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupViewController];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - 设置控制器
-(void)setupViewController {
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:self.cancelButton];
    self.navigationItem.leftBarButtonItem = backItem;
    
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 180, 45)];
    self.navigationItem.titleView = titleView;
    [titleView addSubview:self.showAlbumButton];
    
    UIBarButtonItem *confirmItem = [[UIBarButtonItem alloc] initWithCustomView:self.confirmButton];
    self.navigationItem.rightBarButtonItem = confirmItem;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self getThumbnailImages];
    
    __weak typeof(self) weakSelf = self;
    [LYFPhotoManger standardPhotoManger].choiceCountChange = ^(NSInteger choiceCount) {
        weakSelf.confirmButton.enabled = choiceCount != 0;
        if (choiceCount == 0) {
            [weakSelf.confirmButton setTitle:@"确定" forState:UIControlStateNormal];
            [weakSelf.confirmButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        } else {
            [weakSelf.confirmButton setTitle:[NSString stringWithFormat:@"确定%ld/%ld", [LYFPhotoManger standardPhotoManger].choiceCount, [LYFPhotoManger standardPhotoManger].maxCount] forState:UIControlStateNormal];
            [weakSelf.confirmButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        }
    };
}

#pragma mark - 获得所有的自定义相簿
-(void)getThumbnailImages {
    self.assetCollectionList = [NSMutableArray array];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // 获得个人收藏相册
        PHFetchResult<PHAssetCollection *> *favoritesCollection = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumFavorites options:nil];
        // 获得相机胶卷
        PHFetchResult<PHAssetCollection *> *assetCollections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
        // 获得全部相片
        PHFetchResult<PHAssetCollection *> *cameraRolls = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
        
        for (PHAssetCollection *collection in cameraRolls) {
            LYFAlbumModel *model = [[LYFAlbumModel alloc] init];
            model.collection = collection;
            
            if (![model.collectionNumber isEqualToString:@"0"]) {
                [weakSelf.assetCollectionList addObject:model];
            }
        }
        
        for (PHAssetCollection *collection in favoritesCollection) {
            LYFAlbumModel *model = [[LYFAlbumModel alloc] init];
            model.collection = collection;
            
            if (![model.collectionNumber isEqualToString:@"0"]) {
                [weakSelf.assetCollectionList addObject:model];
            }
        }
        
        for (PHAssetCollection *collection in assetCollections) {
            LYFAlbumModel *model = [[LYFAlbumModel alloc] init];
            model.collection = collection;
            
            if (![model.collectionNumber isEqualToString:@"0"]) {
                [weakSelf.assetCollectionList addObject:model];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.albumModel = weakSelf.assetCollectionList.firstObject;
        });
    });
}

#pragma mark - Set方法
-(void)setAlbumModel:(LYFAlbumModel *)albumModel {
    _albumModel = albumModel;
    
    [self.showAlbumButton setTitle:albumModel.collectionTitle forState:UIControlStateNormal];
    
    [self.albumCollectionView reloadData];
}

#pragma mark - UICollectionViewDataSource / UICollectionViewDelegate
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.albumModel.assets.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    LYFAlbumCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:albumCollectionViewCell forIndexPath:indexPath];
    
    cell.row = indexPath.row;
    cell.asset = self.albumModel.assets[indexPath.row];
    [cell loadImage:indexPath];
    cell.isSelect = [self.albumModel.selectRows containsObject:@(indexPath.row)];
    
    __weak typeof(self) weakSelf = self;
    __weak typeof(cell) weakCell = cell;
    cell.selectPhotoAction = ^(PHAsset *asset) {
        BOOL isReloadCollectionView = NO;
        if ([weakSelf.albumModel.selectRows containsObject:@(indexPath.row)]) {
            [weakSelf.albumModel.selectRows removeObject:@(indexPath.row)];
            [LYFPhotoManger standardPhotoManger].choiceCount--;
            
            isReloadCollectionView = [LYFPhotoManger standardPhotoManger].choiceCount == 9;
        } else {
            if ([LYFPhotoManger standardPhotoManger].maxCount == [LYFPhotoManger standardPhotoManger].choiceCount) {
                return;
            }
            
            [weakSelf.albumModel.selectRows addObject:@(indexPath.row)];
            [LYFPhotoManger standardPhotoManger].choiceCount++;
            isReloadCollectionView = [LYFPhotoManger standardPhotoManger].choiceCount == 10;
        }
        
        if (isReloadCollectionView) {
            [weakSelf.albumCollectionView reloadData];
        } else {
            weakCell.isSelect = [weakSelf.albumModel.selectRows containsObject:@(indexPath.row)];
        }
    };
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PHAsset *asset = self.albumModel.assets[indexPath.row];
    [self fetchImageWithAsset:asset imageBlock:^(NSData *imageData) {
        self.currentImagePreview.image = [UIImage imageWithData:imageData];
    }];
    
}

/**
 通过资源获取图片的数据
 
 @param mAsset 资源文件
 @param imageBlock 图片数据回传
 */
- (void)fetchImageWithAsset:(PHAsset*)mAsset imageBlock:(void(^)(NSData*))imageBlock {
    
    [[PHImageManager defaultManager] requestImageDataForAsset:mAsset options:nil resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        
        if (orientation != UIImageOrientationUp) {
            UIImage* image = [UIImage imageWithData:imageData];
            // 尽然弯了,那就板正一下
            image = [self fixOrientation:image];
            // 新的 数据信息 （不准确的）
            imageData = UIImageJPEGRepresentation(image, 0.5);
        }
        
        // 直接得到最终的 NSData 数据
        if (imageBlock) {
            imageBlock(imageData);
        }
        
    }];
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake((kScreenWidth - 20.f) / 3.f, (kScreenWidth - 20.f) / 3.f);
}

-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(5, 5, 5, 5);
}

#pragma mark - 点击事件
-(void)showAlbum:(UIButton *)button {
    button.selected = !button.selected;
    
    [LYFAlbumView showAlbumView:self.assetCollectionList navigationBarMaxY:CGRectGetMaxY(self.navigationController.navigationBar.frame) complete:^(LYFAlbumModel *albumModel) {
        if (albumModel) {
            self.albumModel = albumModel;
        }
        
        button.selected = !button.selected;
    }];
}

-(void)backAction:(UIButton *)button {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)confirmAction:(UIButton *)button {
    if ([LYFPhotoManger standardPhotoManger].choiceCount > 0) {
        button.enabled = NO;
        NSMutableArray<LYFPhotoModel *> *photoList = [NSMutableArray array];
        
        __weak typeof(self) weakSelf = self;
        for (LYFAlbumModel *albumModel in self.assetCollectionList) {
            for (NSNumber *row in albumModel.selectRows) {
                if (row.integerValue < albumModel.assets.count) {
                    LYFPhotoModel *photoModel = [[LYFPhotoModel alloc] init];
                    
                    __weak typeof(photoModel) weakPhotoModel = photoModel;
                    photoModel.getPictureAction = ^{
                        [photoList addObject:weakPhotoModel];
                        
                        if (photoList.count == [LYFPhotoManger standardPhotoManger].choiceCount) {
                            button.enabled = YES;
                            
                            [LYFPhotoManger standardPhotoManger].photoModelList = photoList;
                            if (weakSelf.confirmAction) {
                                weakSelf.confirmAction();
                            }
                            
                            [weakSelf dismissViewControllerAnimated:YES completion:nil];
                        }
                    };
                    
                    photoModel.asset = albumModel.assets[row.integerValue];
                }
            }
        }
    }
}

#pragma mark - Get方法

- (UIImageView *)currentImagePreview {
    if(!_currentImagePreview){
        _currentImagePreview = [[UIImageView alloc] initWithFrame:self.previewBgView.frame];
        [self.previewBgView addSubview:_currentImagePreview];
    }
    return _currentImagePreview;
}

-(UIView *)previewBgView {
    if(!_previewBgView){
        _previewBgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenWidth)];
        _previewBgView.backgroundColor = [UIColor lightGrayColor];
        [self.view addSubview:_previewBgView];
    }
    return _previewBgView;
}

-(UICollectionView *)albumCollectionView {
    if (!_albumCollectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.minimumLineSpacing = 5.f;
        layout.minimumInteritemSpacing = 5.f;
        
        _albumCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.previewBgView.frame), kScreenWidth, kScreenHeight- CGRectGetHeight(self.previewBgView.frame)) collectionViewLayout:layout];
        _albumCollectionView.delegate = self;
        _albumCollectionView.dataSource = self;
        _albumCollectionView.backgroundColor = [UIColor whiteColor];
        _albumCollectionView.scrollEnabled = YES;
        _albumCollectionView.alwaysBounceVertical = YES;
        
        [_albumCollectionView registerClass:[LYFAlbumCollectionViewCell class] forCellWithReuseIdentifier:albumCollectionViewCell];
        
        [self.view addSubview:_albumCollectionView];
    }
    
    return _albumCollectionView;
}

-(UIButton *)showAlbumButton {
    if (!_showAlbumButton) {
        _showAlbumButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _showAlbumButton.frame = CGRectMake(0, 0, 180, 45);
        [_showAlbumButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_showAlbumButton setImage:[UIImage imageNamed:@"photo_select_down"] forState:UIControlStateNormal];
        [_showAlbumButton setImage:[UIImage imageNamed:@"photo_select_up"] forState:UIControlStateSelected];
        _showAlbumButton.titleLabel.font = [UIFont systemFontOfSize:15];
        _showAlbumButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 10.f);
        [_showAlbumButton addTarget:self action:@selector(showAlbum:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _showAlbumButton;
}

-(UIButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelButton.frame = CGRectMake(0, 0, 50, 50);
        [_cancelButton setTitle:@"取消" forState:UIControlStateNormal];
        _cancelButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [_cancelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(backAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _cancelButton;
}

-(UIButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_confirmButton addTarget:self action:@selector(confirmAction:) forControlEvents:UIControlEventTouchUpInside];
        _confirmButton.enabled = NO;
        _confirmButton.frame = CGRectMake(0, 0, 80, 45);
        _confirmButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        _confirmButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [_confirmButton setTitle:@"确定" forState:UIControlStateNormal];
        [_confirmButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    }
    
    return _confirmButton;
}



/** 解决旋转90度问题 */
- (UIImage *)fixOrientation:(UIImage *)aImage
{
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

@end
