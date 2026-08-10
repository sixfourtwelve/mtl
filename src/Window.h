#import <ObjFW/ObjFW.h>
#import <SDL3/SDL.h>

@interface Window : OFObject

@property (nonatomic, copy) OFString* title;

+ (instancetype)windowWithTitle:(OFString*)title width:(int)width height:(int)height;
- (instancetype)initWithTitle:(OFString*)title width:(int)width height:(int)height;

- (SDL_Window*)getSDLWindow;
@end
