#import <ObjFW/ObjFW.h>
#import <SDL3/SDL_gpu.h>

@class Device;
@class Shader;

@interface Pipeline : OFObject

+ (instancetype)pipelineWithDevice:(Device*)device
                            window:(SDL_Window*)window
                            vertex:(Shader*)vertex
                          fragment:(Shader*)fragment;
- (instancetype)initWithDevice:(Device*)device
                        window:(SDL_Window*)window
                        vertex:(Shader*)vertex
                      fragment:(Shader*)fragment;

- (SDL_GPUGraphicsPipeline*)getPipeline;

@end
