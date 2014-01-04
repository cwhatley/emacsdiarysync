//
//  RNAppDelegate.m
//  EmacsDiarySync
//
//  Created by Chris Whatley on 1/3/14.
//  Copyright (c) 2014 Chris Whatley. All rights reserved.
//

#import "RNAppDelegate.h"
#import "EventKit/EventKit.h"

#define RNDiaryFilePath @"diaryFilePath"
#define RNDefaultDiaryFilePath @"~/diary"

@implementation RNAppDelegate
NSStatusItem *statusItem;
BOOL accessIsGranted = NO;
EKEventStore *store;
NSString *diaryPath;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
    statusItem = [statusBar statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setTitle:@"EDS"];
    [statusItem setHighlightMode:YES];
    [statusItem setMenu: [self statusMenu]];

    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject: RNDefaultDiaryFilePath forKey: RNDiaryFilePath]];
    diaryPath = [[[NSUserDefaults standardUserDefaults] stringForKey: RNDiaryFilePath] stringByStandardizingPath];
    [self openEventStore];
    [self checkDiaryPath];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(refreshDiary:)
     name:EKEventStoreChangedNotification
     object:store];
    [self performSelector:@selector(refreshDiary:) withObject:self afterDelay: 2.0];
}

- (void) openEventStore
{
    store = [[EKEventStore alloc] init];
    [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        accessIsGranted = granted;
        NSLog(@"%@",[error debugDescription]);
    }];
}

- (BOOL) checkDiaryPath {
    BOOL result = NO;
    if(diaryPath){
        NSFileManager *fm = [NSFileManager defaultManager];
        BOOL fileExists = [fm fileExistsAtPath:diaryPath];
        if(fileExists){
            if(![fm isWritableFileAtPath:diaryPath]){
                NSLog(@"Can't write diary file %@", diaryPath);
            } else {
                result = YES;
            }
        } else {
            NSLog(@"Diary file (%@) doesn't exist.", diaryPath);
            result = [fm createFileAtPath:diaryPath contents:[NSData data] attributes: nil];
            if(!result){
                NSLog(@"Can't create empty diary file %@", diaryPath);
            }
        }
    } else {
        NSLog(@"Empty default for diary path");
    }
    return result;
}

- (void)refreshDiary: (id)sender
{
    NSLog(@"Trying to refresh diary");
    if(accessIsGranted && [self checkDiaryPath]){
        NSCalendar *calendar = [NSCalendar currentCalendar];
        
        // Create the start date components
        NSDateComponents *oneDayAgoComponents = [[NSDateComponents alloc] init];
        oneDayAgoComponents.day = -1;
        NSDate *oneDayAgo = [calendar dateByAddingComponents:oneDayAgoComponents
                                                      toDate:[NSDate date]
                                                     options:0];
        
        // Create the end date components
        NSDateComponents *twoWeeksFromNowComponents = [[NSDateComponents alloc] init];
        twoWeeksFromNowComponents.week = 1;
        NSDate *twoWeeksFromNow = [calendar dateByAddingComponents:twoWeeksFromNowComponents
                                                           toDate:[NSDate date]
                                                          options:0];
        
        // Create the predicate from the event store's instance method
        NSPredicate *predicate = [store predicateForEventsWithStartDate:oneDayAgo
                                                                endDate:twoWeeksFromNow
                                                              calendars:nil];
        
        // Fetch all events that match the predicate
        NSArray *events = [store eventsMatchingPredicate:predicate];
        
        NSDateFormatter *dfTime = [NSDateFormatter new];
        [dfTime setDateFormat: @"hh:mma"];
        NSDateFormatter *dfDate = [NSDateFormatter new];
        [dfDate setDateStyle:NSDateFormatterShortStyle];
        [dfDate setTimeStyle: NSDateFormatterNoStyle];
        
        NSMutableString *output = [NSMutableString stringWithCapacity:[events count]*80];
        
        NSEnumerator *en = [events objectEnumerator];
        EKEvent *ev;
        int idx = 0;
        while(ev=[en nextObject]){
            [output appendString: [dfDate stringFromDate:[ev startDate]]];
            [output appendString: @" "];
            if(![ev isAllDay]){
               [output appendString:
                [NSString stringWithFormat: @"%@-%@ ",
                 [dfTime stringFromDate:[ev startDate]],
                 [dfTime stringFromDate:[ev endDate]]]];
            }
            if([ev organizer]){
                [output appendFormat: @"(%@-%@) ", [[ev calendar] title], [[ev organizer] name]];
            } else {
                [output appendFormat: @"(%@) ", [[ev calendar] title]];
            }
            [output appendString:[ev title]];
            if([ev location] && [[ev location] length]>0){
                [output appendString:[NSString stringWithFormat: @" [%@]", [ev location]]];
            }
            [output appendString:@"\n"];
            [self updateRefreshProgress: idx++ ofTotal: [events count]];
        }
        NSError *error;
        if(![output writeToFile:diaryPath atomically:YES encoding:NSUTF8StringEncoding error:&error]){
            NSLog(@"Error writing to %@ - %@", diaryPath, [error debugDescription]);
        }
        [self indicateNormalCondition];
    } else {
        [self indicateErrorCondition];
        // Try again in a bit
        [self performSelector:@selector(refreshDiary:) withObject:self afterDelay: 30];
    }
}

- (void)indicateErrorCondition
{
    [statusItem setTitle: @"EDS!"];
}

- (void)indicateNormalCondition
{
    [statusItem setTitle: @"EDS"];
}
- (void)updateRefreshProgress:(NSUInteger)base ofTotal: (NSUInteger) total
{
    NSString *menu = @"/-\\-";
    NSString *str =[NSString stringWithFormat:@"EDS%@", [menu substringWithRange:NSMakeRange(base%4, 1)]];
    [statusItem setTitle: str];
}
@end
