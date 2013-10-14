//
//  PSAppDelegate.h
//  SQLite Access Tool
//
//  Created by Petr Šimek on 05.10.13.
//  Copyright (c) 2013 Petr Šimek. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PSAppDelegate : NSObject <NSApplicationDelegate,NSMenuDelegate> {
    

    IBOutlet NSMenu *statusMenu;
    NSStatusItem * statusItem;
    
}



@end
