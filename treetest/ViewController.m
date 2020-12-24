
//The MIT License (MIT)
//
//Copyright (c) 2014 Rafał Augustyniak
//
//Permission is hereby granted, free of charge, to any person obtaining a copy of
//this software and associated documentation files (the "Software"), to deal in
//the Software without restriction, including without limitation the rights to
//use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//the Software, and to permit persons to whom the Software is furnished to do so,
//subject to the following conditions:
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import "ViewController.h"
#import "RATreeView.h"
#import "RADataObject.h"

#import "RATableViewCell.h"


@interface ViewController () <RATreeViewDelegate, RATreeViewDataSource>

@property (strong, nonatomic) NSMutableArray *data;
@property (weak, nonatomic) RATreeView *treeView;

@property (strong, nonatomic) UIBarButtonItem *editButton;

@end

@implementation ViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  [self loadData];

  RATreeView *treeView = [[RATreeView alloc] initWithFrame:self.view.bounds];

  treeView.delegate = self;
  treeView.dataSource = self;
  treeView.treeFooterView = [UIView new];
  treeView.separatorStyle = RATreeViewCellSeparatorStyleSingleLine;
    treeView.allowsSelection = YES;
    treeView.allowsSelectionDuringEditing = YES;
    treeView.dragInteractionEnabled = YES;

  UIRefreshControl *refreshControl = [UIRefreshControl new];
  [refreshControl addTarget:self action:@selector(refreshControlChanged:) forControlEvents:UIControlEventValueChanged];
  [treeView.scrollView addSubview:refreshControl];

    [treeView reloadData:^{
        //Completion
        for (RADataObject *item in self.data) {
            //Expand the cell after reloading.
            if (item.expanded) {
                //Disable expand animation
                self.treeView.isAnimationEnabled = NO;
                [self.treeView expandCollapseRow:[self.treeView indexPathForItem:item]];
                self.treeView.isAnimationEnabled = YES;
            }
        }
    }];
  [treeView setBackgroundColor:[UIColor colorWithWhite:0.97 alpha:1.0]];


  self.treeView = treeView;
  self.treeView.frame = self.view.bounds;
  self.treeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [self.view insertSubview:treeView atIndex:0];

  [self.navigationController setNavigationBarHidden:NO];
  self.navigationItem.title = NSLocalizedString(@"Things", nil);
  [self updateNavigationItemButton];

  [self.treeView registerNib:[UINib nibWithNibName:NSStringFromClass([RATableViewCell class]) bundle:nil] forCellReuseIdentifier:NSStringFromClass([RATableViewCell class])];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  int systemVersion = [[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."][0] intValue];
  if (systemVersion >= 7 && systemVersion < 8) {
    CGRect statusBarViewRect = [[UIApplication sharedApplication] statusBarFrame];
    float heightPadding = statusBarViewRect.size.height+self.navigationController.navigationBar.frame.size.height;
    self.treeView.scrollView.contentInset = UIEdgeInsetsMake(heightPadding, 0.0, 0.0, 0.0);
    self.treeView.scrollView.contentOffset = CGPointMake(0.0, -heightPadding);
  }

  self.treeView.frame = self.view.bounds;
}


#pragma mark - Actions

- (void)refreshControlChanged:(UIRefreshControl *)refreshControl
{
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [refreshControl endRefreshing];
  });
}

- (void)editButtonTapped:(id)sender
{
  [self.treeView setEditing:!self.treeView.isEditing animated:YES];
  [self updateNavigationItemButton];
}

- (void)updateNavigationItemButton
{
  UIBarButtonSystemItem systemItem = self.treeView.isEditing ? UIBarButtonSystemItemDone : UIBarButtonSystemItemEdit;
  self.editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:systemItem target:self action:@selector(editButtonTapped:)];
  self.navigationItem.rightBarButtonItem = self.editButton;
}


#pragma mark TreeView Delegate methods

- (CGFloat)treeView:(RATreeView *)treeView heightForRowForItem:(id)item
{
  return 44 + (3 - [treeView levelForCellForItem:item]) * 15;
}

- (BOOL)treeView:(RATreeView *)treeView canEditRowForItem:(id)item
{
  return YES;
}

- (void)treeView:(RATreeView *)treeView willExpandRowForItem:(id)item
{
  RATableViewCell *cell = (RATableViewCell *)[treeView cellForItem:item];
  [cell setAdditionButtonHidden:NO animated:YES];
}

- (void)treeView:(RATreeView *)treeView willCollapseRowForItem:(id)item
{
  RATableViewCell *cell = (RATableViewCell *)[treeView cellForItem:item];
  [cell setAdditionButtonHidden:YES animated:YES];
}

