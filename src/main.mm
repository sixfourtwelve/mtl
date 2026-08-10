#import <ObjFW/ObjFW.h>
#import <SDL3/SDL.h>

#import "main.h"

OF_APPLICATION_DELEGATE(Main)

@implementation Main

- (void)applicationDidFinishLaunching:(nonnull OFNotification*)notification
{
    _engine = [Engine engine];
    [_engine go];
    [OFApplication terminate];
}

- (void)applicationWillTerminate:(OFNotification*)notification
{
    [OFStdOut writeLine:@"Application terminated"];
}

@end
