#ifndef WATERCOLOR_INC
#define WATERCOLOR_INC

#include "UnityPBSLighting.cginc"

#include "../Winder.cginc"

#define NoisifyNormals(input, output) NoisifyNormalsWorldSpace(input##.viewDirWorld, ##output##)

#define AddNoisyLight(input, output) output##.ExtraLight = tex2D (_PerlinTex, GetPlanarWorldSpaceUvFromViewDirection(##input##.viewDirWorld) * .25);

sampler2D _LightRampTex;
sampler2D _PerlinTex;
sampler2D _UvTestTex;

float3 _AdditiveAmbientLight;

float3 _WindingColorSelection;
float3 _WindingColorPositive;
float3 _WindingColorNegative;
float3 _WindingColorNeutral;

float _NearLightFactor;
float _InverseLightFactor;
float _WrapAroundLightFactor;

struct SurfaceOutputWatercolor
{
    fixed3 Albedo;      // base (diffuse or specular) color
    fixed3 Normal;      // tangent space normal, if written
    half3 Emission;
    half Metallic;      // 0=non-metal, 1=metal
    half Smoothness;    // 0=rough, 1=smooth
    half Occlusion;     // occlusion (default 1)
    fixed Alpha;        // alpha for transparencies
    half InverseLightFactor; // allows us to remove light near the foreground.
    half ExtraLight; // allows us to add extra light for color-mapped texture.
};

float valueRamp(float value)
{
    return tex2D (_LightRampTex, float2(value, 0.5));
}

void NoisifyNormalsScreenSpace(float4 screenPos, inout SurfaceOutputWatercolor o, float density = 2, float magnitude = 0.175)
{
    float2 uv = GetScreenAlignedUv(screenPos, density);
    fixed3 perlin = tex2D (_PerlinTex, uv);
    
    o.Normal += float3(perlin.yz, 0) * magnitude;
}

void NoisifyNormalsWorldSpace(float3 viewDirectionWorldSpace, inout SurfaceOutputWatercolor o,
    float density = 0.25, float magnitude = 0.175)
{
    float2 uv = GetPlanarWorldSpaceUvFromViewDirection(viewDirectionWorldSpace) * density;
    fixed3 perlin = tex2D (_PerlinTex, uv);
    
    o.Normal += float3(perlin.yz, 0) * magnitude;
}

float GetDarknessFactor(float3 worldPos, float startDistance = -0.25, float falloffDistance = 10)
{
    return 1 - saturate((worldPos.z - startDistance) / falloffDistance);
}

float DarkenNearZero(float3 worldPos, float startDistance = -0.25, float falloffDistance = 10)
{
    float darknessFactor = GetDarknessFactor(worldPos, startDistance, falloffDistance);
    return darknessFactor * (1 - _NearLightFactor) * -1;
}

float3 GetGrassOffset(float l)
{
    float3 offset = 0;

    // Get a nice 'random' seed based on the object position. Not the vertex position.
    float seed = GetObjectSeed();
        
    float pi = 3.14159265359;
        
    // Vary the length.
    float mode = .5 + sin(pi * seed * 9.6436) * .5;
    offset.y += lerp(-.275, 0, mode * mode) * l;
    
    // Lean the blade forward or backward.
    float mode2 = sin(pi * seed);
    float lean = lerp(.2, .3, 1 - pow(1 - mode2, 2)) * sign(mode2);
    offset.z += pow(l, 2) * lean;
    offset.z += sin(pi * l) * -lean * .5;
    
    // Droop a bit.
    float mode3 = sin(pi * seed * 934.342);
    float droop = mode3 * pow(l, 4);
    offset.y -= abs(droop) * .3;
    offset.z += lean * droop * 1.5;
    
    return offset;
}

float3 GetWindingTint(float direction)
{
    float3 windingTint = lerp(_WindingColorNeutral, _WindingColorPositive, saturate(direction));
    return lerp(windingTint, _WindingColorNegative, saturate(- direction));
}

