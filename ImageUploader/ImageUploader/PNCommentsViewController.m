//
//  PNCommentsViewController.m
//  Potion
//
//  Created by Bradley Griffith on 8/2/13.
//  Copyright (c) 2013 Bradley Griffith. All rights reserved.
//

#import "PNCommentsViewController.h"
#import "Comment.h"
#import "PNCoreDataController.h"
#import "PNCommentRetriever.h"
#import "NSDateFormatter+stringConversions.h"
#import "SVProgressHUD.h"
#import "Post.h"
#import "User.h"
#import "PNSentComment.h"
#import "PNRecievedComment.h"

@interface PNCommentsViewController ()
@property (nonatomic, retain)NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong)PNCommentRetriever *commentRetriever;
@property (nonatomic, strong)User *currentUser;
@property (nonatomic, strong)PNSentComment *cellPrototype;
@end

@implementation PNCommentsViewController

@synthesize fetchedResultsController = _fetchedResultsController;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _currentUser = [User currentUser];
    
    _commentRetriever = [[PNCommentRetriever alloc] init];
    
    // Load prototype table cell. Since both sent and recieved comments are essentially the same
    // in terms of height, we can use the same prototype to model either.
    static NSString *CellIdentifier = @"SentCommentViewCell";
    [self.tableView registerNib:[UINib nibWithNibName:@"PNSentCommentXib" bundle:nil] forCellReuseIdentifier:CellIdentifier];
    _cellPrototype = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    [self syncComments];
    [self fetchRecords];
}

-(void)viewWillDisappear:(BOOL)animated {
    [NSFetchedResultsController deleteCacheWithName:@"CommentsCache"];
}

- (IBAction)refreshCommentList:(id)sender {
    [self syncComments];
}

- (void)syncComments {
    [self replaceRefreshButtonWithActivityIndicator];
    
    [_commentRetriever retrieveNewOrUpdatedCommentForPostWithId:[_parentPost.postID stringValue] success:^{
        [self removeActivityIndicatorFromRefreshButton];
    } failure:^(NSString *errorMessage) {
        // TODO: Handle failure;
        [self removeActivityIndicatorFromRefreshButton];
        [SVProgressHUD showErrorWithStatus:errorMessage];
    }];
}

- (void)replaceRefreshButtonWithActivityIndicator {
    // TODO: add 'started updating' style to refresh button.
}

- (void)removeActivityIndicatorFromRefreshButton {
    // TODO: add 'finished updating' style to refresh button.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id  sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Comment *comment = [_fetchedResultsController objectAtIndexPath:indexPath];
    
    if ([comment isSentByUser]){
        static NSString *CellIdentifier = @"SentCommentViewCell";
        [_tableView registerNib:[UINib nibWithNibName:@"PNSentCommentXib" bundle:nil] forCellReuseIdentifier:CellIdentifier];
        PNSentComment *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setComment:comment];
        return cell;
    }
    else {
        static NSString *CellIdentifier = @"RecievedCommentViewCell";
        [_tableView registerNib:[UINib nibWithNibName:@"PNRecievedCommentXib" bundle:nil] forCellReuseIdentifier:CellIdentifier];
        PNRecievedComment *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        [cell setComment:comment];
        return cell;
    }
    
}

#pragma mark -
#pragma mark UITableView Delegate

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
	Comment *comment = [_fetchedResultsController objectAtIndexPath:indexPath];
	return [PNSentComment heightForCell:_cellPrototype withComment:comment];
}

#pragma mark - Fetched results controller setup

- (NSFetchedResultsController *)fetchedResultsController {
    
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSManagedObjectContext *context = [[PNCoreDataController sharedInstance] backgroundManagedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Comment" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sort = [[NSSortDescriptor alloc]
                              initWithKey:@"createdAt" ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parentpost == %@", _parentPost];
    
    [fetchRequest setPredicate:predicate];
    
    [fetchRequest setFetchBatchSize:20];
    
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:context
                                          sectionNameKeyPath:nil
                                                   cacheName:@"CommentsCache"];
    self.fetchedResultsController = theFetchedResultsController;
    _fetchedResultsController.delegate = self;
    
    return _fetchedResultsController;
}

- (void)fetchRecords {
    NSError *error = nil;
    [NSFetchedResultsController deleteCacheWithName:@"CommentsCache"];
    if (![[self fetchedResultsController] performFetch:&error]) {
        // TODO: Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }
}

#pragma mark - Fetched Results Controller delegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    // TODO: We REALLY shouldnt be reloading the whole table. Investigate inserting rows.
    // Read here: http://www.fruitstandsoftware.com/blog/2013/02/uitableview-and-nsfetchedresultscontroller-updates-done-right/
    [_tableView reloadData];
}

#pragma mark - Et cetera

- (void)viewDidUnload {
    [NSFetchedResultsController deleteCacheWithName:@"CommentsCache"];
    _fetchedResultsController = nil;
}

@end
