#import <Window.h>

static const SDL_WindowFlags kWindowFlags =
    SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIGH_PIXEL_DENSITY | SDL_WINDOW_METAL;

@implementation Window
{
    SDL_Window* _window;
}

+ (instancetype)windowWithTitle:(OFString*)title width:(int)width height:(int)height
{
    return [[self alloc] initWithTitle:title width:width height:height];
}

- (instancetype)initWithTitle:(OFString*)title width:(int)width height:(int)height
{
    self = [super init];
    _title = [title copy];

    if (!SDL_Init(SDL_INIT_VIDEO))
    {
        [OFStdErr writeFormat:@"Failed to initialize SDL: %s\n", SDL_GetError()];
        @throw [OFInitializationFailedException exceptionWithClass:self.class];
    }

    _window = SDL_CreateWindow([_title UTF8String], width, height, kWindowFlags);
    if (_window == NULL)
    {
        [OFStdErr writeFormat:@"Failed to create SDL window: %s\n", SDL_GetError()];
        @throw [OFInitializationFailedException exceptionWithClass:self.class];
    }

    return self;
}

- (SDL_Window*)getSDLWindow
{
    return _window;
}

- (void)dealloc
{
    if (_window != NULL)
    {
        SDL_DestroyWindow(_window);
        _window = NULL;
    }
}

@end