float WrapAround(float value)
{
    return _WrapAroundLightFactor + value * (1 - _WrapAroundLightFactor);
}

// Main Physically Based BRDF
// Derived from Disney work and based on Torrance-Sparrow micro-facet model
//
//   BRDF = kD / pi + kS * (D * V * F) / 4
//   I = BRDF * NdotL
//
// * NDF (depending on UNITY_BRDF_GGX):
//  a) Normalized BlinnPhong
//  b) GGX
// * Smith for Visiblity term
// * Schlick approximation for Fresnel
half4 BRDF_Watercolor_PBS (half3 diffColor, half3 specColor, half oneMinusReflectivity, half smoothness,
    float3 normal, float3 viewDir,
    UnityLight light, UnityIndirect gi, float inverseLightFactor, float extraLight)
{
    float lightFactor = saturate(1 - inverseLightFactor);

    float perceptualRoughness = SmoothnessToPerceptualRoughness (smoothness);
    float3 halfDir = Unity_SafeNormalize (float3(light.dir) + viewDir);

// NdotV should not be negative for visible pixels, but it can happen due to perspective projection and normal mapping
// In this case normal should be modified to become valid (i.e facing camera) and not cause weird artifacts.
// but this operation adds few ALU and users may not want it. Alternative is to simply take the abs of NdotV (less correct but works too).
// Following define allow to control this. Set it to 0 if ALU is critical on your platform.
// This correction is interesting for GGX with SmithJoint visibility function because artifacts are more visible in this case due to highlight edge of rough surface
// Edit: Disable this code by default for now as it is not compatible with two sided lighting used in SpeedTree.
#define UNITY_HANDLE_CORRECTLY_NEGATIVE_NDOTV 0

#if UNITY_HANDLE_CORRECTLY_NEGATIVE_NDOTV
    // The amount we shift the normal toward the view vector is defined by the dot product.
    half shiftAmount = dot(normal, viewDir);
    normal = shiftAmount < 0.0f ? normal + viewDir * (-shiftAmount + 1e-5f) : normal;
    // A re-normalization should be applied here but as the shift is small we don't do it to save ALU.
    //normal = normalize(normal);

    half nv = saturate(dot(normal, viewDir)); // TODO: this saturate should no be necessary here
#else
    half nv = abs(dot(normal, viewDir));    // This abs allow to limit artifact
#endif

    half nl = WrapAround(saturate(dot(normal, light.dir)));
    float nh = saturate(dot(normal, halfDir));

    half lv = saturate(dot(light.dir, viewDir));
    half lh = saturate(dot(light.dir, halfDir));

    // Diffuse term
    half diffuseTerm = DisneyDiffuse(nv, nl, lh, perceptualRoughness) * nl * lightFactor;

    // Specular term
    // HACK: theoretically we should divide diffuseTerm by Pi and not multiply specularTerm!
    // BUT 1) that will make shader look significantly darker than Legacy ones
    // and 2) on engine side "Non-important" lights have to be divided by Pi too in cases when they are injected into ambient SH
    float roughness = PerceptualRoughnessToRoughness(perceptualRoughness);
#if UNITY_BRDF_GGX
    // GGX with roughtness to 0 would mean no specular at all, using max(roughness, 0.002) here to match HDrenderloop roughtness remapping.
    roughness = max(roughness, 0.002);
    half V = SmithJointGGXVisibilityTerm (nl, nv, roughness);
    float D = GGXTerm (nh, roughness);
#else
    // Legacy
    half V = SmithBeckmannVisibilityTerm (nl, nv, roughness);
    half D = NDFBlinnPhongNormalizedTerm (nh, PerceptualRoughnessToSpecPower(perceptualRoughness));
#endif

    half specularTerm = V*D * UNITY_PI; // Torrance-Sparrow model, Fresnel is applied later

#   ifdef UNITY_COLORSPACE_GAMMA
        specularTerm = sqrt(max(1e-4h, specularTerm));
#   endif

    // specularTerm * nl can be NaN on Metal in some cases, use max() to make sure it's a sane value
    specularTerm = max(0, specularTerm * nl);
#if defined(_SPECULARHIGHLIGHTS_OFF)
    specularTerm = 0.0;
#endif
    specularTerm *= lightFactor;

    // surfaceReduction = Int D(NdotH) * NdotH * Id(NdotL>0) dH = 1/(roughness^2+1)
    half surfaceReduction;
#   ifdef UNITY_COLORSPACE_GAMMA
        surfaceReduction = 1.0-0.28*roughness*perceptualRoughness;      // 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0;1]
#   else
        surfaceReduction = 1.0 / (roughness*roughness + 1.0);           // fade \in [0.5;1]
#   endif

    // To provide true Lambert lighting, we need to be able to kill specular completely.
    specularTerm *= any(specColor) ? 1.0 : 0.0;

    //diffColor = 1;

    half grazingTerm = saturate(smoothness + (1-oneMinusReflectivity));
    
    // Little experiment: multiply the diffuse color with the direct light only. This way a purely black albedo will still
    // receive ambient light. This is not physically accurate but this will ensure that black objects still feel grounded
    // in the world. Essentially this turns ambient light into a sort of 'color correction' except it can be overridden
    // completely with emission, which you couldn't with color correction via a post processing effect.
    half3 lighting = (gi.diffuse + light.color * diffuseTerm * diffColor)
                    + specularTerm * light.color * FresnelTerm (specColor, lh)
                    + surfaceReduction * gi.specular * FresnelLerp (specColor, grazingTerm, nv);
    
    // Let's try some free ambient light! This prevents the scene from going to full black which allows us to show
    // more texture and perhaps is more in line with the look of watercolor.
    lighting += 0.025;
    lighting += extraLight * _AdditiveAmbientLight;
    
    half3 hsv = rgb2hsv(lighting.rgb);
    hsv.b = valueRamp(hsv.b);
    
    float selectionFactor = UNITY_ACCESS_INSTANCED_PROP(Props, _SelectionFactor);
    float windingDirection = UNITY_ACCESS_INSTANCED_PROP(Props, _WindingDirection);
    float windingFactor = UNITY_ACCESS_INSTANCED_PROP(Props, _WindingFactor);
    
    float3 selectionColor = lerp(1, _WindingColorSelection * 6.5, selectionFactor);
    float3 windingColor = GetWindingTint(windingDirection) * 9;
    float3 lightTint = lerp(selectionColor, windingColor, windingFactor);
    
    lighting = hsv2rgb(hsv) * lightTint;
    
    //float nearFactor = lerp(1, _NearLightFactor, );

    // Experiment: do not incorporate the diffuse color here, but only in the directional light.
    return half4(lighting, 1);
}

