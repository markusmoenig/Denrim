//
//  DenrimDesktop.h
//  DenrimDesktop
//
//  Created by Markus Moenig on 9/11/20.
//

#import <Foundation/Foundation.h>

//! Project version number for DenrimDesktop.
FOUNDATION_EXPORT double DenrimDesktopVersionNumber;

//! Project version string for DenrimDesktop.
FOUNDATION_EXPORT const unsigned char DenrimDesktopVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <DenrimDesktop/PublicHeader.h>

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
    //vector_bool       boolData[10];
    int             intData[10];
    float           floatData[10];
    simd_float2     float2Data[10];
    simd_float3     float3Data[10];
    simd_float4     float4Data[10];
} BehaviorData;
