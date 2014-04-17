//
//  VideoListTableViewController.m
//  VideoViewer
//
//  Created by Cameron McCord on 4/16/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import "VideoListTableViewController.h"
#import "Medias.h"
#import "VideoPlayerViewController.h"


@interface VideoListTableViewController ()

@end

@implementation VideoListTableViewController

-(instancetype)initWithContext:(NSManagedObjectContext *)context{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.managedObjectContext = context;
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    [[VPDaoV1 sharedManager] getMedias:self forContext:self.managedObjectContext];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Delegate methods

-(void)gotMedias{
    [self reloadData];
}

-(void)reloadData{
    NSError *error = nil;
    if (![[self fetchedResultsController] performFetch:&error]) {
        NSLog(@"Error fetching results: %@, %@", error, [error userInfo]);
        exit(-1);// fail
    }
    [[self tableView] reloadData];
}

-(void)errorGettingMedias{
    self.alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was an error getting medias" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    [self.alert dismissWithClickedButtonIndex:buttonIndex animated:YES];
}

#pragma mark - Table view data source

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    Medias *media = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSLog(@"%@", media);
    VideoPlayerViewController *vpvc = [[VideoPlayerViewController alloc] initWithContext:self.managedObjectContext media:media];
    [[self navigationController] pushViewController:vpvc animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
//    return [[self.fetchedResultsController sections] count];
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.fetchedResultsController.fetchedObjects count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"myCell"];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"myCell"];
    
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
    // Configure the cell to show the book's title
    Medias *media = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = media.name;
}



-(NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    // Create and configure a fetch request with the Book entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Medias" inManagedObjectContext:self.managedObjectContext];
    
    [fetchRequest setEntity:entity];
    
    // Create the sort descriptors array.
    NSSortDescriptor *authorDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSArray *sortDescriptors = @[authorDescriptor];
    [fetchRequest setSortDescriptors:sortDescriptors];
    [fetchRequest setFetchBatchSize:20];
    // Create and initialize the fetch results controller.
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Root"];// nil was @"author"
    _fetchedResultsController.delegate = self;
    
//    NSFetchRequest *req = [[NSFetchRequest alloc] init];
//    [req setPredicate:[NSPredicate predicateWithFormat:@"id == 1048"]];
//    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Medias" inManagedObjectContext:_managedObjectContext];
//    [req setEntity:entity];
//    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
//    [req setSortDescriptors:[NSArray arrayWithObject:sort]];
//    [req setFetchBatchSize:20];
//    
//    NSFetchedResultsController *theFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:req managedObjectContext:_managedObjectContext sectionNameKeyPath:nil cacheName:nil];
//    self.fetchedResultsController = theFetchedResultsController;
//    _fetchedResultsController.delegate = self;
//    
    return _fetchedResultsController;
    
//    return _fetchedResultsController;
}

@end
