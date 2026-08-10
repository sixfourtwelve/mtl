#include "cube.hlsli"

cbuffer TransformData : register(b0, space1)
{
    float4x4 ModelViewProjection;
};

VertexOutput main(VertexInput input)
{
    VertexOutput output;
    output.Position = mul(ModelViewProjection, float4(input.Position, 1.0f));
    output.Color = float4(input.Color, 1.0f);
    return output;
}
