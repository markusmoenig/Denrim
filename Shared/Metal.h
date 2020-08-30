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
    vector_float4   fillColor;
    vector_float4   borderColor;
    float           radius, borderSize;
} DiscUniform;

typedef struct
{
    vector_float2   screenSize;
    vector_float2   pos;
    vector_float2   size;
    float           globalAlpha;

} TextureUniform;

typedef struct
{
    vector_float2   pos;
    vector_float2   size;
    vector_float2   size2;
    float           round, borderSize;
    vector_float4   fillColor;
    vector_float4   borderColor;
    float           rotation;

} BoxUniform;

#endif /* Metal_h */
