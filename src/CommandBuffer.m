#import "CommandBuffer.h"

@implementation CommandBuffer
+ (instancetype)command:(Device*)device pipeline:(Pipeline*)pipeline window:(SDL_Window*)window
{
    return [[self alloc] initCommand:device pipeline:pipeline window:window];
}

- (instancetype)initCommand:(Device*)device pipeline:(Pipeline*)pipeline window:(SDL_Window*)window
{
    self = [super init];
    if (self)
    {
        _device = device;
        _window = window;
        _pipeline = pipeline;
    }

    return self;
}

- (SDL_GPUCommandBuffer*)acquireCommandBuffer
{
    _commandBuffer = SDL_AcquireGPUCommandBuffer(_device.getDevice);
    if (_commandBuffer == NULL)
    {
        [OFStdErr writeFormat:@"Failed to acquire SDL GPU command buffer: %s\n", SDL_GetError()];
        return nil;
    }
    return _commandBuffer;
}

- (SDL_GPUCommandBuffer*)getCommandBuffer
{
    return _commandBuffer;
}

- (void)acquireSwapchainTexture
{
    if (!SDL_WaitAndAcquireGPUSwapchainTexture(_commandBuffer, _window, &_swapchainTexture, NULL, NULL))
    {
        [OFStdErr writeFormat:@"Failed to acquire SDL GPU swapchain texture: %s\n", SDL_GetError()];
        [OFApplication terminate];
    }
}

// Other shit below

- (void)begin
{
    _commandBuffer = [self acquireCommandBuffer];
    [self acquireSwapchainTexture];

    SDL_GPUColorTargetInfo colorTargetInfo = { 0 };
    colorTargetInfo.texture = _swapchainTexture;
    colorTargetInfo.clear_color = (SDL_FColor) { 0.3f, 0.6f, 0.5f, 1.0f };
    colorTargetInfo.load_op = SDL_GPU_LOADOP_CLEAR;
    colorTargetInfo.store_op = SDL_GPU_STOREOP_STORE;

    _swapchainRenderPass = SDL_BeginGPURenderPass(_commandBuffer, &colorTargetInfo, 1, NULL);
}

- (void)end
{
    SDL_BindGPUGraphicsPipeline(_swapchainRenderPass, _pipeline.getPipeline);
    SDL_DrawGPUPrimitives(_swapchainRenderPass, 3, 1, 0, 0);
    SDL_EndGPURenderPass(_swapchainRenderPass);
}

- (void)submit
{
    SDL_SubmitGPUCommandBuffer(_commandBuffer);
}

@end
