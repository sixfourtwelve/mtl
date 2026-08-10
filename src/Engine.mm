#import <SDL3/SDL.h>
#include <imgui.h>

#import <Engine.h>
#import <GPU/Device.h>
#import <GPU/GPU.h>
#import <GPU/Mesh.h>
#import <GPU/Pipeline.h>
#import <GPU/Primitives/CubeGeometry.h>
#import <GPU/Shader.h>
#import <Input/KeyController.h>
#import <UI/ImGUILayer.h>
#import <Window.h>

@implementation Engine
{
    Device* _device;
    Pipeline* _geometryPipeline;
    GPU* _gpu;
    ImGUILayer* _imguiLayer;
    KeyController* _keyController;
    Mesh* _spinningCube;
    Window* _window;
    bool _isShutdown;
}

+ (instancetype)engine
{
    return [[self alloc] init];
}

- (instancetype)init
{
    self = [super init];

    _window = [Window windowWithTitle:@"ObjFW SDL3 Example" width:1920 height:1080];
    _keyController = [KeyController keyController];
    _device = [Device deviceWithWindow:[_window getSDLWindow]];
    _imguiLayer = [ImGUILayer layerWithWindow:_window device:_device];

    return self;
}

- (void)setupGPU
{
    ShaderDescriptor vertexShaderDescriptor = {
        .source = @"cube.vert",
        .samplerCounts = 0,
        .uniformBufferCounts = 1,
        .storageBufferCounts = 0,
        .storageTextureCounts = 0
    };
    Shader* vertexShader =
        [Shader shaderWithDevice:_device
                            desc:vertexShaderDescriptor];

    ShaderDescriptor fragmentShaderDescriptor = {
        .source = @"cube.frag",
        .samplerCounts = 0,
        .uniformBufferCounts = 0,
        .storageBufferCounts = 0,
        .storageTextureCounts = 0
    };
    Shader* fragmentShader =
        [Shader shaderWithDevice:_device
                            desc:fragmentShaderDescriptor];

    _geometryPipeline = [Pipeline pipelineWithDevice:_device
                                              window:[_window getSDLWindow]
                                              vertex:vertexShader
                                            fragment:fragmentShader];
    _spinningCube = [Mesh meshWithDevice:_device
                                vertices:kCubeVertices
                             vertexCount:kCubeVertexCount];

    _gpu = [GPU gpuWithDevice:_device
                     pipeline:_geometryPipeline
                     geometry:_spinningCube
                       window:_window
                   imguiLayer:_imguiLayer];
}

- (void)go
{
    @try
    {
        [self setupGPU];
        [self loop];
    }
    @finally
    {
        [self shutdown];
    }
}

- (void)loop
{
    bool quit = false;
    while (!quit)
    {
        @autoreleasepool
        {
            SDL_Event event;
            while (SDL_PollEvent(&event))
            {
                [_imguiLayer processEvent:&event];
                [_keyController handleEvent:&event quit:&quit];
            }

            if (quit)
                continue;

            if (SDL_GetWindowFlags([_window getSDLWindow]) & SDL_WINDOW_MINIMIZED)
            {
                SDL_Delay(10);
                continue;
            }

            [_imguiLayer beginFrame];
            ImGui::ShowDemoWindow();
            [_imguiLayer endFrame];

            if (![_gpu renderFrame])
                quit = true;
        }
    }
}

- (void)shutdown
{
    if (_isShutdown)
        return;

    _isShutdown = true;

    _gpu = nil;
    _imguiLayer = nil;
    _spinningCube = nil;
    _geometryPipeline = nil;
    _device = nil;
    _window = nil;

    SDL_Quit();
}

- (void)dealloc
{
    [self shutdown];
}

@end
