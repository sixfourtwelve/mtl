#import <GPU/Device.h>
#import <GPU/Mesh.h>

@implementation Mesh
{
    Device* _device;
    SDL_GPUBuffer* _vertexBuffer;
}

+ (instancetype)meshWithDevice:(Device*)device
                      vertices:(const GeometryVertex*)vertices
                   vertexCount:(Uint32)vertexCount
{
    return [[self alloc] initWithDevice:device vertices:vertices vertexCount:vertexCount];
}

- (instancetype)initWithDevice:(Device*)device
                      vertices:(const GeometryVertex*)vertices
                   vertexCount:(Uint32)vertexCount
{
    self = [super init];

    if (vertices == NULL || vertexCount == 0 || vertexCount > SDL_MAX_UINT32 / sizeof(GeometryVertex))
        @throw [OFInvalidArgumentException exception];

    _device = device;
    _vertexCount = vertexCount;

    const Uint32 dataSize = vertexCount * sizeof(GeometryVertex);
    SDL_GPUBufferCreateInfo bufferInfo = { };
    bufferInfo.usage = SDL_GPU_BUFFERUSAGE_VERTEX;
    bufferInfo.size = dataSize;

    _vertexBuffer = SDL_CreateGPUBuffer([_device getDevice], &bufferInfo);
    if (_vertexBuffer == NULL)
    {
        [OFStdErr writeFormat:@"Failed to create mesh vertex buffer: %s\n", SDL_GetError()];
        @throw [OFInitializationFailedException exceptionWithClass:self.class];
    }

    SDL_GPUTransferBufferCreateInfo transferBufferInfo = { };
    transferBufferInfo.usage = SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;
    transferBufferInfo.size = dataSize;

    SDL_GPUTransferBuffer* transferBuffer = SDL_CreateGPUTransferBuffer([_device getDevice], &transferBufferInfo);
    if (transferBuffer == NULL)
    {
        [OFStdErr writeFormat:@"Failed to create mesh transfer buffer: %s\n", SDL_GetError()];
        @throw [OFInitializationFailedException exceptionWithClass:self.class];
    }

    void* mappedData = SDL_MapGPUTransferBuffer([_device getDevice], transferBuffer, false);
    if (mappedData == NULL)
    {
        [OFStdErr writeFormat:@"Failed to map mesh transfer buffer: %s\n", SDL_GetError()];
        SDL_ReleaseGPUTransferBuffer([_device getDevice], transferBuffer);
        @throw [OFInitializationFailedException exceptionWithClass:self.class];
    }

    SDL_memcpy(mappedData, vertices, dataSize);
    SDL_UnmapGPUTransferBuffer([_device getDevice], transferBuffer);

    SDL_GPUCommandBuffer* commandBuffer = SDL_AcquireGPUCommandBuffer([_device getDevice]);
    if (commandBuffer == NULL)
    {
        [OFStdErr writeFormat:@"Failed to acquire mesh upload command buffer: %s\n", SDL_GetError()];
        SDL_ReleaseGPUTransferBuffer([_device getDevice], transferBuffer);
        @throw [OFInitializationFailedException exceptionWithClass:self.class];
    }

    SDL_GPUCopyPass* copyPass = SDL_BeginGPUCopyPass(commandBuffer);
    SDL_GPUTransferBufferLocation source = {
        .transfer_buffer = transferBuffer,
        .offset = 0,
    };
    SDL_GPUBufferRegion destination = {
        .buffer = _vertexBuffer,
        .offset = 0,
        .size = dataSize,
    };

    SDL_UploadToGPUBuffer(copyPass, &source, &destination, false);
    SDL_EndGPUCopyPass(copyPass);

    const bool submitted = SDL_SubmitGPUCommandBuffer(commandBuffer);
    SDL_ReleaseGPUTransferBuffer([_device getDevice], transferBuffer);

    if (!submitted)
    {
        [OFStdErr writeFormat:@"Failed to submit mesh upload: %s\n", SDL_GetError()];
        @throw [OFInitializationFailedException exceptionWithClass:self.class];
    }

    return self;
}

- (SDL_GPUBuffer*)getVertexBuffer
{
    return _vertexBuffer;
}

- (void)dealloc
{
    if (_vertexBuffer != NULL)
    {
        SDL_ReleaseGPUBuffer([_device getDevice], _vertexBuffer);
        _vertexBuffer = NULL;
    }
}

@end
