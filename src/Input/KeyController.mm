#import <Input/KeyController.h>

@implementation KeyController

+ (instancetype)keyController
{
    return [[self alloc] init];
}

- (void)handleEvent:(const SDL_Event*)event quit:(bool*)quit
{
    if (event->type == SDL_EVENT_QUIT)
        *quit = true;

    if (event->type == SDL_EVENT_KEY_DOWN && event->key.scancode == SDL_SCANCODE_ESCAPE)
        *quit = true;
}

@end
