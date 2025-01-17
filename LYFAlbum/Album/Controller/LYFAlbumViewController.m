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
#import "UIView+Additions.h"
#import "UIImage+Additions.h"
#import "LPImageEditViewController.h"
#import "LPImageCutModel.h"
@interface LYFAlbumViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout,UIGestureRecognizerDelegate>
{
    CGSize orginSize;
  
}

/// 当前正在编辑的那一行
@property (nonatomic, assign) NSInteger nowEditRow;
@property (nonatomic, assign) CGRect latestFrame; // 最终frame
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

/// 最终的图片数组
@property (nonatomic, strong) NSMutableArray<UIImage *> *selectedImages;
/// 选择的， 带有缩放信息的，图片数组，
@property (nonatomic, strong) NSMutableArray<LPImageCutModel *> *editdImages;

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
    PHAsset * rowAsset = self.albumModel.assets[indexPath.row];
    NSInteger seqNumber = [self.albumModel.selectedAssets indexOfObject:rowAsset]+1;
    cell.seqNumber =  seqNumber;
    cell.isSelect = [self.albumModel.selectedAssets containsObject:rowAsset];
    
    cell.asset = rowAsset;
    [cell loadImage:indexPath];
    
   
    __weak typeof(self) weakSelf = self;
    __weak typeof(cell) weakCell = cell;
    cell.selectPhotoAction = ^(PHAsset *asset, NSInteger nowSelectedRow) {
        weakSelf.nowEditRow = nowSelectedRow;
        if([self.albumModel.selectedAssets containsObject:asset]){
            
            [weakSelf.selectedImages removeObjectAtIndex:[weakSelf.albumModel.selectedAssets indexOfObject:asset]];
            [weakSelf.editdImages removeObjectAtIndex:[weakSelf.albumModel.selectedAssets indexOfObject:asset]];
            NSMutableArray * oldAry = [self.albumModel.selectRows copy];
            [weakSelf.albumModel.selectRows removeObject:@(indexPath.row)];
            
            [weakSelf.albumModel.selectedAssets removeObject:asset];
            
            [LYFPhotoManger standardPhotoManger].choiceCount--;
            
            NSMutableArray * indexPathAry = [NSMutableArray new];
            for (NSInteger i = 0; i<   oldAry.count; i++) {
                NSNumber * number = oldAry[i];
                [indexPathAry addObject:[NSIndexPath indexPathForRow:[number integerValue] inSection:0]];
            }
            [self.albumCollectionView reloadItemsAtIndexPaths:indexPathAry];
            weakCell.isSelect = [weakSelf.albumModel.selectedAssets containsObject:asset];
            if([LYFPhotoManger standardPhotoManger].choiceCount == 9){//减少到10张以下，去除遮罩
                [weakSelf.albumCollectionView reloadData];
            }
          
            
        }else {
            if ([LYFPhotoManger standardPhotoManger].maxCount == [LYFPhotoManger standardPhotoManger].choiceCount) {
                return;
            }
            [weakSelf.albumModel.selectRows addObject:@(indexPath.row)];
            weakCell.seqNumber =  [self.albumModel.selectedAssets indexOfObject:asset]+1;
            
            [weakSelf.albumModel.selectedAssets addObject:asset];
            
            [self.albumCollectionView reloadItemsAtIndexPaths:@[indexPath]];
            
            [LYFPhotoManger standardPhotoManger].choiceCount++;
            weakCell.isSelect = [weakSelf.albumModel.selectedAssets containsObject:asset];
            if([LYFPhotoManger standardPhotoManger].choiceCount == 10){//选到第10张，去除遮罩
                
                [weakSelf.albumCollectionView reloadData];
            }
            [weakSelf fetchImageWithAsset:asset imageBlock:^(NSData *imageData) {
                UIImage * selectedImage = [UIImage imageWithData:imageData];
                [weakSelf.selectedImages addObject:selectedImage];
                [weakSelf setCoverImage: selectedImage];
                
                LPImageCutModel * cutModel = [[LPImageCutModel alloc] init];
                
                cutModel.image = selectedImage;
                cutModel.scrale =  selectedImage.size.width/self.currentImagePreview.frame.size.width;
                [self updateModel:cutModel WithView:self.currentImagePreview];
                [weakSelf.editdImages addObject:cutModel];
            }];
        }
    };
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PHAsset *asset = self.albumModel.assets[indexPath.row];
    [self fetchImageWithAsset:asset imageBlock:^(NSData *imageData) {
        [self setCoverImage: [UIImage imageWithData:imageData]];
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
            image = [image fixOrientation:image];
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


#pragma mark - 确认选择去到照片的标签编辑

-(void)confirmAction:(UIButton *)button {
    LPImageEditViewController * editVc = [[LPImageEditViewController alloc] init];
    editVc.images = [self corpedImage];
    [self.navigationController pushViewController:editVc animated:YES];
}


- (NSMutableArray *)corpedImage {
    NSMutableArray * images = [NSMutableArray new];
    for (NSInteger i =0 ; i <self.editdImages.count; i ++) {
        LPImageCutModel * cutModel = self.editdImages[i];
        NSLog(@"%@",NSStringFromCGRect(cutModel.corpRect));
        NSLog(@"图片/视图 比例--%.2f",cutModel.scrale);
        UIImage * newImage =  [cutModel.image getSubImage:cutModel.corpRect];
        [images addObject:newImage];
    }
    return [NSMutableArray arrayWithArray:images];
}



- (void)setCoverImage:(UIImage *)theImage
{
    CGFloat WHScale = theImage.size.width / theImage.size.height;
    
    CGFloat rule = kScreenWidth * WIDTHHEIGHTLIMETSCALE;
    CGSize imageViewSize;
    if (WHScale > 1) {
        CGFloat height = kScreenWidth/WHScale;
        if (height < rule) {
            height = rule;
            imageViewSize = CGSizeMake(height*WHScale, height);
        }else{
            imageViewSize = CGSizeMake(kScreenWidth, height);
        }
    }else{
        CGFloat width = kScreenWidth*WHScale;
        if (width < rule) {
            width = rule;
            imageViewSize = CGSizeMake(width, width/WHScale);
        }else{
            imageViewSize = CGSizeMake(width, kScreenWidth);
        }
    }
    self.currentImagePreview.contentMode = UIViewContentModeScaleToFill;
    [self.currentImagePreview setImage:theImage];
    [self.currentImagePreview setTranslatesAutoresizingMaskIntoConstraints:YES];
    self.currentImagePreview.frame = CGRectMake(0, 0, imageViewSize.width, imageViewSize.height);
    self.currentImagePreview.center = CGPointMake(self.currentImagePreview.superview.width / 2.0f, self.currentImagePreview.superview.height / 2.0f);
    
    orginSize = self.currentImagePreview.frame.size;
}

#pragma mark -- 手势代码实现
// 处理缩放手势
- (void) pinchView:(UIPinchGestureRecognizer *)pinchGestureRecognizer
{
    if (UIGestureRecognizerStateBegan == pinchGestureRecognizer.state ||
        UIGestureRecognizerStateChanged == pinchGestureRecognizer.state) {
        
        // Use the x or y scale, they should be the same for typical zooming (non-skewing)
        float currentScale = [[pinchGestureRecognizer.view.layer valueForKeyPath:@"transform.scale.x"] floatValue];
        
        // Variables to adjust the max/min values of zoom
        float minScale = 1.0;
        float maxScale = 2.0;
        float zoomSpeed = .5;
        
        float deltaScale = pinchGestureRecognizer.scale;
        
        // You need to translate the zoom to 0 (origin) so that you
        // can multiply a speed factor and then translate back to "zoomSpace" around 1
        deltaScale = ((deltaScale - 1) * zoomSpeed) + 1;
        
        // Limit to min/max size (i.e maxScale = 2, current scale = 2, 2/2 = 1.0)
        //  A deltaScale is ~0.99 for decreasing or ~1.01 for increasing
        //  A deltaScale of 1.0 will maintain the zoom size
        deltaScale = MIN(deltaScale, maxScale / currentScale);
        deltaScale = MAX(deltaScale, minScale / currentScale);
        
        CGAffineTransform zoomTransform = CGAffineTransformScale(pinchGestureRecognizer.view.transform, deltaScale, deltaScale);
        pinchGestureRecognizer.view.transform = zoomTransform;
        
        // Reset to 1 for scale delta's
        //  Note: not 0, or we won't see a size: 0 * width = 0
        pinchGestureRecognizer.scale = 1;
    }

//    UIView *view = pinchGestureRecognizer.view;
//    if (pinchGestureRecognizer.state == UIGestureRecognizerStateBegan || pinchGestureRecognizer.state == UIGestureRecognizerStateChanged) {
//        view.transform = CGAffineTransformScale(view.transform, pinchGestureRecognizer.scale, pinchGestureRecognizer.scale);
//        pinchGestureRecognizer.scale = 1;
//
//    }
    UIView *view = pinchGestureRecognizer.view;
    LPImageCutModel * cutModel ;
    PHAsset * rowAsset = self.albumModel.assets[self.nowEditRow];
    if([self.albumModel.selectedAssets containsObject:rowAsset]){
        NSInteger index = [self.albumModel.selectedAssets indexOfObject:rowAsset];
        cutModel = [self.editdImages objectAtIndex:index];
    }
    
    if(cutModel){
        cutModel.scrale = cutModel.image.size.width/view.frame.size.width;
        NSLog(@"缩放比例- %.2f- %.2f ",cutModel.scrale,pinchGestureRecognizer.scale);
    }
    if (pinchGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        CGFloat rule = view.width > view.height?view.width:view.height;
        CGFloat min = kScreenWidth * WIDTHHEIGHTLIMETSCALE;
        if (rule < kScreenWidth) {
            CGFloat width;
            CGFloat height;
            if (view.width > view.height) {
                width = kScreenWidth;
                height = kScreenWidth * view.height / view.width;
            }else{
                height = kScreenWidth;
                width = kScreenWidth * view.width / view.height;
            }
            
            if (width < min || height < min) {
                width = orginSize.width;
                height = orginSize.height;
            }
            
            [UIView animateWithDuration:0.2 animations:^{
                view.width = width;
                view.height = height;
                view.center = CGPointMake(view.superview.width / 2.0, view.superview.height / 2.0);
                if(cutModel){
                    [self updateModel:cutModel WithView:view];
                    
                }
            }];
        }else{
            CGFloat width = view.width;
            CGFloat height = view.height;
            if (width > SCALEMAX * orginSize.width || height > SCALEMAX * orginSize.height) {
                height = SCALEMAX * orginSize.height;
                width = SCALEMAX * orginSize.width;
            }
            if (width < min || height < min) {
                width = orginSize.width;
                height = orginSize.height;
            }
            CGPoint center = view.center;
            if (width < kScreenWidth) {
                center.x = view.superview.width / 2.0;
            }
            if (height < kScreenWidth) {
                center.y = view.superview.height / 2.0;
            }
            
            [UIView animateWithDuration:0.2 animations:^{
                view.width = width;
                view.height = height;
                view.center = center;
                if(cutModel){
                    [self updateModel:cutModel WithView:view];
                    
                }
            }];
        }
        
    }
}



// 处理拖拉手势
- (void) panView:(UIPanGestureRecognizer *)panGestureRecognizer
{
    
    UIView *view = panGestureRecognizer.view;
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan || panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [panGestureRecognizer translationInView:view.superview];
        [view setCenter:(CGPoint){view.center.x + translation.x, view.center.y + translation.y}];
        [panGestureRecognizer setTranslation:CGPointZero inView:view.superview];
    }
    LPImageCutModel * cutModel ;
    PHAsset * rowAsset = self.albumModel.assets[self.nowEditRow];
    if([self.albumModel.selectedAssets containsObject:rowAsset]){
        NSInteger index = [self.albumModel.selectedAssets indexOfObject:rowAsset];
        cutModel = [self.editdImages objectAtIndex:index];
    }
    if(cutModel){
        cutModel.scrale = cutModel.image.size.width/view.frame.size.width;
    }
    
    if (panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint center = view.center;
        
        if (view.width <= kScreenWidth)
        {
            center.x = kScreenWidth / 2.0f;
        }else{
            if (view.originX > 0) {
                center.x -= view.originX;
            }else{
                if ((kScreenWidth - center.x) > view.width / 2.0f) {
                    center.x += (kScreenWidth - center.x) - view.width / 2.0f;
                }
            }
        }
        
        if (view.height <= kScreenWidth) {
            center.y = kScreenWidth / 2.0f;
        }else{
            if (view.originY > 0) {
                center.y -= view.originY;
            }else{
                if((kScreenWidth - center.y) > view.height / 2.0f){
                    CGFloat offSet =(kScreenWidth - center.y)-view.height / 2.0f;
                    center.y += offSet;
                }
            }
        }
        [UIView animateWithDuration:0.2 animations:^{
            view.center = center;
            self.latestFrame = view.frame;
            if(cutModel){
                [self updateModel:cutModel WithView:view];
                
            }
        }];
        
    }
    
}

- (void)updateModel:(LPImageCutModel * )cutModel WithView:(UIView *)view {
    
    CGFloat imgX;
    CGFloat imgY;
    CGFloat imgW;
    CGFloat imgH;
    
    if (view.width <= kScreenWidth)
    {
        imgX = 0;
        imgW = view.width;
    }else{
        imgX = -view.originX;
        imgW = kScreenWidth;
    }
    
    if (view.height <= kScreenWidth) {
        imgY = 0;
        imgH = view.height;
    }else{
        imgY = - view.originY;
        imgH = kScreenWidth;
    }
    CGFloat scraled = cutModel.scrale;
    CGRect rect = CGRectMake(imgX*scraled, imgY*scraled, imgW*scraled, imgH*scraled);
    cutModel.corpRect = rect;
    NSLog(@"%@",NSStringFromCGRect(cutModel.corpRect ));
}
#pragma mark - Get方法

- (UIImageView *)currentImagePreview {
    if(!_currentImagePreview){
        _currentImagePreview = [[UIImageView alloc] initWithFrame:self.previewBgView.frame];
        
        [_currentImagePreview setUserInteractionEnabled:YES];
        [_currentImagePreview setMultipleTouchEnabled:YES];
        
        // 旋转手势
        //    UIRotationGestureRecognizer *rotationGestureRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotateView:)];
        //    [view addGestureRecognizer:rotationGestureRecognizer];
        
        // 缩放手势
        UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchView:)];
        pinchGestureRecognizer.delegate =self;
        [_currentImagePreview addGestureRecognizer:pinchGestureRecognizer];
        
        // 移动手势
        UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panView:)];
        panGestureRecognizer.delegate =self;
        panGestureRecognizer.maximumNumberOfTouches = 1;
        [panGestureRecognizer setCancelsTouchesInView:NO];
        [_currentImagePreview addGestureRecognizer:panGestureRecognizer];
        
        
        
        [self.previewBgView addSubview:_currentImagePreview];
    }
    return _currentImagePreview;
}

-(UIView *)previewBgView {
    if(!_previewBgView){
        _previewBgView = [[UIView alloc] initWithFrame:CGRectMake(0, 64, kScreenWidth, kScreenWidth)];
        _previewBgView.backgroundColor = [UIColor whiteColor];
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
        
        _albumCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.previewBgView.frame), kScreenWidth, kScreenHeight- CGRectGetHeight(self.previewBgView.frame)-64) collectionViewLayout:layout];
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

- (NSMutableArray<UIImage *> *)selectedImages{
    if(!_selectedImages){
        _selectedImages = [NSMutableArray new];
        }
    return _selectedImages;
}
- (NSMutableArray<UIImage *> *)editdImages{
    if(!_editdImages){
        _editdImages = [NSMutableArray new];
    }
    return _editdImages;
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (![gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] && ![otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        return YES;
    }
    
    return NO;
}

@end
