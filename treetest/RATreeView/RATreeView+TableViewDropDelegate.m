//
//  RATreeView+TableViewDropDelegate.m
//  treetest
//
//  Created by Wataru Inoue on 2020/12/15.
//

#import "RATreeView+TableViewDropDelegate.h"

@implementation RATreeView (TableViewDropDelegate)
- (void)tableView:(nonnull UITableView *)tableView performDropWithCoordinator:(nonnull id<UITableViewDropCoordinator>)coordinator
{
    if(self.delegate != nil)
    {
        [self.delegate treeView:self performDropWithCoordinator:coordinator];
    }
}

- (UITableViewDropProposal *)tableView:(UITableView *)tableView dropSessionDidUpdate:(id<UIDropSession>)session withDestinationIndexPath:(NSIndexPath *)destinationIndexPath
{
    return [[UITableViewDropProposal alloc] initWithDropOperation:UIDropOperationMove];
}

- (BOOL)tableView:(UITableView *)tableView canHandleDropSession:(id<UIDropSession>)session
{
    return YES;
}

@end
