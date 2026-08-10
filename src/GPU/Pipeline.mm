#import <ObjFW/ObjFW.h>
#import <SDL3/SDL_gpu.h>

#import <GPU/Pipeline.h>

@implementation Pipeline
+ (instancetype)pipelineWithDevice:(Device*)device window:(SDL_Window*)window vertex:(Shader*)vertex fragment:(Shader*)fragment
{
    return [[self alloc] initWithDevice:device window:window vertex:vertex fragment:fragment];
}

- (instancetype)initWithDevice:(Device*)device window:(SDL_Window*)window vertex:(Shader*)vertex fragment:(Shader*)fragment
{
    self = [super init];
    if (self)
    {
        _device = device;
        _window = window;
        _vertex = vertex;
        _fragment = fragment;
        _pipeline = [self createPipeline];
    }

    return self;
}

- (SDL_GPUGraphicsPipeline*)createPipeline
{
    SDL_GPUGraphicsPipelineCreateInfo pipelineCreateInfo = {
        .vertex_shader = [_vertex getShader],
        .fragment_shader = [_fragment getShader],
        .primitive_type = SDL_GPU_PRIMITIVETYPE_TRIANGLELIST,
        .rasterizer_state = { .fill_mode = SDL_GPU_FILLMODE_FILL },
        .target_info = (SDL_GPUGraphicsPipelineTargetInfo) {
            .color_target_descriptions = (SDL_GPUColorTargetDescription[]) {
                {
                    .format = SDL_GetGPUSwapchainTextureFormat([_device getDevice], _window),
                },
            },
            .num_color_targets = 1,
        },
    };

    _pipeline = SDL_CreateGPUGraphicsPipeline([_device getDevice], &pipelineCreateInfo);
    if (_pipeline == NULL)
    {
        [OFStdErr writeFormat:@"Failed to create SDL GPU graphics pipeline: %s\n", SDL_GetError()];
        return nil;
    }

    return _pipeline;
}

- (SDL_GPUGraphicsPipeline*)getPipeline
{
    return _pipeline;
}

- (void)dealloc
{
    if (_pipeline != NULL)
    {
        SDL_ReleaseGPUGraphicsPipeline([_device getDevice], _pipeline);
        _pipeline = NULL;
    }
}

@end
