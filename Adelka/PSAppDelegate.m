//
//  PSAppDelegate.m
//  Adelka
//
//  Created by Petr Šimek on 05.10.13.
//  Copyright (c) 2013 Petr Šimek. All rights reserved.
//

#import "PSAppDelegate.h"
#import <CoreServices/CoreServices.h>
#import <AppKit/AppKit.h>
#import <stdarg.h>

#import "PSProgressViewController.h"

@implementation PSAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
}

- (void)awakeFromNib
{
	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	[statusItem setImage:[NSImage imageNamed:@"Adelka"]];
	[statusItem setHighlightMode:YES];
	[statusItem setMenu:statusMenu];

	[statusMenu setAutoenablesItems:YES];
	[statusMenu setDelegate:self];

	databasesMenuItem = [[NSMenuItem alloc]
						 initWithTitle:@"Databases"
								action:@selector(menuItemClicked:)
						 keyEquivalent:@""];

	[databasesMenuItem setTarget:self];
	[databasesMenuItem setEnabled:NO];
	[statusMenu insertItem:databasesMenuItem atIndex:0];

	pVC = [[PSProgressViewController alloc] initWithNibName:@"ProgressView" bundle:nil];
	databasesProgressMenuItem = [[NSMenuItem alloc]
								 initWithTitle:@""
										action:@selector(menuItemClicked:)
								 keyEquivalent:@""];
	[databasesProgressMenuItem setView:[pVC view]];
	[databasesProgressMenuItem setTarget:self];
}

- (void)menuWillOpen:(NSMenu *)menu
{
	startedAnim = false;
	stoppedAnim = false;

	NSTimer *timer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(animateProgress:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode];

	isScanned = false;

	[self someMethod:^(BOOL result) {
		 NSLog(@"%@", tree);

		 [self traverseOneLevel:tree depth:0 parent:tree menuitem:databasesMenuItem];

		 isScanned = true;
	 }];
}

- (void)someMethod:(void (^)(BOOL result))completionHandler
{
	[[[NSOperationQueue alloc] init] addOperationWithBlock:^{
		 tree = [NSMutableDictionary dictionary];

	     //   [NSThread sleepForTimeInterval:1.0f];
		 [self scanFilesIntoTree:tree];
		 [[NSOperationQueue currentQueue] addOperationWithBlock:^{
				  completionHandler(YES);
			  }];
	 }];
}

- (void)animateProgress:(NSTimer *)timer
{
	if (isScanned && startedAnim)
	{
		[[pVC progressIndicator] stopAnimation:[pVC progressIndicator]];
		[databasesMenuItem setEnabled:YES];
		[statusMenu removeItemAtIndex:1];
		[statusMenu setMenuChangedMessagesEnabled:YES];
		startedAnim = false;
		stoppedAnim = true;
	}
	else if (!isScanned && !startedAnim && !stoppedAnim)
	{
		[[pVC progressIndicator] startAnimation:[pVC progressIndicator]];
		[databasesMenuItem setEnabled:NO];
		[statusMenu insertItem:databasesProgressMenuItem atIndex:1];
		startedAnim = true;
		stoppedAnim = false;
	}
}

- (void)scanFilesIntoTree:(NSMutableDictionary *)treeX
{
	NSString *dir =
		[NSString stringWithFormat:@"%@/Library/Application Support/iPhone Simulator", NSHomeDirectory()];

	NSMutableSet *contents = [[NSMutableSet alloc] init];
	NSFileManager *fm = [NSFileManager defaultManager];

	BOOL isDir;

	if (dir && ([fm fileExistsAtPath:dir isDirectory:&isDir] && isDir))
	{
		if (![dir hasSuffix:@"/"])
		{
			dir = [dir stringByAppendingString:@"/"];
		}

		NSDirectoryEnumerator *de = [fm enumeratorAtPath:dir];
		NSString *f;
		NSString *fqn;
		while ((f = [de nextObject]))
		{
			NSString *regEx = @"(.+)/Applications/(.+)/Documents/(.+).sqlite$";

			NSPredicate *regExTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regEx];

			if ([[f pathExtension] isEqualToString:@"sqlite"])
			{
				if ([regExTest evaluateWithObject:f] == YES)
				{
					NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regEx options:NSRegularExpressionCaseInsensitive error:NULL];

					fqn = [dir stringByAppendingString:f];

					if ([fm fileExistsAtPath:fqn isDirectory:&isDir] && isDir)
					{
						fqn = [fqn stringByAppendingString:@"/"];
					}

					[regex enumerateMatchesInString:f options:0
											  range:NSMakeRange(0, [f length])
										 usingBlock:^(NSTextCheckingResult *match,
													  NSMatchingFlags flags, BOOL *stop) {
						 [self insertPathIntoTree:f match:match tree:treeX fqn:fqn];
					 }];

					[contents addObject:fqn];
				}
			}
		}
	}
}

- (IBAction)menuItemClicked:sender {
	[[NSWorkspace sharedWorkspace] openFile:[sender representedObject]];
}

- (IBAction)menuItemQuitClicked:sender {
	[[NSApplication sharedApplication] terminate:nil];
}

- (void)insertPathIntoTree:(NSString *)f match:(NSTextCheckingResult *)match tree:(NSMutableDictionary *)localTree fqn:(NSString *)fqn
{
	for (NSInteger i = 1, count = [match numberOfRanges]; i < count; i++)
	{
		NSString *component = [f substringWithRange:[match rangeAtIndex:i]];

		if (i == 2)
		{
			component =  [NSString stringWithFormat:@"%@...", [component substringWithRange:NSMakeRange(0, 12)]];
		}

		if (i == count - 1)
		{
			[localTree setObject:fqn forKey:component];
		}

		else
		{
			NSMutableDictionary *nextBranch = [tree objectForKey:component];
			if (!nextBranch)
			{
				nextBranch = [NSMutableDictionary dictionary];
				[localTree setObject:nextBranch forKey:component];
			}
			localTree = nextBranch;
		}
	}
}

- (void)traverseOneLevel:(id)object depth:(int)depth parent:(id)parent menuitem:(NSMenuItem *)menuitem
{
	if ([object isKindOfClass:[NSDictionary class]])
	{
		[menuitem setEnabled:YES];
		NSMenu *submenu = [menuitem submenu];

		if (submenu == nil)
		{
			submenu = [[NSMenu alloc] init];
			[menuitem setSubmenu:submenu];
		}
		else
		{
			[submenu removeAllItems];
		}

		for (NSString *key in [object allKeys])
		{
			id child = [object objectForKey:key];

			NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:key action:nil keyEquivalent:@"" ];

			[item setEnabled:YES];

			[submenu addItem:item];

			[self traverseOneLevel:child depth:depth + 1 parent:object menuitem:item];
		}
	}
	else
	{
		[menuitem setRepresentedObject:object];
		[menuitem setTarget:self];
		[menuitem setEnabled:YES];
		[menuitem setAction:@selector(menuItemClicked:) ];
	}
}

@end