#import <ObjFW/ObjFW.h>
#import <SDL3/SDL_events.h>

@interface KeyController : OFObject

+ (instancetype)keyController;
- (void)handleEvent:(const SDL_Event*)event quit:(bool*)quit;

@end
