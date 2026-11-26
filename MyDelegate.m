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
### Is listing available Applications
### with a built-in filter
###
### Implementation: MyDelegate.m
####################################################
*/

#import <AppKit/AppKit.h>
#import "MyDelegate.h"

static NSComparisonResult CompareAppsByName(id a, id b, void *context)
{
    NSString *nameA = [a objectForKey:@"name"];
    NSString *nameB = [b objectForKey:@"name"];

    return [nameA caseInsensitiveCompare:nameB];
}

@implementation MyDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    _apps = [[NSMutableArray alloc] init];

    [self loadApps];

    _panel = [[NSPanel alloc] initWithContentRect:NSMakeRect(200, 200, 420, 500)
                                        styleMask:(NSTitledWindowMask |
                                                   NSClosableWindowMask |
                                                   NSMiniaturizableWindowMask)
                                          backing:NSBackingStoreBuffered
                                            defer:NO];
    [_panel setTitle: _(@"Applications") ];

    NSView *content = [_panel contentView];

    _searchField = [[NSSearchField alloc] initWithFrame:NSMakeRect(12, 458, 396, 28)];
    [_searchField setTarget:self];
    [_searchField setAction:@selector(filterApps:)];
    [content addSubview:_searchField];

    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(12, 12, 396, 436)];
    [scroll setHasVerticalScroller:YES];

    _tableView = [[NSTableView alloc] initWithFrame:[[scroll contentView] bounds]];
    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"app"];
    [column setWidth:380];
    [_tableView addTableColumn:column];
    [_tableView setHeaderView:nil];
    [_tableView setDataSource:self];
    [_tableView setDelegate:self];
    [scroll setDocumentView:_tableView];
    [content addSubview:scroll];

    [_panel makeKeyAndOrderFront:nil];
}

/* Scan GNUstep's local applications directory. */
- (void)loadApps
{
    NSString *appsPath = [[[NSProcessInfo processInfo] environment]
                          objectForKey:@"GNUSTEP_LOCAL_APPS"];
    if (appsPath == nil) {
        NSLog(@"GNUSTEP_LOCAL_APPS is not set");
        return;
    }

    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *names = [fm contentsOfDirectoryAtPath:appsPath error:NULL];

    for (NSString *name in names) {
        if ([[name pathExtension] isEqualToString:@"app"]) {
            NSString *path = [appsPath stringByAppendingPathComponent:name];
            BOOL isDirectory = NO;
            if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
                [_apps addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                  [name stringByDeletingPathExtension], @"name",
                                  path, @"path", nil]];
            }
        }
    }

    // Sorting the Apps 
	[_apps sortUsingFunction:CompareAppsByName context:NULL];
}

- (NSArray *)visibleApps
{
    NSString *query = [[_searchField stringValue] lowercaseString];
    if ([query length] == 0) return _apps;

    NSMutableArray *matches = [NSMutableArray array];
    for (NSDictionary *app in _apps) {
        if ([[[app objectForKey:@"name"] lowercaseString] rangeOfString:query].location
            != NSNotFound) {
            [matches addObject:app];
        }
    }
    return matches;
}

- (void)filterApps:(id)sender
{
    [_tableView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [[self visibleApps] count];
}

- (id)tableView:(NSTableView *)tableView
 objectValueForTableColumn:(NSTableColumn *)column
            row:(NSInteger)row
{
    return [[[self visibleApps] objectAtIndex:row] objectForKey:@"name"];
}

- (void)tableView:(NSTableView *)tableView
   setObjectValue:(id)value
   forTableColumn:(NSTableColumn *)column
              row:(NSInteger)row
{
    /* The list is display-only. */
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if ([_tableView selectedRow] < 0) return;

    NSDictionary *app = [[self visibleApps] objectAtIndex:[_tableView selectedRow]];
    [self launchAppAtPath:[app objectForKey:@"path"]];
}

- (void)launchAppAtPath:(NSString *)appPath
{
    NSString *appName = [[appPath lastPathComponent] stringByDeletingPathExtension];
    BOOL launched = [[NSWorkspace sharedWorkspace] launchApplication:appName];

    if (launched) {
        [NSApp terminate:nil];
    } else {
        NSLog(@"Could not launch %@.", appPath);
    }
}


@end

