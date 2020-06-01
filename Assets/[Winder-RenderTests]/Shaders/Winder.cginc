#ifndef WINDER_INC
#define WINDER_INC

#define PLANAR_WORLD_UVS_INPUT float3 viewDirWorld;
#define PLANAR_WORLD_UVS_VERTEX(input, output) output##.viewDirWorld = WorldSpaceViewDir(##input##.vertex);
#define GetPlanarWorldSpaceUv(input) GetPlanarWorldSpaceUvFromViewDirection(input##.viewDirWorld)

// Based on Unity's Plane.Raycast
float3 RaycastOntoPlane(float3 rayOrigin, float3 rayDirection, float3 planePosition, float3 planeNormal)
{
    float planeDistanceAlongNormal = -dot(planeNormal, planePosition);

    float a = dot(rayDirection, planeNormal);
    float num = -dot(rayOrigin, planeNormal) - planeDistanceAlongNormal;
    
    // NOTE: Our noise plane is facing the camera and our camera is always facing forward so the raycast will never
    // miss the plane so this check is not needed.
    //if (abs(a - 0.0f) < 0.001)
        //return rayOrigin;
    
    float distanceAlongRay = num / a;
    return rayOrigin + rayDirection * distanceAlongRay;
}

// Determines a UV co-ordinate based on a plane centered at the object's pivot. This creates parallax effects that are 
// more or less consistent with what you would expect at that object's position but do not curve along the object.
float2 GetPlanarWorldSpaceUvFromViewDirection(float3 viewDirectionWorldSpace, float3 planePosition)
{
    float3 planeNormal = float3(0, 0, 1);
    
    float3 rayOrigin = _WorldSpaceCameraPos.xyz;
    float3 rayDirection = normalize(viewDirectionWorldSpace);
    
    return RaycastOntoPlane(rayOrigin, rayDirection, planePosition, planeNormal) - planePosition;
}

// Determines a UV co-ordinate based on a plane centered at the object's pivot. This creates parallax effects that are 
// more or less consistent with what you would expect at that object's position but do not curve along the object.
float2 GetPlanarWorldSpaceUvFromViewDirection(float3 viewDirectionWorldSpace)
{
    float3 planePosition = mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).xyz;
    return GetPlanarWorldSpaceUvFromViewDirection(viewDirectionWorldSpace, planePosition);
}

float2 GetScreenAlignedUv(float2 screenUv, float repeat = 1, float parallax = 0.23)
{
    float width = _ScreenParams.x / _ScreenParams.y;
    screenUv.x *= width;
    float2 uvOffset = float2(_WorldSpaceCameraPos.x, _WorldSpaceCameraPos.y) * parallax;
    return screenUv * repeat + uvOffset;
}

float2 GetScreenAlignedUv(float4 screenPos, float repeat = 1, float parallax = 0.23)
{
    float2 screenUv = (screenPos.xy / max(0.0001, screenPos.w));
    return GetScreenAlignedUv(screenUv, repeat, parallax);
}

float2 GetWorldAlignedUvStepped(float3 worldPos)
{
    float2 uv = float2(worldPos.x, worldPos.y) / 2;
    float steps = 10;
    uv.x += 3538;
    //uv.x += 238 * floor(worldPos.z / steps);
    return uv;
}

float3 GetObjectPosition()
{
    return mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).xyz;
}

float GetObjectSeed()
{
    float3 objectPosition = GetObjectPosition();
    return
        objectPosition.x * 348723.694857389
        + objectPosition.y * 747374.57248724
        + objectPosition.z * 5657385.946583
        ;
}

float3 rgb2hsv(float3 c) {
  float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
  float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
  float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

  float d = q.x - min(q.w, q.y);
  float e = 1.0e-10;
  return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 hsv2rgb(float3 c) {
  c = float3(c.x, clamp(c.yz, 0.0, 1.0));
  float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

#define WINDING_FIELDS float _SelectionFactor;\
    float _WindingFactor; \
    float _WindingDirection;

#define WINDING_FIELDS_INSTANCED UNITY_DEFINE_INSTANCED_PROP(float, _SelectionFactor)\
    UNITY_DEFINE_INSTANCED_PROP(float, _WindingFactor) \
    UNITY_DEFINE_INSTANCED_PROP(float, _WindingDirection)

#endif
