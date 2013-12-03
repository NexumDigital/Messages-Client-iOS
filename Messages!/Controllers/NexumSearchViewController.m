//
//  NexumSearchViewController.m
//  Twitter iOS 1.0
//
//  Created by Cristian Castillo on 11/13/13.
//  Copyright (c) 2013 NexumDigital Inc. All rights reserved.
//

#import "NexumSearchViewController.h"

@interface NexumSearchViewController ()

@end

@implementation NexumSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self clearTable];
    self.dataSource = @"suggested";
    [self loadData];
    
    self.searchBar.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [Flurry logPageView];
}

#pragma mark - SearchBar delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self clearTable];
    [self.searchBar resignFirstResponder];
    self.dataSource = @"search";
    self.query = searchBar.text;
    [self loadData];
}

#pragma mark - TableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    NexumProfileViewController *nextViewController = [storyboard instantiateViewControllerWithIdentifier:@"ProfileView"];
    nextViewController.profile = [self.profiles objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:nextViewController animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.profiles count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ProfileCell";
    NexumProfileCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSDictionary *profile = [self.profiles objectAtIndex:indexPath.row];
    cell.identifier = profile[@"identifier"];
    [cell reuseCellWithProfile:profile andRow:indexPath.row];
    [cell performSelector:@selector(loadImagesWithProfile:) withObject:profile afterDelay:0.01];
    if([self.profiles count] < (indexPath.row + 20)){
        if([NSNull null] != (NSNull *)self.page){
            [self loadData];
        }
    }
    
    return cell;
}

#pragma mark - Load data

- (void)loadData {
    if(!self.isLoading){
        self.isLoading = YES;
        self.activityRow.alpha = 1;
        NSString *params = nil;
        if([@"suggested" isEqualToString:self.dataSource]){
            params = [NSString stringWithFormat:@"identifier=%@&page=%@", [NexumDefaults currentAccount][@"identifier"], self.page];
            [NexumBackend getContactsSuggested:params withAsyncBlock:^(NSDictionary *data) {
                self.page = data[@"pagination"][@"next"];
                [self.profiles addObjectsFromArray:data[@"profiles_data"]];
                dispatch_async(dispatch_get_main_queue(), ^ {
                    self.activityRow.alpha = 0;
                    [self.tableView reloadData];
                    self.isLoading = NO;
                });
            }];
        } else if([@"search" isEqualToString:self.dataSource]){
            params = [NSString stringWithFormat:@"identifier=%@&page=%@&query=%@", [NexumDefaults currentAccount][@"identifier"], self.page, self.query];
            [NexumBackend getContactsSearch:params withAsyncBlock:^(NSDictionary *data) {
                self.page = data[@"pagination"][@"next"];
                [self.profiles addObjectsFromArray:data[@"profiles_data"]];
                dispatch_async(dispatch_get_main_queue(), ^ {
                    self.activityRow.alpha = 0;
                    [self.tableView reloadData];
                    self.isLoading = NO;
                });
            }];
        }
    }
}

#pragma mark - Actions

- (IBAction)rowButtonAction:(UIButton *)sender {
    NSMutableDictionary *profile = [[self.profiles objectAtIndex:[(NexumProfileCell *)sender tag]] mutableCopy];
    
    BOOL follower = [profile[@"follower"] boolValue];
    BOOL following = [profile[@"following"] boolValue];
    
    if((follower && following) || follower){
        NSArray *data = [NSArray arrayWithObjects:profile[@"identifier"], [NSString stringWithFormat:@"@%@", profile[@"username"]], nil];
        NSArray *keys = [NSArray arrayWithObjects:@"identifier", @"subtitle", nil];
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
        NexumThreadViewController *nextViewController = [storyboard instantiateViewControllerWithIdentifier:@"ThreadView"];
        nextViewController.thread = [NSDictionary dictionaryWithObjects:data forKeys:keys];
        [self.navigationController pushViewController:nextViewController animated:YES];
    } else {
        [NexumTwitter postStatus:[NSString stringWithFormat:TW_INVITE, profile[@"username"]] onView:self];
    }
}

#pragma mark - Helpers

- (void)clearTable {
    self.profiles = [NSMutableArray array];
    self.isLoading = NO;
    self.page = @"0";
    self.query = @"";
    [self.tableView reloadData];
}

@end
