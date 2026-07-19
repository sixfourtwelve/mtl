#import "CommandBuffer.h"
#import <ObjFW/ObjFW.h>
#import <SDL3/SDL.h>

#import "Device.h"
#import "main.h"

OF_APPLICATION_DELEGATE(Main)

@implementation Main

- (void)applicationDidFinishLaunching:(nonnull OFNotification*)notification
{
    @autoreleasepool
    {
        if (SDL_Init(SDL_INIT_VIDEO) == 0)
        {
            [OFStdErr writeFormat:@"Failed to initialize SDL: %s\n", SDL_GetError()];
            [OFApplication terminate];
        }

        const SDL_WindowFlags flags = SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIGH_PIXEL_DENSITY | SDL_WINDOW_METAL;
        _window = SDL_CreateWindow("ObjFW SDL3 Example", 1920, 1080, flags);
        if (_window == nil)
        {
            [OFStdErr writeFormat:@"Failed to create SDL window: %s\n", SDL_GetError()];
            [OFApplication terminate];
        }

        _device = [Device deviceWithWindow:_window];
        Shader* vertexShader = [Shader shaderWithDevice:_device
                                                 source:@"triangle.vert"
                                          samplerCounts:0
                                    uniformBufferCounts:0
                                    storageBufferCounts:0
                                   storageTextureCounts:0];
        Shader* fragmentShader = [Shader shaderWithDevice:_device
                                                   source:@"triangle.frag"
                                            samplerCounts:0
                                      uniformBufferCounts:0
                                      storageBufferCounts:0
                                     storageTextureCounts:0];
        _pipeline = [Pipeline
            pipelineWithDevice:_device
                        window:_window
                        vertex:vertexShader
                      fragment:fragmentShader];

        _commandBuffer = [CommandBuffer command:_device pipeline:_pipeline window:_window];

        [self loop];
    }

    [OFApplication terminate];
}

- (void)loop
{
    BOOL quit = NO;
    while (!quit)
    {
        @autoreleasepool
        {
            SDL_Event event;
            while (SDL_PollEvent(&event))
            {
                [self handleEvent:event quit:&quit];
            }

            [_commandBuffer begin];
            [_commandBuffer end];
            [_commandBuffer submit];
        }
    }
}

- (void)handleEvent:(SDL_Event)event quit:(BOOL*)quit
{
    if (event.type == SDL_EVENT_QUIT)
    {
        *quit = YES;
    }

    if (event.type == SDL_EVENT_KEY_DOWN)
    {
        if (event.key.scancode == SDL_SCANCODE_ESCAPE)
        {
            *quit = YES;
        }
    }
}

- (void)applicationWillTerminate:(OFNotification*)notification
{
    _commandBuffer = nil;
    _pipeline = nil;
    _device = nil;

    SDL_DestroyWindow(_window);
    SDL_Quit();

    [OFStdOut writeLine:@"Application terminated"];
}

@end
