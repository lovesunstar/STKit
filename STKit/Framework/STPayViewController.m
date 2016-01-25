//
//  STPayViewController.m
//  STKit
//
//  Created by SunJiangting on 14-9-3.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STPayViewController.h"
#import "STResourceManager.h"

@interface _STPayPlatformItem : NSObject

@property(nonatomic, assign) STPayPlatform platform;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *detail;
@property(nonatomic, copy) UIImage *image;
@property(nonatomic, assign) BOOL selected;

+ (_STPayPlatformItem *)itemWithPlatform:(STPayPlatform)platform;
@end

@implementation _STPayPlatformItem

+ (_STPayPlatformItem *)itemWithPlatform:(STPayPlatform)platform {
    _STPayPlatformItem *platformItem;
    switch (platform) {
    case STPayPlatformAliPay:
        platformItem = [[_STPayPlatformItem alloc] init];
        platformItem.title = @"支付宝支付";
        platformItem.detail = @"推荐支付宝用户使用";
        platformItem.image = [STResourceManager imageWithResourceID:STImageResourcePayPlatformAliID];
        platformItem.selected = NO;
        break;
    case STPayPlatformWXPay:
        platformItem = [[_STPayPlatformItem alloc] init];
        platformItem.title = @"微信支付";
        platformItem.detail = @"微信支付，半小时内返券";
        platformItem.image = [STResourceManager imageWithResourceID:STImageResourcePayPlatformWXID];
        platformItem.selected = NO;
    default:
        break;
    }
    return platformItem;
}
@end

@interface _STPayPlatformCell : UITableViewCell

@property(nonatomic, strong) UIImageView *logoImageView;
@property(nonatomic, strong) UILabel *nameLabel;
@property(nonatomic, strong) UILabel *detailLabel;
@property(nonatomic, strong) UIButton *selectedView;

@property(nonatomic, strong) _STPayPlatformItem *platformItem;

@end

const CGSize STPlatformCellDefaultSize = {320, 60};
@implementation _STPayPlatformCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.frame = CGRectMake(0, 0, STPlatformCellDefaultSize.width, STPlatformCellDefaultSize.height);
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.logoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 10, 40, 40)];
        self.logoImageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [self addSubview:self.logoImageView];

        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(70, 10, 200, 20)];
        self.nameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.nameLabel.textColor = [UIColor blackColor];
        self.nameLabel.font = [UIFont systemFontOfSize:17.];
        [self addSubview:self.nameLabel];

        self.detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(70, 35, 200, 15)];
        self.detailLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.detailLabel.textColor = [UIColor grayColor];
        self.detailLabel.font = [UIFont systemFontOfSize:14.];
        [self addSubview:self.detailLabel];

        self.selectedView = [UIButton buttonWithType:UIButtonTypeCustom];
        self.selectedView.frame = CGRectMake(STPlatformCellDefaultSize.width - 50, 15, 30, 30);
        self.selectedView.autoresizingMask =
            UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [self.selectedView setImage:[STResourceManager imageWithResourceID:STImageResourcePayDeselectedID] forState:UIControlStateNormal];
        [self.selectedView setImage:[STResourceManager imageWithResourceID:STImageResourcePaySelectedID] forState:UIControlStateSelected];
        self.selectedView.userInteractionEnabled = NO;
        [self addSubview:self.selectedView];
    }
    return self;
}

- (void)setPlatformItem:(_STPayPlatformItem *)platformItem {
    self.nameLabel.text = platformItem.title;
    self.detailLabel.text = platformItem.detail;
    self.logoImageView.image = platformItem.image;
    self.selectedView.selected = platformItem.selected;
    _platformItem = platformItem;
}

@end

@interface STPayViewController () <UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, strong) STPayItem *payItem;

@property(nonatomic, strong) UITableView *tableView;

@property(nonatomic, strong) NSMutableArray *supportedPlatforms;

@property(nonatomic, strong) STPayHandler payHandler;

@end

@implementation STPayViewController

