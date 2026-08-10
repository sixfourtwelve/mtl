#import <ObjFW/ObjFW.h>
#import <SDL3/SDL.h>
#import <SDL3/SDL_gpu.h>

#import <GPU/Device.h>

struct ShaderDescriptor
{
    OFString* source;
    Uint32 samplerCounts;
    Uint32 uniformBufferCounts;
    Uint32 storageBufferCounts;
    Uint32 storageTextureCounts;
};

@interface Shader : OFObject
{
    SDL_GPUShader* _shader;
}

@property (nonatomic) Device* device;

+ (instancetype)shaderWithDevice:(Device*)device desc:(struct ShaderDescriptor)desc;

- (instancetype)initWithDevice:(Device*)device desc:(struct ShaderDescriptor)desc;

- (SDL_GPUShader*)getShader;

@end
