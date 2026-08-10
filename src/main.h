#import <ObjFW/ObjFW.h>
#import <SDL3/SDL.h>

#import <Engine.h>

@interface Main : OFObject <OFApplicationDelegate>
@property (nonatomic) Engine* engine;

@end
