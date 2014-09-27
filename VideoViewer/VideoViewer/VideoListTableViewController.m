//
//  VideoListTableViewController.m
//  VideoViewer
//
//  Created by Cameron McCord on 4/16/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import "VideoListTableViewController.h"
#import "Medias+Extras.h"
#import "VideoPlayerViewController.h"
#import "Files+Extras.h"
#import "Languages+Extras.h"
#import "Medias+Extras.h"
#import "VPDaoV1.h"
#import "NSDictionary+SafeJson.h"
#import "UIColor+AppColors.h"

NSString *DATAFILE_FILENAME = @"trainerV0";

@interface VideoListTableViewController ()

@end

@implementation VideoListTableViewController{
    NSArray *medias;
    NSManagedObjectContext *context;
}

-(instancetype)initWithContext:(NSManagedObjectContext *)managedObjectContext{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        context = managedObjectContext;
        [self doUpgradeIfNeeded];
        NSError *error = nil;
        medias = [CoreDataTemplates getListForEntity:@"Medias" withPredicate:nil forContext:context error:&error];
        if (error) {
            DLog(@"error getting medias: %@", error);
            medias = [NSArray new];// so it doesn't break everything
        }
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)doUpgradeIfNeeded {
    // delete the old data
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:DATAFILE_FILENAME ofType:@"json"]];
    if(data != nil){
        
        Files *file = [Files getFileForRemoteUrl:DATAFILE_FILENAME fromContext:context];// used to keep track of which update files have been ran

        if (file == nil) {
            [CoreDataTemplates deleteAllObjectsWithEntityDescription:@"Captions" context:context];
            [CoreDataTemplates deleteAllObjectsWithEntityDescription:@"SubPopups" context:context];
            [CoreDataTemplates deleteAllObjectsWithEntityDescription:@"Popups" context:context];
            [CoreDataTemplates deleteAllObjectsWithEntityDescription:@"Medias" context:context];
            [CoreDataTemplates deleteAllObjectsWithEntityDescription:@"Languages" context:context];
            file = [Files newFileForRemoteFilename:DATAFILE_FILENAME type:FileTypeFromMTC inContext:context];
        }
        
        if(![file.loadStatus isEqualToString:LoadStatusDownloaded]){
        
            NSError *e = nil;
            NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&e];
            
            if (e != nil) {
                [[VPDaoV1 sharedManager] doJsonError:data error:e];
            }else {

                [jsonArray enumerateObjectsUsingBlock:^(id d, NSUInteger idx, BOOL *stop){

                    NSDictionary *lang = d[@"language"];
                    d = [d removeNullValues];
                    Languages *language = [Languages parseLanguageFromDictionary:lang intoContext:context];
                    
                    // media
                    Medias *media = [Medias parseMediaFromDictionary:d forLanguage:language intoContext:context];
                    
                    [language addMediasObject:media];
                    
                    [CoreDataTemplates saveContext:context sender:self];
                }];
                
                [CoreDataTemplates saveContext:context sender:self];
            }
            
            [[VPDaoV1 sharedManager] setLoadStatus:LoadStatusDownloaded forLoadProperties:file];
            [[VPDaoV1 sharedManager] getFilesThatDontExistForDelegate:self inContext:context];
        }
    }
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    
    Medias *media = [medias firstObject];
    if(media)
        [self.navigationItem setTitle:[NSString stringWithFormat:@"%@ Videos", media.language.name]];
    self.navigationController.navigationBar.barTintColor = [UIColor flagGreen];
    self.navigationController.navigationBar.alpha = 1.0f;
    self.navigationController.navigationBar.translucent = YES;

    NSDictionary *attrs = @{NSFontAttributeName:[UIFont systemFontOfSize:22.0f]};
    [[UINavigationBar appearance] setTitleTextAttributes:attrs];
    
    [self.tableView setBackgroundColor:[UIColor lightBlue]];
}

#pragma mark - Table view data source

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    Medias *media = [medias objectAtIndex:[indexPath row]];
    VideoPlayerViewController *vpvc = [[VideoPlayerViewController alloc] initWithContext:context media:media];
    [[self navigationController] pushViewController:vpvc animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [medias count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 75.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"myCell"];
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"myCell"];
        [cell setBackgroundColor:[UIColor lightBlue]];
//        UILabel *cellTitleLabel = [UILabel new];

    }
    
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Medias *media = [medias objectAtIndex:[indexPath row]];
    cell.textLabel.text = media.name;
    [cell.textLabel setFont:[UIFont systemFontOfSize:30.0f]];
}

@end
