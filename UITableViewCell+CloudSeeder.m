//
//  UITableViewCell+CloudSeeder.m
//  CloudSeeder
//
//  Created by David Shu on 4/10/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import "UITableViewCell+CloudSeeder.h"

@implementation UITableViewCell (CloudSeeder)
- (CSTableCellPositionType)cellPositionTypeForRow:(NSInteger)row totalCount:(NSInteger)totalCount {
    CSTableCellPositionType posType;
	if (totalCount <= 1) {
		posType = kCSTableCell_Single;
	}
	else {
		if (row == 0) {
			posType = kCSTableCell_Top;
		}
		else if (row == totalCount-1) {
			posType = kCSTableCell_Bottom;
		}
		else {
			posType = kCSTableCell_Mid;
		}
	}
    return posType;
}

@end
