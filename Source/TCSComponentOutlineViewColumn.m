//
//  TCSComponentOutlineViewColumn.m
//  TomcatSlapper
//
//  Created by John Clayton on 3/5/05.
//  Copyright 2005 Fivesquare Software, LLC. All rights reserved.
//

#import "TCSComponentOutlineViewColumn.h"
#import "TCSComponentViewDataSource.h"

@implementation TCSComponentOutlineViewColumn

- (id)dataCellForRow:(int)row {
    id outlineView = [self tableView];
    id item = [outlineView itemAtRow:row];
    id datasource = [outlineView dataSource];
    return [datasource dataCellForItem:item tableColumn:self];
}

@end
