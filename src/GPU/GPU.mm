#import <SDL3/SDL_gpu.h>
#include <imgui.h>

#import <GPU/Device.h>
#import <GPU/Pipeline.h>
#import <GPU/GPU.h>
#import <UI/ImGUILayer+Rendering.h>
#import <Window.h>

@implementation GPU
{
    Device* _device;
    Pipeline* _pipeline;
    Window* _window;
    ImGUILayer* _imguiLayer;
}

+ (instancetype)gpuWithDevice:(Device*)device
                          pipeline:(Pipeline*)pipeline
                            window:(Window*)window
                        imguiLayer:(ImGUILayer*)imguiLayer
{
    return [[self alloc] initWithDevice:device
                               pipeline:pipeline
                                 window:window
                             imguiLayer:imguiLayer];
}

- (instancetype)initWithDevice:(Device*)device
                      pipeline:(Pipeline*)pipeline
                        window:(Window*)window
                    imguiLayer:(ImGUILayer*)imguiLayer
{
    self = [super init];

    _device = device;
    _pipeline = pipeline;
    _window = window;
    _imguiLayer = imguiLayer;

    return self;
}

- (bool)renderFrame
{
    SDL_GPUCommandBuffer* commandBuffer = SDL_AcquireGPUCommandBuffer([_device getDevice]);
    if (commandBuffer == NULL)
    {
        [OFStdErr writeFormat:@"Failed to acquire SDL GPU command buffer: %s\n", SDL_GetError()];
        return false;
    }

    SDL_GPUTexture* swapchainTexture = NULL;
    if (!SDL_WaitAndAcquireGPUSwapchainTexture(
            commandBuffer, [_window getSDLWindow], &swapchainTexture, NULL, NULL))
    {
        [OFStdErr writeFormat:@"Failed to acquire SDL GPU swapchain texture: %s\n", SDL_GetError()];
        SDL_CancelGPUCommandBuffer(commandBuffer);
        return false;
    }

    // A null texture is expected while the window is minimized. The command
    // buffer must still be submitted after acquiring the swapchain.
    if (swapchainTexture != NULL)
    {
        // SDL_GPU requires ImGui uploads before a render pass begins.
        [_imguiLayer prepareDrawDataWithCommandBuffer:commandBuffer];

        SDL_GPUColorTargetInfo colorTargetInfo = { };
        colorTargetInfo.texture = swapchainTexture;
        colorTargetInfo.clear_color = (SDL_FColor) { 0.3f, 0.6f, 0.5f, 1.0f };
        colorTargetInfo.load_op = SDL_GPU_LOADOP_CLEAR;
        colorTargetInfo.store_op = SDL_GPU_STOREOP_STORE;

        SDL_GPURenderPass* renderPass = SDL_BeginGPURenderPass(commandBuffer, &colorTargetInfo, 1, NULL);

        SDL_BindGPUGraphicsPipeline(renderPass, [_pipeline getPipeline]);
        SDL_DrawGPUPrimitives(renderPass, 3, 1, 0, 0);

        [_imguiLayer renderDrawDataWithCommandBuffer:commandBuffer renderPass:renderPass];
        SDL_EndGPURenderPass(renderPass);
    }

    if (!SDL_SubmitGPUCommandBuffer(commandBuffer))
    {
        [OFStdErr writeFormat:@"Failed to submit SDL GPU command buffer: %s\n", SDL_GetError()];
        return false;
    }

    return true;
}

@end
