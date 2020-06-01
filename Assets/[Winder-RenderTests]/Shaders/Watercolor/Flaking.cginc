#ifndef FLAKING_INC
#define FLAKING_INC

#include "Watercolor.cginc"

#define GetFlakingShadowPass(input) GetFlakingFromDirections(##input##.viewDir, ##input##.viewDirWorld, ##input##.normal)
#define GetFlaking(input, output) GetFlakingFromDirections(##input##.viewDir, ##input##.viewDirWorld, ##output##.Normal)

float _GrazingThresholdStart;
float _GrazingThresholdEnd;

float _FlakingOffsetStart;
float _FlakingOffsetEnd;
float _FlakingDistanceStart;
float _FlakingDistanceEnd;
float _FlakingSizeStart;
float _FlakingSizeEnd;

float GetFlakingFromDirections(float3 viewDir, float3 viewDirWorld, float3 normal)
{
    //return 1;

    half rim = 1.0 - saturate(dot (normalize(viewDir), normalize(normal)));
    
    // Little experiment: modulate grazing threshold by distance.
    float objectZ = max(GetObjectPosition().z, 0);
    float gz = (objectZ - _FlakingDistanceStart) / (_FlakingDistanceEnd - _FlakingDistanceStart);
    
    float flakingOffset = lerp(_FlakingOffsetStart, _FlakingOffsetEnd, gz);
    float gt = lerp(_GrazingThresholdStart, _GrazingThresholdEnd, gz);
    float grazing = saturate((rim - (1 - gt)) / (gt));
    
    float flakeSize = lerp(_FlakingSizeStart, _FlakingSizeEnd, gz);
    float2 uv = 
    GetPlanarWorldSpaceUvFromViewDirection(viewDirWorld) / flakeSize
    ;
    
    fixed3 perlin = tex2D (_PerlinTex, uv);
    return saturate(lerp(1, perlin, grazing) - flakingOffset);
}

#endif
