#import "Pipeline.h"
#import <ObjFW/ObjFW.h>
#import <SDL3/SDL_gpu.h>

#import "Device.h"

@interface CommandBuffer : OFObject
{
    SDL_GPUCommandBuffer* _commandBuffer;
    SDL_Window* _window;
    SDL_GPUTexture* _swapchainTexture;
    SDL_GPURenderPass* _swapchainRenderPass;
}

@property (nonatomic) Device* device;
@property (nonatomic) Pipeline* pipeline;

+ (instancetype)command:(Device*)device pipeline:(Pipeline*)pipeline window:(SDL_Window*)window;
- (instancetype)initCommand:(Device*)device pipeline:(Pipeline*)pipeline window:(SDL_Window*)window;
- (SDL_GPUCommandBuffer*)getCommandBuffer;

- (void)begin;
- (void)end;
- (void)submit;

@end
