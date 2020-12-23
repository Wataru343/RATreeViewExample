//
//  RATreeView+TableViewDragDelegate.m
//  treetest
//
//  Created by Wataru Inoue on 2020/12/15.
//

#import "RATreeView+TableViewDragDelegate.h"

@implementation RATreeView (TableViewDragDelegate)
- (nonnull NSArray<UIDragItem *> *)tableView:(nonnull UITableView *)tableView itemsForBeginningDragSession:(nonnull id<UIDragSession>)session atIndexPath:(nonnull NSIndexPath *)indexPath {
    if(self.delegate != nil)
    {
        return [self.delegate treeView:self itemsForBeginningDragSession:session atIndexPath:indexPath];
    } else {
        return @[];
    }
}

@end