inline UnityGI UnityGI_Watercolor(UnityGIInput data, half occlusion, half3 normalWorld)
{
    UnityGI o_gi;
    ResetUnityGI(o_gi);

    // Base pass with Lightmap support is responsible for handling ShadowMask / blending here for performance reason
    #if defined(HANDLE_SHADOWS_BLENDING_IN_GI)
        half bakedAtten = UnitySampleBakedOcclusion(data.lightmapUV.xy, data.worldPos);
        float zDist = dot(_WorldSpaceCameraPos - data.worldPos, UNITY_MATRIX_V[2].xyz);
        float fadeDist = UnityComputeShadowFadeDistance(data.worldPos, zDist);
        data.atten = UnityMixRealtimeAndBakedShadows(data.atten, bakedAtten, UnityComputeShadowFade(fadeDist));
    #endif

    o_gi.light = data.light;
    o_gi.light.color *= data.atten;

    #if UNITY_SHOULD_SAMPLE_SH
        o_gi.indirect.diffuse = ShadeSHPerPixel(normalWorld, data.ambient, data.worldPos);
    #endif

    #if defined(LIGHTMAP_ON)
        // Baked lightmaps
        half4 bakedColorTex = UNITY_SAMPLE_TEX2D(unity_Lightmap, data.lightmapUV.xy);
        half3 bakedColor = DecodeLightmap(bakedColorTex);

        #ifdef DIRLIGHTMAP_COMBINED
            fixed4 bakedDirTex = UNITY_SAMPLE_TEX2D_SAMPLER (unity_LightmapInd, unity_Lightmap, data.lightmapUV.xy);
            o_gi.indirect.diffuse += DecodeDirectionalLightmap (bakedColor, bakedDirTex, normalWorld);

            #if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN)
                ResetUnityLight(o_gi.light);
                o_gi.indirect.diffuse = SubtractMainLightWithRealtimeAttenuationFromLightmap (o_gi.indirect.diffuse, data.atten, bakedColorTex, normalWorld);
            #endif

        #else // not directional lightmap
            o_gi.indirect.diffuse += bakedColor;

            #if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN)
                ResetUnityLight(o_gi.light);
                o_gi.indirect.diffuse = SubtractMainLightWithRealtimeAttenuationFromLightmap(o_gi.indirect.diffuse, data.atten, bakedColorTex, normalWorld);
            #endif

        #endif
    #endif

    #ifdef DYNAMICLIGHTMAP_ON
        // Dynamic lightmaps
        fixed4 realtimeColorTex = UNITY_SAMPLE_TEX2D(unity_DynamicLightmap, data.lightmapUV.zw);
        half3 realtimeColor = DecodeRealtimeLightmap (realtimeColorTex);

        #ifdef DIRLIGHTMAP_COMBINED
            half4 realtimeDirTex = UNITY_SAMPLE_TEX2D_SAMPLER(unity_DynamicDirectionality, unity_DynamicLightmap, data.lightmapUV.zw);
            o_gi.indirect.diffuse += DecodeDirectionalLightmap (realtimeColor, realtimeDirTex, normalWorld);
        #else
            o_gi.indirect.diffuse += realtimeColor;
        #endif
    #endif

    o_gi.indirect.diffuse *= occlusion;
    return o_gi;
}

