#import <SDL3/SDL_gpu.h>

#import <UI/ImGUILayer.h>

@interface ImGUILayer (Rendering)

- (void)prepareDrawDataWithCommandBuffer:(SDL_GPUCommandBuffer*)commandBuffer;
- (void)renderDrawDataWithCommandBuffer:(SDL_GPUCommandBuffer*)commandBuffer
                             renderPass:(SDL_GPURenderPass*)renderPass;

@end
