/* 
####################################################
### A G N o S t e p  -  Desktop - by Patrick Cardona
### (c) 2026 - pcardona34 @ Github
### Author: Patrick Cardona
###
### Thanks for the GNUstep Developers Community.
### This application is free software.
### Read complete License in the root directory.
####################################################

####################################################
### Launcher
### Display a list of available Local Applications
### with a filtered view
### 
### Header: MyDelegate.h
####################################################
*/

#import <AppKit/AppKit.h>

@interface MyDelegate : NSObject <NSTableViewDataSource, NSTableViewDelegate>
{
    NSPanel *_panel;
    NSSearchField *_searchField;
    NSTableView *_tableView;
    NSMutableArray *_apps;
}

- (void)loadApps;
- (NSArray *)visibleApps;
- (void)filterApps:(id)sender;
- (void)launchAppAtPath:(NSString *)appPath;

@end
