#import <GPU/Device.h>
#import <GPU/GeometryVertex.h>
#import <GPU/Pipeline.h>
#import <GPU/Shader.h>

static const SDL_GPUTextureFormat kDepthTextureFormat = SDL_GPU_TEXTUREFORMAT_D16_UNORM;

@implementation Pipeline
{
    Device* _device;
    Shader* _fragment;
    SDL_GPUGraphicsPipeline* _pipeline;
    Shader* _vertex;
    SDL_Window* _window;
}

+ (instancetype)pipelineWithDevice:(Device*)device
                            window:(SDL_Window*)window
                            vertex:(Shader*)vertex
                          fragment:(Shader*)fragment
{
    return [[self alloc] initWithDevice:device window:window vertex:vertex fragment:fragment];
}

- (instancetype)initWithDevice:(Device*)device
                        window:(SDL_Window*)window
                        vertex:(Shader*)vertex
                      fragment:(Shader*)fragment
{
    self = [super init];

    _device = device;
    _window = window;
    _vertex = vertex;
    _fragment = fragment;

    SDL_GPUVertexBufferDescription vertexBufferDescription = { };
    vertexBufferDescription.slot = 0;
    vertexBufferDescription.pitch = sizeof(GeometryVertex);
    vertexBufferDescription.input_rate = SDL_GPU_VERTEXINPUTRATE_VERTEX;

    SDL_GPUVertexAttribute vertexAttributes[2] = { };
    vertexAttributes[0].location = 0;
    vertexAttributes[0].buffer_slot = 0;
    vertexAttributes[0].format = SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3;
    vertexAttributes[0].offset = offsetof(GeometryVertex, position);

    vertexAttributes[1].location = 1;
    vertexAttributes[1].buffer_slot = 0;
    vertexAttributes[1].format = SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3;
    vertexAttributes[1].offset = offsetof(GeometryVertex, color);

    SDL_GPUColorTargetDescription colorTargetDescription = { };
    colorTargetDescription.format = SDL_GetGPUSwapchainTextureFormat([_device getDevice], _window);

    SDL_GPUGraphicsPipelineCreateInfo pipelineInfo = { };
    pipelineInfo.vertex_shader = [_vertex getShader];
    pipelineInfo.fragment_shader = [_fragment getShader];
    pipelineInfo.vertex_input_state.vertex_buffer_descriptions = &vertexBufferDescription;
    pipelineInfo.vertex_input_state.num_vertex_buffers = 1;
    pipelineInfo.vertex_input_state.vertex_attributes = vertexAttributes;
    pipelineInfo.vertex_input_state.num_vertex_attributes = 2;
    pipelineInfo.primitive_type = SDL_GPU_PRIMITIVETYPE_TRIANGLELIST;
    pipelineInfo.rasterizer_state.fill_mode = SDL_GPU_FILLMODE_FILL;
    pipelineInfo.rasterizer_state.enable_depth_clip = true;
    pipelineInfo.multisample_state.sample_count = SDL_GPU_SAMPLECOUNT_1;
    pipelineInfo.depth_stencil_state.compare_op = SDL_GPU_COMPAREOP_LESS_OR_EQUAL;
    pipelineInfo.depth_stencil_state.enable_depth_test = true;
    pipelineInfo.depth_stencil_state.enable_depth_write = true;
    pipelineInfo.target_info.color_target_descriptions = &colorTargetDescription;
    pipelineInfo.target_info.num_color_targets = 1;
    pipelineInfo.target_info.depth_stencil_format = kDepthTextureFormat;
    pipelineInfo.target_info.has_depth_stencil_target = true;

    _pipeline = SDL_CreateGPUGraphicsPipeline([_device getDevice], &pipelineInfo);
    if (_pipeline == NULL)
    {
        [OFStdErr writeFormat:@"Failed to create SDL GPU graphics pipeline: %s\n", SDL_GetError()];
        @throw [OFInitializationFailedException exceptionWithClass:self.class];
    }

    return self;
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