- (void)treeView:(RATreeView *)treeView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowForItem:(id)item
{
  if (editingStyle != UITableViewCellEditingStyleDelete) {
    return;
  }

  RADataObject *parent = [self.treeView parentForItem:item];
  NSInteger index = 0;

  if (parent == nil) {
    index = [self.data indexOfObject:item];
    NSMutableArray *children = [self.data mutableCopy];
    [children removeObject:item];
    self.data = [children copy];

  } else {
    index = [parent.children indexOfObject:item];
    [parent removeChild:item];
  }

  [self.treeView deleteItemsAtIndexes:[NSIndexSet indexSetWithIndex:index] inParent:parent withAnimation:RATreeViewRowAnimationRight];
  if (parent) {
    [self.treeView reloadRowsForItems:@[parent] withRowAnimation:RATreeViewRowAnimationNone];
  }
}

- (void)treeView:(RATreeView *)treeView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger level = [treeView levelForCellForItem:[treeView itemForRowAtIndexPath:indexPath]];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:level == 0 ? @"Parent cell tapped" : @"Child cell tapped" message:@"" preferredStyle:UIAlertControllerStyleAlert];
     [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
      }]];

    //[self presentViewController:alertController animated:YES completion:nil];
}

- (NSArray<RADataObject *> *)getItems:(RADataObject *)parentItem
{
    NSMutableArray *arr = [NSMutableArray arrayWithObjects: parentItem, nil];

    if(parentItem.children) {
        for (RADataObject *child in parentItem.children) {
            [arr addObjectsFromArray: [self getItems:child]];
        }
    }

    return arr;
}

- (NSArray<UIDragItem *> *)treeView:(RATreeView *)treeView itemsForBeginningDragSession:(id<UIDragSession>)session atIndexPath:(NSIndexPath *)indexPath
{
    RADataObject *item = [self.treeView itemForRowAtIndexPath:indexPath];

    NSArray *array = [self getItems:item];

    NSMutableArray *dragItems = [NSMutableArray array];
    for (RADataObject *obj in array) {
        NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithItem:obj typeIdentifier:(NSString*)kUTTypePlainText];
        UIDragItem *dragItem = [[UIDragItem alloc] initWithItemProvider: itemProvider];
        [dragItems addObject:dragItem];
    }

    return dragItems;
}

- (void)treeView:(RATreeView *)treeView performDropWithCoordinator:(id<UITableViewDropCoordinator>)coordinator
{
    if(coordinator.items.firstObject) {
        RADataObject *srcItem = [self.treeView itemForRowAtIndexPath:coordinator.items.firstObject.sourceIndexPath];
        RADataObject *dstItem = [self.treeView itemForRowAtIndexPath:coordinator.destinationIndexPath];
        RADataObject *parentItem = [self.treeView parentForItem:srcItem];
        NSLog(@"%@, %@", srcItem, dstItem);

        [self treeView:self.treeView commitEditingStyle:UITableViewCellEditingStyleDelete forRowForItem:srcItem];

        [dstItem addChild:srcItem];
        [self.treeView insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:0] inParent:dstItem withAnimation:RATreeViewRowAnimationLeft];
        [self.treeView reloadRowsForItems:@[dstItem] withRowAnimation:RATreeViewRowAnimationNone];
    }
}

#pragma mark TreeView Data Source

- (UITableViewCell *)treeView:(RATreeView *)treeView cellForItem:(id)item
{
  RADataObject *dataObject = item;

  NSInteger level = [self.treeView levelForCellForItem:item];
  NSInteger numberOfChildren = [dataObject.children count];
  NSString *detailText = [NSString localizedStringWithFormat:@"Number of children %@", [@(numberOfChildren) stringValue]];
  BOOL expanded = [self.treeView isCellForItemExpanded:item];

  __block RATableViewCell *cell = [self.treeView dequeueReusableCellWithIdentifier:NSStringFromClass([RATableViewCell class])];
  [cell setupWithTitle:dataObject.name detailText:detailText level:level additionButtonHidden:!expanded];
  cell.selectionStyle = UITableViewCellSelectionStyleNone;

  __weak typeof(self) weakSelf = self;
  cell.additionButtonTapAction = ^(id sender){
      /*if (![weakSelf.treeView isCellForItemExpanded:dataObject] || weakSelf.treeView.isEditing) {
      return;
    }*/
    RADataObject *newDataObject = [[RADataObject alloc] initWithName:@"Added value" children:@[]];
    [dataObject addChild:newDataObject];
    [weakSelf.treeView insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:0] inParent:dataObject withAnimation:RATreeViewRowAnimationLeft];
    [weakSelf.treeView reloadRowsForItems:@[dataObject] withRowAnimation:RATreeViewRowAnimationNone];
  };

  cell.expandButtonTapAction = ^(id sender){
      [treeView expandCollapseRow:[treeView indexPathForCell:cell]];
  };

  return cell;
}

