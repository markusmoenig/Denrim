//
//  Metal.h
//  Metal-Z
//
//  Created by Markus Moenig on 25/8/20.
//

#ifndef Metal_h
#define Metal_h

#include <simd/simd.h>

typedef struct
{
    vector_float2   position;
    vector_float2   textureCoordinate;
} VertexUniform;

typedef struct
{
    vector_float2   screenSize;
    vector_float2   pos;
    vector_float2   size;
    float           globalAlpha;
    
    int             mirrorX;

} TextureUniform;

typedef struct
{
    vector_float4   fillColor;
    vector_float4   borderColor;
    float           radius;
    float           borderSize;
    float           rotation;
    float           onion;
    
    int             hasTexture;
    vector_float2   textureSize;
} DiscUniform;

typedef struct
{
    vector_float2   screenSize;
    vector_float2   pos;
    vector_float2   size;
    float           round;
    float           borderSize;
    vector_float4   fillColor;
    vector_float4   borderColor;
    float           rotation;
    float           onion;
    
    int             mirrorX;
    int             mirrorY;

    int             hasTexture;
    vector_float2   textureSize;
    vector_float2   checkerSize;

} BoxUniform;

typedef struct
{
    vector_float2   atlasSize;
    vector_float2   fontPos;
    vector_float2   fontSize;
    vector_float4   color;
} TextUniform;

typedef struct
{
    vector_float2   screenSize;
    vector_float2   offset;
    float           gridSize;
    float           scale;
} GridUniform;

typedef struct
{
    //vector_bool       boolData[10];
    int             intData[10];
    float           floatData[10];
    simd_float2     float2Data[10];
    simd_float3     float3Data[10];
    simd_float4     float4Data[10];
} BehaviorData;

#endif /* Metal_h */