- (instancetype)initWithPayItem:(STPayItem *)payItem handler:(STPayHandler)payHandler {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.payItem = payItem;
        self.payHandler = payHandler;
        self.supportedPlatforms = [NSMutableArray arrayWithCapacity:2];
        [self _buildPayPlatforms];
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [self initWithPayItem:nil handler:NULL];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = @"订单确认";

    self.navigationItem.leftBarButtonItem = [UIBarButtonItem backBarButtonItemWithTarget:self action:@selector(_backViewController:)];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];

    UIView *tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 60)];
    self.tableView.tableFooterView = tableFooterView;

    UIButton *payButton = [UIButton buttonWithType:UIButtonTypeCustom];
    payButton.frame = CGRectMake(10, 10, CGRectGetWidth(tableFooterView.bounds) - 20, 40);
    payButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    payButton.layer.borderColor = [UIColor st_colorWithRGB:0xFF8400].CGColor;
    payButton.backgroundColor = [UIColor st_colorWithRGB:0xFF8400];
    [payButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [payButton setTitle:@"确认支付" forState:UIControlStateNormal];
    [tableFooterView addSubview:payButton];
}

- (void)_backViewController:(id)sender {
    if (self.payHandler) {
        self.payHandler(self.payItem, STPayResultCancelled, nil);
    }
    if (self.st_navigationController) {
        if (self.st_navigationController.viewControllers.count > 1) {
            [self.st_navigationController popViewControllerAnimated:YES];
        } else {
            [self.st_navigationController dismissViewControllerAnimated:YES completion:NULL];
        }
    } else if (self.navigationController) {
        if (self.navigationController.viewControllers.count > 1) {
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
        }
    } else {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1 + (self.supportedPlatforms.count > 0);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 2;
    } else if (section == 1) {
        return self.supportedPlatforms.count;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 5;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 45;
    } else if (indexPath.section == 1) {
        return STPlatformCellDefaultSize.height;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *infoIdentifier = @"infoIdentifier";
    static NSString *payIdentifier = @"payIdentifier";
    UITableViewCell *tableViewCell;
    if (indexPath.section == 0) {
        tableViewCell = [tableView dequeueReusableCellWithIdentifier:infoIdentifier];
        if (!tableViewCell) {
            tableViewCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:infoIdentifier];
        }
        if (indexPath.row == 0) {
            tableViewCell.textLabel.text = @"数量";
            tableViewCell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", (long)self.payItem.count];
            tableViewCell.detailTextLabel.textColor = [UIColor blackColor];
        } else if (indexPath.row == 1) {
            tableViewCell.textLabel.text = @"总价";
            NSString *price = [NSString stringWithFormat:@"￥%.2f", self.payItem.amount / 100.0];
            price = [price stringByReplacingOccurrencesOfString:@".00" withString:@""];

            tableViewCell.detailTextLabel.text = price;
            tableViewCell.detailTextLabel.textColor = [UIColor blackColor];
        }
    } else {
        _STPayPlatformCell *platformCell = [tableView dequeueReusableCellWithIdentifier:payIdentifier];
        if (!platformCell) {
            platformCell = [[_STPayPlatformCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:payIdentifier];
        }
        _STPayPlatformItem *payPlatformItem = self.supportedPlatforms[indexPath.row];
        platformCell.platformItem = payPlatformItem;
        tableViewCell = platformCell;
    }
    return tableViewCell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return self.payItem.title;
    } else if (section == 1) {
        return @"选择支付方式";
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.section == 1) {
        _STPayPlatformItem *item = self.supportedPlatforms[indexPath.row];
        [self.supportedPlatforms enumerateObjectsUsingBlock:^(_STPayPlatformItem *obj, NSUInteger idx, BOOL *stop) { obj.selected = NO; }];
        item.selected = YES;
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark - PrivateMethod
- (void)_buildPayPlatforms {
    [self.supportedPlatforms removeAllObjects];
    if (self.payItem.supportedPlatforms & STPayPlatformAliPay) {
        _STPayPlatformItem *platform = [_STPayPlatformItem itemWithPlatform:STPayPlatformAliPay];
        if (self.payItem.defaultPlatform == STPayPlatformAliPay) {
            platform.selected = YES;
        }
        if (platform) {
            [self.supportedPlatforms addObject:platform];
        }
    }

    if (self.payItem.supportedPlatforms & STPayPlatformWXPay) {
        _STPayPlatformItem *platform = [_STPayPlatformItem itemWithPlatform:STPayPlatformWXPay];
        if (self.payItem.defaultPlatform == STPayPlatformWXPay) {
            platform.selected = YES;
        }
        if (platform) {
            [self.supportedPlatforms addObject:platform];
        }
    }
}

@end
