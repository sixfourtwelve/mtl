#import <GPU/Device.h>

@implementation Device
{
    SDL_GPUDevice* _device;
    SDL_Window* _window;
    bool _windowClaimed;
}

+ (instancetype)deviceWithWindow:(SDL_Window*)window
{
    return [[self alloc] initWithWindow:window];
}

- (instancetype)initWithWindow:(SDL_Window*)window
{
    self = [super init];
    _window = window;

    _device = SDL_CreateGPUDevice(
        SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_DXIL |
            SDL_GPU_SHADERFORMAT_MSL,
        true,
        NULL);
    if (_device == NULL)
    {
        [OFStdErr writeFormat:@"Failed to create SDL GPU device: %s\n", SDL_GetError()];
        @throw [OFInitializationFailedException exceptionWithClass:self.class];
    }

    _windowClaimed = SDL_ClaimWindowForGPUDevice(_device, _window);
    if (!_windowClaimed)
    {
        [OFStdErr writeFormat:@"Failed to claim window for SDL GPU device: %s\n", SDL_GetError()];
        @throw [OFInitializationFailedException exceptionWithClass:self.class];
    }

    return self;
}

- (SDL_GPUDevice*)getDevice
{
    return _device;
}

- (void)dealloc
{
    if (_device == NULL)
        return;

    if (!SDL_WaitForGPUIdle(_device))
        [OFStdErr writeFormat:@"Failed to wait for the SDL GPU device: %s\n", SDL_GetError()];

    if (_windowClaimed)
    {
        SDL_ReleaseWindowFromGPUDevice(_device, _window);
        _windowClaimed = false;
    }

    SDL_DestroyGPUDevice(_device);
    _device = NULL;
}

@end
