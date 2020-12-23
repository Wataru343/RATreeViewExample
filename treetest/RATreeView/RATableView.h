//
//  RATableView.h
//  Pods
//
//  Created by Rafal Augustyniak on 15/11/15.
//
//


#import <UIKit/UIKit.h>


@interface RATableView : UITableView

@property (nonatomic, nullable, weak) id<UITableViewDelegate> tableViewDelegate;
@property (nonatomic, nullable, weak) id<UIScrollViewDelegate> scrollViewDelegate;
@property (nonatomic, nullable, weak) id<UITableViewDragDelegate> tableViewDragDelegate;
@property (nonatomic, nullable, weak) id<UITableViewDropDelegate> tableViewDropDelegate;

@end
