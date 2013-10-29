//
//  PSProgressView.m
//  Adelka
//
//  Created by Petr Šimek on 22.10.13.
//  Copyright (c) 2013 Petr Šimek. All rights reserved.
//

#import "PSProgressView.h"

@implementation PSProgressView

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
	{
		// Initialization code here.
	}
	return self;
}

- (void)mouseUp:(NSEvent *)event
{
	NSMenuItem *mitem = [self enclosingMenuItem];
	NSMenu *m = [mitem menu];

	[m cancelTracking];
	[m performActionForItemAtIndex:[m indexOfItem:mitem]];
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
}

@end