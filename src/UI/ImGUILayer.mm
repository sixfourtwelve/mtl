#import <imgui.h>
#import <imgui_impl_sdl3.h>
#import <imgui_impl_sdlgpu3.h>

#import <GPU/Device.h>
#import <UI/ImGUILayer+Rendering.h>
#import <Window.h>

@implementation ImGUILayer
{
    Device* _device;
    Window* _window;
    bool _platformBackendInitialized;
    bool _rendererBackendInitialized;
}

+ (instancetype)layerWithWindow:(Window*)window device:(Device*)device
{
    return [[self alloc] initWithWindow:window device:device];
}

- (instancetype)initWithWindow:(Window*)window device:(Device*)device
{
    self = [super init];

    _window = window;
    _device = device;

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGui::GetIO().ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;

    _platformBackendInitialized = ImGui_ImplSDL3_InitForSDLGPU([_window getSDLWindow]);
    if (!_platformBackendInitialized)
    {
        [OFStdErr writeFormat:@"Failed to initialize the ImGui SDL3 backend: %s\n", SDL_GetError()];
        @throw [OFInitializationFailedException exceptionWithClass:self.class];
    }

    ImGui_ImplSDLGPU3_InitInfo initInfo = { };
    initInfo.Device = [_device getDevice];
    initInfo.ColorTargetFormat =
        SDL_GetGPUSwapchainTextureFormat([_device getDevice], [_window getSDLWindow]);

    _rendererBackendInitialized = ImGui_ImplSDLGPU3_Init(&initInfo);
    if (!_rendererBackendInitialized)
    {
        [OFStdErr writeFormat:@"Failed to initialize the ImGui SDL GPU backend: %s\n", SDL_GetError()];
        @throw [OFInitializationFailedException exceptionWithClass:self.class];
    }

    return self;
}

- (void)processEvent:(const SDL_Event*)event
{
    ImGui_ImplSDL3_ProcessEvent(event);
}

- (void)beginFrame
{
    ImGui_ImplSDLGPU3_NewFrame();
    ImGui_ImplSDL3_NewFrame();
    ImGui::NewFrame();
}

- (void)endFrame
{
    ImGui::Render();
}

- (void)dealloc
{
    if (_rendererBackendInitialized)
    {
        ImGui_ImplSDLGPU3_Shutdown();
        _rendererBackendInitialized = false;
    }

    if (_platformBackendInitialized)
    {
        ImGui_ImplSDL3_Shutdown();
        _platformBackendInitialized = false;
    }

    if (ImGui::GetCurrentContext() != NULL)
        ImGui::DestroyContext();
}

@end

@implementation ImGUILayer (Rendering)

- (void)prepareDrawDataWithCommandBuffer:(SDL_GPUCommandBuffer*)commandBuffer
{
    ImGui_ImplSDLGPU3_PrepareDrawData(ImGui::GetDrawData(), commandBuffer);
}

- (void)renderDrawDataWithCommandBuffer:(SDL_GPUCommandBuffer*)commandBuffer
                             renderPass:(SDL_GPURenderPass*)renderPass
{
    ImGui_ImplSDLGPU3_RenderDrawData(ImGui::GetDrawData(), commandBuffer, renderPass);
}

@end
