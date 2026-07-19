#import <ObjFW/ObjFW.h>
#import <SDL3/SDL_gpu.h>

@interface Device : OFObject
{
    SDL_GPUDevice* _device;
    SDL_Window* _window;
}

+ (instancetype)deviceWithWindow:(SDL_Window*)window;
- (instancetype)initWithWindow:(SDL_Window*)window;

- (SDL_GPUDevice*)getDevice;
- (void)claimDevice;

@end
