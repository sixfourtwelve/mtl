#import <ObjFW/ObjFW.h>
#import <SDL3/SDL_gpu.h>

#import <GPU/GeometryVertex.h>

@class Device;

@interface Mesh : OFObject

@property (nonatomic, readonly) Uint32 vertexCount;

+ (instancetype)meshWithDevice:(Device*)device
                      vertices:(const GeometryVertex*)vertices
                   vertexCount:(Uint32)vertexCount;
- (instancetype)initWithDevice:(Device*)device
                      vertices:(const GeometryVertex*)vertices
                   vertexCount:(Uint32)vertexCount;

- (SDL_GPUBuffer*)getVertexBuffer;

@end
