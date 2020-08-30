//
//  Metal.metal
//  Metal-Z
//
//  Created by Markus Moenig on 25/8/20.
//

#include <metal_stdlib>
using namespace metal;

#import "Metal.h"

typedef struct
{
    float4 clipSpacePosition [[position]];
    float2 textureCoordinate;
} RasterizerData;

// Quad Vertex Function
vertex RasterizerData
m4mQuadVertexShader(uint vertexID [[ vertex_id ]],
             constant VertexUniform *vertexArray [[ buffer(0) ]],
             constant vector_uint2 *viewportSizePointer  [[ buffer(1) ]])
{
    RasterizerData out;
    
    float2 pixelSpacePosition = vertexArray[vertexID].position.xy;
    float2 viewportSize = float2(*viewportSizePointer);
    
    out.clipSpacePosition.xy = pixelSpacePosition / (viewportSize / 2.0);
    out.clipSpacePosition.z = 0.0;
    out.clipSpacePosition.w = 1.0;
    
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    return out;
}

// --- SDF utilities

float m4mFillMask(float dist)
{
    return clamp(-dist, 0.0, 1.0);
}

float m4mBorderMask(float dist, float width)
{
    return clamp(dist + width, 0.0, 1.0) - clamp(dist, 0.0, 1.0);
}

float2 m4mRotateCW(float2 pos, float angle)
{
    float ca = cos(angle), sa = sin(angle);
    return pos * float2x2(ca, -sa, sa, ca);
}

// Disc
fragment float4 m4mDiscDrawable(RasterizerData in [[stage_in]],
                               constant DiscUniform *data [[ buffer(0) ]] )
{
    float2 uv = in.textureCoordinate * float2( data->radius * 2 + data->borderSize, data->radius * 2 + data->borderSize);
    uv -= float2( data->radius + data->borderSize / 2 );
    
    float dist = length( uv ) - data->radius;
    
    float4 col = float4( data->fillColor.x, data->fillColor.y, data->fillColor.z, m4mFillMask( dist ) * data->fillColor.w );
    col = mix( col, data->borderColor, m4mBorderMask( dist, data->borderSize ) );
    
    return col;
}

// Box
fragment float4 m4mBoxDrawable(RasterizerData in [[stage_in]],
                               constant BoxUniform *data [[ buffer(0) ]] )
{
    float2 uv = in.textureCoordinate * ( data->size + float2( data->borderSize ) * 2.0 );
    uv -= float2( data->size / 2.0 + data->borderSize );
    
    float2 d = abs( uv ) - data->size / 2 + data->round;
    float dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - data->round;
    
    float4 col = float4( data->fillColor.x, data->fillColor.y, data->fillColor.z, m4mFillMask( dist ) * data->fillColor.w );
    col = mix( col, data->borderColor, m4mBorderMask( dist, data->borderSize ) );
    
    return col;
}

// Rotated Box
fragment float4 m4mBoxDrawableExt(RasterizerData in [[stage_in]],
                               constant BoxUniform *data [[ buffer(0) ]] )
{
    float2 uv = in.textureCoordinate * ( data->size + float2( data->borderSize ) * 2.0 );
    uv -= float2( data->size / 2.0 + data->borderSize );

    uv = m4mRotateCW(uv, data->rotation);
    
    float2 d = abs( uv ) - data->size / 2 + data->round;
    float dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - data->round;
    
    float4 col = float4( data->fillColor.x, data->fillColor.y, data->fillColor.z, m4mFillMask( dist ) * data->fillColor.w );
    col = mix( col, data->borderColor, m4mBorderMask( dist, data->borderSize ) );
    
    return col;
}

// Copy texture
fragment float4 m4mCopyTextureDrawable(RasterizerData in [[stage_in]],
                                constant TextureUniform *data [[ buffer(0) ]],
                                texture2d<half, access::read> inTexture [[ texture(1) ]])
{
    float2 uv = in.textureCoordinate * data->size;
    uv.y = data->size.y - uv.y;
    
    const half4 colorSample = inTexture.read(uint2(uv));
    float4 sample = float4( colorSample );

    sample.w *= data->globalAlpha;

    return float4(sample.x / sample.w, sample.y / sample.w, sample.z / sample.w, sample.w);
}

fragment float4 m4mTextureDrawable(RasterizerData in [[stage_in]],
                                constant TextureUniform *data [[ buffer(0) ]],
                                texture2d<half> inTexture [[ texture(1) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    
    float2 uv = in.textureCoordinate;
    uv.y = 1 - uv.y;
    
    float4 sample = float4(inTexture.sample(textureSampler, uv));
    sample.w *= data->globalAlpha;

    return sample;
}


