#import <ObjFW/ObjFW.h>
#import <SDL3/SDL_gpu.h>

#import "Device.h"

@implementation Device
+ (instancetype)deviceWithWindow:(SDL_Window*)window
{
    return [[self alloc] initWithWindow:window];
}

- (instancetype)initWithWindow:(SDL_Window*)window
{
    self = [super init];
    if (self)
    {
        _window = window;
        _device = [self createDevice];
        if (_device == NULL)
            return nil;

        [self claimDevice];
    }

    return self;
}

- (SDL_GPUDevice*)createDevice
{
    _device = SDL_CreateGPUDevice(SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_DXIL | SDL_GPU_SHADERFORMAT_MSL, true, NULL);
    if (_device == NULL)
    {
        [OFStdErr writeFormat:@"Failed to create SDL GPU device: %s\n", SDL_GetError()];
        return nil;
    }

    return _device;
}

- (SDL_GPUDevice*)getDevice
{
    return _device;
}

- (void)claimDevice
{
    if (!SDL_ClaimWindowForGPUDevice(_device, _window))
    {
        [OFStdErr writeFormat:@"Failed to claim SDL GPU device: %s\n", SDL_GetError()];
    }
}

- (void)dealloc
{
    if (_device != NULL)
    {
        SDL_DestroyGPUDevice(_device);
        _device = NULL;
    }
}

@end
