//
//  UITableViewCell+CloudSeeder.h
//  CloudSeeder
//
//  Created by David Shu on 4/10/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
	kCSTableCell_None,
	kCSTableCell_Top,
	kCSTableCell_Mid,
	kCSTableCell_Bottom,
	kCSTableCell_Single
} CSTableCellPositionType;

@interface UITableViewCell (CloudSeeder)
- (CSTableCellPositionType)cellPositionTypeForRow:(NSInteger)row totalCount:(NSInteger)totalCount;
@end
