#import <ObjFW/ObjFW.h>

@class Device;
@class ImGUILayer;
@class Mesh;
@class Pipeline;
@class Window;

@interface GPU : OFObject

+ (instancetype)gpuWithDevice:(Device*)device
                     pipeline:(Pipeline*)pipeline
                     geometry:(Mesh*)geometry
                       window:(Window*)window
                   imguiLayer:(ImGUILayer*)imguiLayer;
- (instancetype)initWithDevice:(Device*)device
                      pipeline:(Pipeline*)pipeline
                      geometry:(Mesh*)geometry
                        window:(Window*)window
                    imguiLayer:(ImGUILayer*)imguiLayer;

- (bool)renderFrame;

@end
