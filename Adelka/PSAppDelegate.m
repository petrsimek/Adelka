//
//  PSAppDelegate.m
//  SQLite Access Tool
//
//  Created by Petr Šimek on 05.10.13.
//  Copyright (c) 2013 Petr Šimek. All rights reserved.
//

#import "PSAppDelegate.h"
#import <CoreServices/CoreServices.h>
#import <AppKit/AppKit.h>
#import <stdarg.h>


@implementation PSAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
}

- (void)insertPathIntoTree:(NSString *)f match:(NSTextCheckingResult *)match tree:(NSMutableDictionary *)tree fqn:(NSString *)fqn
{
	for (int i = 1, count = [match numberOfRanges]; i < count; i++)
	{
		NSString *component = [f substringWithRange:[match rangeAtIndex:i]];

		if (i == count - 1 /*&& [component hasSuffix:@".pack"]*/)
		{
			[tree setObject:fqn forKey:component];
		}

		else
		{
			NSMutableDictionary *nextBranch = [tree objectForKey:component];
			if (!nextBranch)
			{
				nextBranch = [NSMutableDictionary dictionary];
				[tree setObject:nextBranch forKey:component];
			}
			tree = nextBranch;
		}
	}
}

- (void)traverseOneLevel:(id)object depth:(int)depth parent:(id)parent menuitem:(NSMenuItem *)menuitem
{
	if ([object isKindOfClass:[NSDictionary class]])
	{
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

- (void)menuWillOpen:(NSMenu *)menu
{
	NSString *dir =
		[NSString stringWithFormat:@"%@/Library/Application Support/iPhone Simulator", NSHomeDirectory()];

	NSMutableSet *contents = [[NSMutableSet alloc] init];
	NSFileManager *fm = [NSFileManager defaultManager];

	BOOL isDir;

	NSMutableDictionary *tree = [NSMutableDictionary dictionary];

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
						 [self insertPathIntoTree:f match:match tree:tree fqn:fqn];
					 }];

					[contents addObject:fqn];
				}
			}
		}


		NSLog(@"%@", tree);

		[self traverseOneLevel:tree depth:0 parent:tree menuitem:[statusMenu itemWithTag:102]];
	}
}

- (void)awakeFromNib
{
	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	[statusItem setImage:[NSImage imageNamed:@"Adelka"]];
	[statusItem setHighlightMode:YES];
	[statusItem setMenu:statusMenu];

	[statusMenu setAutoenablesItems:YES];
	[statusMenu setDelegate:self];
}

- (IBAction)menuItemClicked:sender {
	[[NSWorkspace sharedWorkspace] openFile:[sender representedObject]];
}

@end