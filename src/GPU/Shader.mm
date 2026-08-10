#import <ObjFW/ObjFW.h>
#import <SDL3/SDL_gpu.h>

#import <GPU/Shader.h>

@implementation Shader

+ (instancetype)shaderWithDevice:(Device*)device desc:(struct ShaderDescriptor)desc;
{
    return [[self alloc] initWithDevice:device desc:desc];
}

- (instancetype)initWithDevice:(Device*)device desc:(struct ShaderDescriptor)desc;
{
    self = [super init];
    if (self)
    {
        _device = device;

        const char* basePath = SDL_GetBasePath();
        const char* shaderFilename = [desc.source UTF8String];
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
        const char* formatDirectory;
        const char* fileExtension;
        const char* entrypoint;

        if (backendFormats & SDL_GPU_SHADERFORMAT_SPIRV)
        {
            format = SDL_GPU_SHADERFORMAT_SPIRV;
            formatDirectory = "spirv";
            fileExtension = "spv";
            entrypoint = "main";
        }
        else if (backendFormats & SDL_GPU_SHADERFORMAT_MSL)
        {
            format = SDL_GPU_SHADERFORMAT_MSL;
            formatDirectory = "msl";
            fileExtension = "msl";
            entrypoint = "main0";
        }
        else if (backendFormats & SDL_GPU_SHADERFORMAT_DXIL)
        {
            format = SDL_GPU_SHADERFORMAT_DXIL;
            formatDirectory = "dxil";
            fileExtension = "dxil";
            entrypoint = "main";
        }
        else
        {
            SDL_Log("%s", "Unrecognized backend shader format!");
            return NULL;
        }

        SDL_snprintf(fullPath,
            sizeof(fullPath),
            "%sassets/shaders/%s/%s.%s",
            basePath,
            formatDirectory,
            shaderFilename,
            fileExtension);

        size_t codeSize;
        void* code = SDL_LoadFile(fullPath, &codeSize);
        if (code == NULL)
        {
            SDL_Log("Failed to load shader from disk! %s", fullPath);
            return NULL;
        }

        SDL_GPUShaderCreateInfo shaderInfo = {
            .code_size = codeSize,
            .code = (const Uint8*)code,
            .entrypoint = entrypoint,
            .format = format,
            .stage = stage,
            .num_samplers = desc.samplerCounts,
            .num_storage_textures = desc.storageTextureCounts,
            .num_storage_buffers = desc.storageBufferCounts,
            .num_uniform_buffers = desc.uniformBufferCounts
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
