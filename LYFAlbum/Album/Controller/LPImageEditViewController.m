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
    self.currentImageView.image = self.images[0];
   
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
