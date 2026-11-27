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
	 
	 //NSLog(@"Comparing %@ and %@", nameA, nameB);

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

- (NSString *) getApplicationsFolderPath
{
	/* We do not use NSProcessInfo because it fails to get GNUstep variables
	when the app is executed from the Dock */
	
	NSString *gnustepconf = @"/etc/GNUstep/GNUstep.conf";
   NSString *content = [NSString stringWithContentsOfFile: gnustepconf];
   NSString *motif = @"GNUSTEP_LOCAL_APPS";
	NSLog(@"Reading GNUstep conf...");
	if (content == nil) {
		NSLog(@"Reading GNUstep conf at %@ failed.", gnustepconf);
		return @"";
		}
	
	NSArray *lines = [content componentsSeparatedByString:@"\n"];
   for (NSString *line in lines) {
        if ([line rangeOfString: motif].location != NSNotFound) {
        	printf("%s", [line UTF8String]);
        	NSString *found = [[NSString stringWithFormat: @"%s", [line UTF8String]] substringFromIndex: 19];
        	
        	return found;
        }
    }
    return @"";
}

/* Scan GNUstep's local applications directory. */
- (void)loadApps
{
   	NSString *applicationsFolderPath;
	NSArray *names;
		
	applicationsFolderPath = [self getApplicationsFolderPath];
    
    NSFileManager *fm = [NSFileManager defaultManager];    
    
    names = [fm contentsOfDirectoryAtPath:applicationsFolderPath error:NULL];
    	    	
    for (NSString *name in names) {
        if ([[name pathExtension] isEqualToString:@"app"]) {
            NSString *path = [applicationsFolderPath stringByAppendingPathComponent:name];
            BOOL isDirectory = NO;
            if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
                [_apps addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                  [name stringByDeletingPathExtension], @"name",
                                  path, @"path", nil]];
            }
        }
    }

    // Sorting the Apps
	// NSLog(@"Before sort: %lu apps", (unsigned long)[_apps count]);
   [_apps sortUsingFunction:CompareAppsByName context:NULL];
   // NSLog(@"After sort: %lu apps", (unsigned long)[_apps count]);	
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
	NSLog(@"tableView was reloaded.");
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    NSInteger count = [[self visibleApps] count];
    // NSLog(@"numberOfRowsInTableView: %ld", (long)count);
    return count;
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

- (NSApplicationTerminateReply)applicationShouldTerminate:
    (NSApplication *)sender
{
    NSLog(@"Launcher termination requested");
    return NSTerminateNow;
}

@end

