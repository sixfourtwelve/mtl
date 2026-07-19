#import "Pipeline.h"
#import <ObjFW/ObjFW.h>
#import <SDL3/SDL.h>

#import "CommandBuffer.h"
#import "Device.h"

@interface Main : OFObject <OFApplicationDelegate>
{
    SDL_Window* _window;
}

@property (nonatomic) Device* device;
@property (nonatomic) CommandBuffer* commandBuffer;
@property (nonatomic) Pipeline* pipeline;

@end
