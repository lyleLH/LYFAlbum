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

@interface LPImageEditViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *currentImageView;

@end

@implementation LPImageEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    LYFPhotoModel * model = self.images[0];
    [self setPreviewImage:model.highDefinitionImage];
   
}



- (void)setPreviewImage:(UIImage *) theImage{
    
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
//    self.currentImageView.contentMode = UIViewContentModeScaleToFill;
    self.currentImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.currentImageView setImage:theImage];
    [self.currentImageView setTranslatesAutoresizingMaskIntoConstraints:YES];
     self.currentImageView.frame = CGRectMake(0, 0, imageViewSize.width, imageViewSize.height);
    self.currentImageView.center = CGPointMake(self.currentImageView.superview.width / 2.0f, self.currentImageView.superview.height / 2.0f);
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
