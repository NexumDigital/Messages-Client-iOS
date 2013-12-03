//
//  NexumInboxViewController.m
//  Twitter iOS 1.0
//
//  Created by Cristian Castillo on 11/12/13.
//  Copyright (c) 2013 NexumDigital Inc. All rights reserved.
//

#import "NexumInboxViewController.h"

@interface NexumInboxViewController ()

@end

@implementation NexumInboxViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self clearTable];
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    [refresh addTarget:self action:@selector(loadData) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refresh;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [Flurry logPageView];
    [self loadData];
    
    [self.navigationController.tabBarItem setBadgeValue:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushNotification:) name:@"pushNotification" object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"pushNotification" object:nil];
}

#pragma mark - TableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    NexumThreadViewController *nextViewController = [storyboard instantiateViewControllerWithIdentifier:@"ThreadView"];
    nextViewController.thread = [self.threads objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:nextViewController animated:YES];
}

#pragma mark - Table view data source

- (void)loadData {
    if(!self.isLoading){
        self.isLoading = YES;
        if(0 == [self.threads count]){
            self.activityRow.alpha = 1;
        }
        [NexumBackend getThreadsWithAsyncBlock:^(NSDictionary *data) {
            self.threads = data[@"threads_data"];
            dispatch_async(dispatch_get_main_queue(), ^ {
                self.activityRow.alpha = 0;
                [self.tableView reloadData];
                [self.refreshControl endRefreshing];
                self.isLoading = NO;
            });
        }];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.threads count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"InboxCell";
    NexumThreadCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSDictionary *thread = [self.threads objectAtIndex:indexPath.row];
    cell.identifier = thread[@"identifier"];
    [cell reuseCellWithThread:thread];
    [cell performSelector:@selector(loadImagesWithThread:) withObject:thread afterDelay:0.01];
    
    return cell;
}

- (void)clearTable {
    self.threads = [NSMutableArray array];
    self.isLoading = NO;
    [self.tableView reloadData];
}

- (IBAction)searchAction:(UIBarButtonItem *)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    NexumSearchViewController *nextViewController = [storyboard instantiateViewControllerWithIdentifier:@"SearchView"];
    [self.navigationController pushViewController:nextViewController animated:YES];
}

#pragma mark - Push notification

- (void)pushNotification:(NSNotification *)notification{
    NSDictionary *currentAccount = [NexumDefaults currentAccount];
    NSDictionary *data = notification.userInfo;
    if([(NSString *)currentAccount[@"identifier"] isEqualToString:(NSString *)data[@"recipient"]]){
        [self loadData];
    }
}

@end
