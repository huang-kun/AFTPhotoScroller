//
//  AFTViewController.m
//  AFTPhotoScroller
//
//  Created by huangkun on 01/23/2017.
//  Copyright (c) 2017 huangkun. All rights reserved.
//

#import "AFTViewController.h"
#import "AFTPagingBaseViewController.h"
#import "AFTNetworkPagingViewController.h"

@interface AFTViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@end

@implementation AFTViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"AFTPhotoScrollerDemo";
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:UITableViewCell.self forCellReuseIdentifier:@"Cell"];

    [self.view addSubview:self.tableView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.textLabel.text = self.items[indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *name = self.itemClasses[indexPath.row];
    NSString *title = self.items[indexPath.row];
    
    Class cls = NSClassFromString(name);
    if (!cls) {
        return;
    }
    
    AFTPagingBaseViewController *vc = [cls new];
    if ([vc isKindOfClass:AFTPagingBaseViewController.self]) {
        AFTPagingBaseViewController *bvc = (AFTPagingBaseViewController *)vc;
        bvc.title = title;
        if (![vc isKindOfClass:AFTNetworkPagingViewController.self]) {
            bvc.images = self.landscapeImages;
        }
        [self presentViewController:bvc animated:YES completion:nil];
    }
}

#pragma mark - Rotation

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Helper

- (NSArray *)items {
    return @[ @"Regular pages",
              @"Vertical pages",
              @"Custom pages",
              @"Network pages" ];
}

- (NSArray *)itemClasses {
    return @[ @"AFTNormalPagingViewController",
              @"AFTVerticalPagingViewController",
              @"AFTCustomPagingViewController",
              @"AFTNetworkPagingViewController" ];
}

- (NSArray *)landscapeImages {
    NSMutableArray *images = [NSMutableArray new];
    for (int i = 0; i < 14; i++) {
        NSString *name = [NSString stringWithFormat:@"image%03d", i];
        NSString *path = [NSBundle.mainBundle pathForResource:name ofType:@"jpg"];
        UIImage *image = [UIImage imageWithContentsOfFile:path];
        [images addObject:image];
    }
    return images.copy;
}

@end
