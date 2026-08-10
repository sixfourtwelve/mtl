#import <ObjFW/ObjFW.h>
#import <SDL3/SDL_events.h>

@class Device;
@class Window;

@interface ImGUILayer : OFObject

+ (instancetype)layerWithWindow:(Window*)window device:(Device*)device;
- (instancetype)initWithWindow:(Window*)window device:(Device*)device;

- (void)processEvent:(const SDL_Event*)event;
- (void)beginFrame;
- (void)endFrame;

@end
