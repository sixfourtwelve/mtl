#import <SDL3/SDL_gpu.h>

#include <glm/ext/matrix_clip_space.hpp>
#include <glm/ext/matrix_transform.hpp>
#include <glm/geometric.hpp>
#include <glm/trigonometric.hpp>

#include <cmath>

#import <GPU/Device.h>
#import <GPU/GPU.h>
#import <GPU/Mesh.h>
#import <GPU/Pipeline.h>
#import <UI/ImGUILayer+Rendering.h>
#import <Window.h>

namespace
{
static const SDL_GPUTextureFormat kDepthTextureFormat = SDL_GPU_TEXTUREFORMAT_D16_UNORM;

struct alignas(16) TransformUniform
{
    glm::mat4 modelViewProjection;
};

static_assert(sizeof(TransformUniform) == sizeof(float) * 16);

TransformUniform MakeTransformUniform(Uint32 drawableWidth, Uint32 drawableHeight)
{
    const double elapsedSeconds = static_cast<double>(SDL_GetTicksNS()) / 1'000'000'000.0;
    const float rotationRadians = static_cast<float>(std::fmod(elapsedSeconds, 6.283185307179586));
    const float aspectRatio = static_cast<float>(drawableWidth) / static_cast<float>(drawableHeight);

    glm::mat4 model = glm::rotate(
        glm::mat4(1.0f), rotationRadians, glm::normalize(glm::vec3(1.0f, 1.0f, 0.5f)));
    const glm::mat4 view = glm::lookAtLH(
        glm::vec3(0.0f, 0.0f, -3.0f),
        glm::vec3(0.0f, 0.0f, 0.0f),
        glm::vec3(0.0f, 1.0f, 0.0f));
    const glm::mat4 projection = glm::perspectiveLH_ZO(glm::radians(60.0f), aspectRatio, 0.1f, 100.0f);

    return { projection * view * model };
}
}

@implementation GPU
{
    Device* _device;
    SDL_GPUTexture* _depthTexture;
    Uint32 _depthTextureHeight;
    Uint32 _depthTextureWidth;
    Mesh* _geometry;
    ImGUILayer* _imguiLayer;
    Pipeline* _pipeline;
    Window* _window;
}

+ (instancetype)gpuWithDevice:(Device*)device
                     pipeline:(Pipeline*)pipeline
                     geometry:(Mesh*)geometry
                       window:(Window*)window
                   imguiLayer:(ImGUILayer*)imguiLayer
{
    return [[self alloc] initWithDevice:device
                               pipeline:pipeline
                               geometry:geometry
                                 window:window
                             imguiLayer:imguiLayer];
}

- (instancetype)initWithDevice:(Device*)device
                      pipeline:(Pipeline*)pipeline
                      geometry:(Mesh*)geometry
                        window:(Window*)window
                    imguiLayer:(ImGUILayer*)imguiLayer
{
    self = [super init];

    _device = device;
    _pipeline = pipeline;
    _geometry = geometry;
    _window = window;
    _imguiLayer = imguiLayer;

    return self;
}

