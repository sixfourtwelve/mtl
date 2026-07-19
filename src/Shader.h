#import <ObjFW/ObjFW.h>
#import <SDL3/SDL.h>
#import <SDL3/SDL_gpu.h>

#import "Device.h"

@interface Shader : OFObject
{
    SDL_GPUShader* _shader;
}

@property (nonatomic) Device* device;

+ (instancetype)shaderWithDevice:(Device*)device
                          source:(OFString*)source
                   samplerCounts:(Uint32)samplerCounts
             uniformBufferCounts:(Uint32)uniformBufferCounts
             storageBufferCounts:(Uint32)storageBufferCounts
            storageTextureCounts:(Uint32)storageTextureCounts;

- (instancetype)initWithDevice:(Device*)device
                        source:(OFString*)source
                 samplerCounts:(Uint32)samplerCounts
           uniformBufferCounts:(Uint32)uniformBufferCounts
           storageBufferCounts:(Uint32)storageBufferCounts
          storageTextureCounts:(Uint32)storageTextureCounts;

- (SDL_GPUShader*)getShader;

@end
