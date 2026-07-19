#import <ObjFW/ObjFW.h>
#import <SDL3/SDL_gpu.h>

#import "Shader.h"

@implementation Shader

+ (instancetype)shaderWithDevice:(Device*)device
                          source:(OFString*)source
                   samplerCounts:(Uint32)samplerCounts
             uniformBufferCounts:(Uint32)uniformBufferCounts
             storageBufferCounts:(Uint32)storageBufferCounts
            storageTextureCounts:(Uint32)storageTextureCounts
{
    return [[self alloc] initWithDevice:device
                                 source:source
                          samplerCounts:samplerCounts
                    uniformBufferCounts:uniformBufferCounts
                    storageBufferCounts:storageBufferCounts
                   storageTextureCounts:storageTextureCounts];
}

- (instancetype)initWithDevice:(Device*)device
                        source:(OFString*)source
                 samplerCounts:(Uint32)samplerCounts
           uniformBufferCounts:(Uint32)uniformBufferCounts
           storageBufferCounts:(Uint32)storageBufferCounts
          storageTextureCounts:(Uint32)storageTextureCounts
{
    self = [super init];
    if (self)
    {
        _device = device;

        const char* basePath = SDL_GetBasePath();
        const char* shaderFilename = [source UTF8String];
        SDL_GPUShaderStage stage;
        if (SDL_strstr(shaderFilename, ".vert"))
        {
            stage = SDL_GPU_SHADERSTAGE_VERTEX;
        }
        else if (SDL_strstr(shaderFilename, ".frag"))
        {
            stage = SDL_GPU_SHADERSTAGE_FRAGMENT;
        }
        else
        {
            SDL_Log("Invalid shader stage!");
            return NULL;
        }

        char fullPath[256];
        SDL_GPUShaderFormat backendFormats = SDL_GetGPUShaderFormats([_device getDevice]);
        SDL_GPUShaderFormat format = SDL_GPU_SHADERFORMAT_INVALID;
        const char* entrypoint;

        if (backendFormats & SDL_GPU_SHADERFORMAT_SPIRV)
        {
            SDL_snprintf(fullPath, sizeof(fullPath), "%sassets/shaders/%s.spv", basePath, shaderFilename);
            format = SDL_GPU_SHADERFORMAT_SPIRV;
            entrypoint = "main";
        }
        else if (backendFormats & SDL_GPU_SHADERFORMAT_MSL)
        {
            SDL_snprintf(fullPath, sizeof(fullPath), "%sassets/shaders/%s.msl", basePath, shaderFilename);
            format = SDL_GPU_SHADERFORMAT_MSL;
            entrypoint = "main0";
        }
        else if (backendFormats & SDL_GPU_SHADERFORMAT_DXIL)
        {
            SDL_snprintf(fullPath, sizeof(fullPath), "%sassets/shaders/%s.dxil", basePath, shaderFilename);
            format = SDL_GPU_SHADERFORMAT_DXIL;
            entrypoint = "main";
        }
        else
        {
            SDL_Log("%s", "Unrecognized backend shader format!");
            return NULL;
        }

        size_t codeSize;
        void* code = SDL_LoadFile(fullPath, &codeSize);
        if (code == NULL)
        {
            SDL_Log("Failed to load shader from disk! %s", fullPath);
            return NULL;
        }

        SDL_GPUShaderCreateInfo shaderInfo = {
            .code = (const Uint8*)code,
            .code_size = codeSize,
            .entrypoint = entrypoint,
            .format = format,
            .stage = stage,
            .num_samplers = samplerCounts,
            .num_uniform_buffers = uniformBufferCounts,
            .num_storage_buffers = storageBufferCounts,
            .num_storage_textures = storageTextureCounts
        };

        _shader = SDL_CreateGPUShader([device getDevice], &shaderInfo);
        if (_shader == NULL)
        {
            SDL_Log("Failed to create shader! %s", SDL_GetError());
            SDL_free(code);
            return NULL;
        }

        SDL_free(code);
    }

    return self;
}

- (SDL_GPUShader*)getShader
{
    return _shader;
}

- (void)dealloc
{
    if (_shader != NULL)
    {
        SDL_ReleaseGPUShader([_device getDevice], _shader);
        _shader = NULL;
    }
}

@end