inline UnityGI UnityGI_Watercolor (UnityGIInput data, half occlusion, half3 normalWorld, Unity_GlossyEnvironmentData glossIn)
{
    UnityGI o_gi = UnityGI_Watercolor(data, occlusion, normalWorld);
    o_gi.indirect.specular = UnityGI_IndirectSpecular(data, occlusion, glossIn);
    return o_gi;
}

inline half4 LightingWatercolor (SurfaceOutputWatercolor s, float3 viewDir, UnityGI gi)
{
    s.Normal = normalize(s.Normal);

    half oneMinusReflectivity;
    half3 specColor;
    s.Albedo = DiffuseAndSpecularFromMetallic (s.Albedo, s.Metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);

    // shader relies on pre-multiply alpha-blend (_SrcBlend = One, _DstBlend = OneMinusSrcAlpha)
    // this is necessary to handle transparency in physically correct way - only diffuse component gets affected by alpha
    half outputAlpha;
    s.Albedo = PreMultiplyAlpha (s.Albedo, s.Alpha, oneMinusReflectivity, /*out*/ outputAlpha);

    half4 c = BRDF_Watercolor_PBS (s.Albedo, specColor, oneMinusReflectivity, s.Smoothness, s.Normal, viewDir, gi.light, gi.indirect, s.InverseLightFactor, s.ExtraLight);
    
    c.a = outputAlpha;
    
    return c;
}

inline void LightingWatercolor_GI (
    SurfaceOutputWatercolor s,
    UnityGIInput data,
    inout UnityGI gi)
{
#if defined(UNITY_PASS_DEFERRED) && UNITY_ENABLE_REFLECTION_BUFFERS
    gi = UnityGI_Watercolor(data, s.Occlusion, s.Normal);
#else
    Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(s.Smoothness, data.worldViewDir, s.Normal, lerp(unity_ColorSpaceDielectricSpec.rgb, s.Albedo, s.Metallic));
    gi = UnityGI_Watercolor(data, s.Occlusion, s.Normal, g);
#endif
}

#endif
