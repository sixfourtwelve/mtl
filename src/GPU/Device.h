#import <ObjFW/ObjFW.h>
#import <SDL3/SDL_gpu.h>

@interface Device : OFObject

+ (instancetype)deviceWithWindow:(SDL_Window*)window;
- (instancetype)initWithWindow:(SDL_Window*)window;

- (SDL_GPUDevice*)getDevice;

@end
