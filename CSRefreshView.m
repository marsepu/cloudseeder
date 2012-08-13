//
//  CSRefreshView.m
//  CloudSeeder
//
//  Created by David Shu on 4/10/12.
//  Copyright (c) 2012 Retronyms. All rights reserved.
//

#import "CSRefreshView.h"

@implementation CSRefreshView
@synthesize refreshIcon = mRefreshIcon;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code        
    }
    return self;
}

+ (CSRefreshView *)create {
	CSRefreshView *cell = nil;
	NSArray *top_level = [[NSBundle mainBundle] loadNibNamed:@"CSRefreshView" owner:self options:nil];
	for(id obj in top_level) {
		if([obj isKindOfClass:[CSRefreshView class]]) {
			cell = (CSRefreshView *) obj;
            [cell retain];
			break;
		}
	}
	return cell;
}

- (void)dealloc {
    // IBOutlets
    [mRefreshIcon release]; mRefreshIcon = nil;
    
    [super dealloc];
}


@end
