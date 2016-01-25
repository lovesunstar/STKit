//
//  STTableViewController.m
//  STKit
//
//  Created by SunJiangting on 14-5-14.
//  Copyright (c) 2014年 SunJiangting. All rights reserved.
//

#import "STTableViewController.h"
#import "STTableView.h"
#import "STResourceManager.h"
#import <Foundation/Foundation.h>

@interface STTableViewController ()

@property(nonatomic, assign) UITableViewStyle tableViewStyle;

@property(nonatomic, strong) STScrollDirector *tableDirector;

@property(nonatomic, weak) STRefreshControl *refreshControl;
@property(nonatomic, weak) STPaginationControl *paginationControl;

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) UIView *tableFooterView;

@property(nonatomic, assign) BOOL displayingEmptyView;
@property(nonatomic, assign) BOOL displayingExceptionView;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@end

@implementation STTableViewController

+ (Class)modelClass {
    return Nil;
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.tableViewStyle = style;
        self.model = [[[[self class] modelClass] alloc] init];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [self initWithStyle:UITableViewStylePlain];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.model = [[[[self class] modelClass] alloc] init];
    }
    return self;
}

- (void)setModel:(STModel *)model {
    model.delegate = self;
    [super setModel:model];
}

- (void)loadView {
    [super loadView];
    self.tableView = [[STTableView alloc] initWithFrame:self.view.bounds style:self.tableViewStyle];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.tableView];

    self.tableDirector.scrollView = self.tableView;
    [self.tableDirector.refreshControl addTarget:self action:@selector(refreshData) forControlEvents:UIControlEventValueChanged];
    [self.tableDirector.paginationControl addTarget:self action:@selector(loadMoreData) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = self.tableDirector.refreshControl;
    self.paginationControl = self.tableDirector.paginationControl;

    self.dataZeroView = [[STAccessoryView alloc] init];
    self.dataZeroView.imageView.image = [STResourceManager imageWithResourceID:STImageResourceAccessoryDataZeroID];
    self.dataZeroView.textLabel.text = @"暂时没有数据";

    self.dataExceptionView = [[STAccessoryView alloc] init];
    self.dataExceptionView.imageView.image = [STResourceManager imageWithResourceID:STImageResourceAccessoryDataZeroID];
    self.dataExceptionView.textLabel.text = @"网络异常，请稍后重试";
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.model loadDataFromCache];
}

- (void)refreshDataUsingRefreshControl {
    [self.tableDirector.refreshControl beginRefreshing];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)reloadData {
    /// self.table reloadData
    [self.tableView reloadData];
}

- (void)refreshData {
    [self.model loadDataFromRemote];
    [self setTableConditionView:nil];
}

- (void)loadMoreData {
    [self.model loadDataFromPagination];
}

- (void)modelWillStartLoadData:(STModel *)model {
    self.tableFooterView = self.tableView.tableFooterView;
}

- (void)modelDidFinishLoadData:(STModel *)model {
    if (model.sourceType == STModelDataSourceTypeRemote) {
        [self.tableDirector.refreshControl endRefreshing];
    }
    if ([model numberOfDataItems] == 0) {
        // TODO:展示空数据
        [self reloadData];
        if ([self shouldDisplayDataZeroView:self.dataZeroView]) {
            [self displayDataZeroView:self.dataZeroView];
        }
    } else {
        [self setTableConditionView:nil];
        if ([model hasNextPage]) {
            self.tableView.tableFooterView = self.paginationControl;
            self.tableDirector.paginationControl.paginationState = STPaginationControlStateNormal;
        } else {
            self.tableDirector.paginationControl.paginationState = STPaginationControlStateReachedEnd;
        }

        self.tableView.scrollEnabled = YES;
        [self reloadData];
    }
}

- (void)modelDidFailedLoadData:(STModel *)model {
    if (model.sourceType == STModelDataSourceTypePagination) {
        // TODO: 加载更多失败
        // 将footer展示为加载更多按钮，点击之后加载更多
        self.tableDirector.paginationControl.paginationState = STPaginationControlStateFailed;
    } else {
        [self.tableDirector.refreshControl endRefreshing];
        // TODO: 服务器访问 失败，展示异常
        if ([self shouldDisplayDataExceptionView:self.dataExceptionView error:model.error]) {
            [self displayDataExceptionView:self.dataExceptionView error:model.error];
        }
    }
}

- (void)modelDidCancelLoadData:(STModel *)model {
    self.tableDirector.paginationControl.paginationState = STPaginationControlStateNormal;
}

- (BOOL)shouldDisplayDataZeroView:(UIView *)zeroView {
    return YES;
}

- (BOOL)shouldDisplayDataExceptionView:(UIView *)exceptionView error:(NSError *)error {
    return YES;
}

- (void)setTableConditionView:(UIView *)conditionView {
    CGSize contentSize = self.tableView.contentSize;
    if (self.tableView.tableFooterView) {
        contentSize.height -= self.tableView.tableFooterView.height;
    }
    CGFloat height = self.view.height - contentSize.height;
    if ([conditionView isKindOfClass:[STAccessoryView class]]) {
        height = MAX(height, STAccessoryViewMinimumSize.height);
    }

    CGRect frame = self.view.bounds;
    frame.size.height = height;
    conditionView.frame = frame;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL selector = NSSelectorFromString(@"setConditionView:");
    if ([self.tableView respondsToSelector:selector]) {
        [self.tableView performSelector:selector withObject:conditionView];
    }
#pragma clang diagnostic pop
}
- (void)displayDataZeroView:(UIView *)zeroView {
    [self setTableConditionView:zeroView];
    self.tableView.scrollEnabled = self.scrollableWhenExcepted;
}

- (void)displayDataExceptionView:(UIView *)exceptionView error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setTableConditionView:exceptionView];
        self.tableView.scrollEnabled = self.scrollableWhenExcepted;
    });
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.model numberOfDataItems];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

#pragma mark - Getter
- (STScrollDirector *)tableDirector {
    if (!_tableDirector) {
        _tableDirector = [[STScrollDirector alloc] init];
        [_tableDirector setTitle:@"下拉可以刷新" forState:STScrollDirectorStateRefreshNormal];
        [_tableDirector setTitle:@"松手开始刷新" forState:STScrollDirectorStateRefreshReachedThreshold];
        [_tableDirector setTitle:@"正在刷新..." forState:STScrollDirectorStateRefreshLoading];
        [_tableDirector setTitle:@"加载更多" forState:STScrollDirectorStatePaginationLoading];
        [_tableDirector setTitle:@"正在加载更多" forState:STScrollDirectorStatePaginationLoading];
        [_tableDirector setTitle:@"重新加载" forState:STScrollDirectorStatePaginationFailed];
        [_tableDirector setTitle:@"没有更多了" forState:STScrollDirectorStatePaginationReachedEnd];
    }
    return _tableDirector;
}

@end