- (bool)ensureDepthTextureWithWidth:(Uint32)width height:(Uint32)height
{
    if (_depthTexture != NULL && _depthTextureWidth == width && _depthTextureHeight == height)
        return true;

    SDL_GPUTextureCreateInfo textureInfo = { };
    textureInfo.type = SDL_GPU_TEXTURETYPE_2D;
    textureInfo.format = kDepthTextureFormat;
    textureInfo.usage = SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET;
    textureInfo.width = width;
    textureInfo.height = height;
    textureInfo.layer_count_or_depth = 1;
    textureInfo.num_levels = 1;
    textureInfo.sample_count = SDL_GPU_SAMPLECOUNT_1;

    SDL_GPUTexture* newDepthTexture = SDL_CreateGPUTexture([_device getDevice], &textureInfo);
    if (newDepthTexture == NULL)
    {
        [OFStdErr writeFormat:@"Failed to create depth texture: %s\n", SDL_GetError()];
        return false;
    }

    if (_depthTexture != NULL)
        SDL_ReleaseGPUTexture([_device getDevice], _depthTexture);

    _depthTexture = newDepthTexture;
    _depthTextureWidth = width;
    _depthTextureHeight = height;
    return true;
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
    Uint32 drawableWidth = 0;
    Uint32 drawableHeight = 0;
    if (!SDL_WaitAndAcquireGPUSwapchainTexture(commandBuffer,
            [_window getSDLWindow],
            &swapchainTexture,
            &drawableWidth,
            &drawableHeight))
    {
        [OFStdErr writeFormat:@"Failed to acquire SDL GPU swapchain texture: %s\n", SDL_GetError()];
        SDL_CancelGPUCommandBuffer(commandBuffer);
        return false;
    }

    if (swapchainTexture == NULL)
    {
        SDL_CancelGPUCommandBuffer(commandBuffer);
        return true;
    }

    if (drawableWidth == 0 || drawableHeight == 0 || ![self ensureDepthTextureWithWidth:drawableWidth height:drawableHeight])
    {
        SDL_SubmitGPUCommandBuffer(commandBuffer);
        return false;
    }

    // ImGui uploads use a copy pass, so they must happen before either render pass.
    [_imguiLayer prepareDrawDataWithCommandBuffer:commandBuffer];

    const TransformUniform transform = MakeTransformUniform(drawableWidth, drawableHeight);
    SDL_PushGPUVertexUniformData(commandBuffer, 0, &transform, sizeof(transform));

    SDL_GPUColorTargetInfo colorTargetInfo = { };
    colorTargetInfo.texture = swapchainTexture;
    colorTargetInfo.clear_color = (SDL_FColor) { 0.08f, 0.09f, 0.12f, 1.0f };
    colorTargetInfo.load_op = SDL_GPU_LOADOP_CLEAR;
    colorTargetInfo.store_op = SDL_GPU_STOREOP_STORE;

    SDL_GPUDepthStencilTargetInfo depthTargetInfo = { };
    depthTargetInfo.texture = _depthTexture;
    depthTargetInfo.clear_depth = 1.0f;
    depthTargetInfo.load_op = SDL_GPU_LOADOP_CLEAR;
    depthTargetInfo.store_op = SDL_GPU_STOREOP_DONT_CARE;
    depthTargetInfo.stencil_load_op = SDL_GPU_LOADOP_DONT_CARE;
    depthTargetInfo.stencil_store_op = SDL_GPU_STOREOP_DONT_CARE;
    depthTargetInfo.cycle = true;

    SDL_GPURenderPass* geometryPass = SDL_BeginGPURenderPass(commandBuffer, &colorTargetInfo, 1, &depthTargetInfo);
    SDL_BindGPUGraphicsPipeline(geometryPass, [_pipeline getPipeline]);

    SDL_GPUBufferBinding vertexBinding = {
        .buffer = [_geometry getVertexBuffer],
        .offset = 0,
    };
    SDL_BindGPUVertexBuffers(geometryPass, 0, &vertexBinding, 1);
    SDL_DrawGPUPrimitives(geometryPass, _geometry.vertexCount, 1, 0, 0);
    SDL_EndGPURenderPass(geometryPass);

    // Draw UI as an overlay without attaching the geometry depth texture.
    colorTargetInfo.load_op = SDL_GPU_LOADOP_LOAD;
    SDL_GPURenderPass* uiPass = SDL_BeginGPURenderPass(commandBuffer, &colorTargetInfo, 1, NULL);
    [_imguiLayer renderDrawDataWithCommandBuffer:commandBuffer renderPass:uiPass];
    SDL_EndGPURenderPass(uiPass);

    if (!SDL_SubmitGPUCommandBuffer(commandBuffer))
    {
        [OFStdErr writeFormat:@"Failed to submit SDL GPU command buffer: %s\n", SDL_GetError()];
        return false;
    }

    return true;
}

- (void)dealloc
{
    if (_depthTexture != NULL)
    {
        SDL_ReleaseGPUTexture([_device getDevice], _depthTexture);
        _depthTexture = NULL;
    }
}

@end