- (NSInteger)treeView:(RATreeView *)treeView numberOfChildrenOfItem:(id)item
{
  if (item == nil) {
    return [self.data count];
  }

  RADataObject *data = item;
  return [data.children count];
}

- (RATreeItem*)treeView:(RATreeView *)treeView child:(NSInteger)index ofItem:(id)item
{
  RADataObject *data = item;
  if (item == nil) {
    return [self.data objectAtIndex:index];
  }

  return data.children[index];
}

#pragma mark - Helpers

- (void)loadData
{
  RADataObject *phone1 = [RADataObject dataObjectWithName:@"Phone 1" children:nil];
  RADataObject *phone2 = [RADataObject dataObjectWithName:@"Phone 2" children:nil];
  RADataObject *phone3 = [RADataObject dataObjectWithName:@"Phone 3" children:nil];
  RADataObject *phone4 = [RADataObject dataObjectWithName:@"Phone 4" children:nil];

  RADataObject *phone = [RADataObject dataObjectWithName:@"Phones"
                                                children:[NSArray arrayWithObjects:phone1, phone2, phone3, phone4, nil]];

  RADataObject *notebook1 = [RADataObject dataObjectWithName:@"Notebook 1" children:nil];
  RADataObject *notebook2 = [RADataObject dataObjectWithName:@"Notebook 2" children:nil];

  RADataObject *computer1 = [RADataObject dataObjectWithName:@"Computer 1"
                                                    children:[NSArray arrayWithObjects:notebook1, notebook2, nil]];
  //Specify the cells to be expanded.
  computer1.expanded = YES;
  RADataObject *computer2 = [RADataObject dataObjectWithName:@"Computer 2" children:nil];
  RADataObject *computer3 = [RADataObject dataObjectWithName:@"Computer 3" children:nil];

  RADataObject *computer = [RADataObject dataObjectWithName:@"Computers"
                                                   children:[NSArray arrayWithObjects:computer1, computer2, computer3, nil]];
  computer.expanded = YES;
  RADataObject *car = [RADataObject dataObjectWithName:@"Cars" children:nil];
  RADataObject *bike = [RADataObject dataObjectWithName:@"Bikes" children:nil];
  RADataObject *house = [RADataObject dataObjectWithName:@"Houses" children:nil];
  RADataObject *flats = [RADataObject dataObjectWithName:@"Flats" children:nil];
  RADataObject *motorbike = [RADataObject dataObjectWithName:@"Motorbikes" children:nil];
  RADataObject *drinks = [RADataObject dataObjectWithName:@"Drinks" children:nil];
  RADataObject *food = [RADataObject dataObjectWithName:@"Food" children:nil];
  RADataObject *sweets = [RADataObject dataObjectWithName:@"Sweets" children:nil];
  RADataObject *watches = [RADataObject dataObjectWithName:@"Watches" children:nil];
  RADataObject *walls = [RADataObject dataObjectWithName:@"Walls" children:nil];
    RADataObject *walls2 = [RADataObject dataObjectWithName:@"Walls" children:nil];
    RADataObject *walls3 = [RADataObject dataObjectWithName:@"Walls" children:nil];
    RADataObject *walls4 = [RADataObject dataObjectWithName:@"Walls" children:nil];
    RADataObject *walls5 = [RADataObject dataObjectWithName:@"Walls" children:nil];
    RADataObject *walls6 = [RADataObject dataObjectWithName:@"Walls" children:nil];
    RADataObject *walls7 = [RADataObject dataObjectWithName:@"Walls" children:nil];
    RADataObject *walls8 = [RADataObject dataObjectWithName:@"Walls" children:nil];
    RADataObject *walls9 = [RADataObject dataObjectWithName:@"Walls" children:nil];
    RADataObject *walls10 = [RADataObject dataObjectWithName:@"Walls" children:nil];
    RADataObject *walls11 = [RADataObject dataObjectWithName:@"Walls" children:nil];
    RADataObject *walls12 = [RADataObject dataObjectWithName:@"Walls" children:nil];
    RADataObject *walls13 = [RADataObject dataObjectWithName:@"Walls" children:nil];
    RADataObject *walls14 = [RADataObject dataObjectWithName:@"Walls" children:nil];
    RADataObject *walls15 = [RADataObject dataObjectWithName:@"Walls" children:[NSArray arrayWithObjects:walls14, nil]];
    walls15.expanded = YES;

  self.data = [NSMutableArray arrayWithObjects:phone, computer, car, bike, house, flats, motorbike, drinks, food, sweets, watches, walls, walls2, walls3, walls4, walls5, walls6, walls7, walls8, walls9, walls10, walls11, walls12, walls13, walls15, nil];

}

@end
