#import <ObjFW/ObjFW.h>
#import <SDL3/SDL_gpu.h>

#import <GPU/Device.h>
#import <GPU/Shader.h>

@interface Pipeline : OFObject
{
    SDL_GPUGraphicsPipeline* _pipeline;
    SDL_Window* _window;
}

@property (nonatomic) Shader* vertex;
@property (nonatomic) Shader* fragment;
@property (nonatomic) Device* device;

+ (instancetype)pipelineWithDevice:(Device*)device window:(SDL_Window*)window vertex:(Shader*)vertex fragment:(Shader*)fragment;
- (instancetype)initWithDevice:(Device*)device window:(SDL_Window*)window vertex:(Shader*)vertex fragment:(Shader*)fragment;

- (SDL_GPUGraphicsPipeline*)getPipeline;
@end
