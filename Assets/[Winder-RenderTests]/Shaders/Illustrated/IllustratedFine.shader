Shader "Illustrated/Fine"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        
        [HDR]
        _EmissionColor ("Emission", Color) = (0,0,0,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _SelectionFactor ("Selection Factor", Range(0.0, 1.0)) = 0.0
        _HighlightMultiplier ("Highlight Multiplier", Range(1.0, 24.0)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Illustrated fullforwardshadows vertex:vert

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0
        
        #include "UnityPBSLighting.cginc"

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float3 viewDir;
            float heightFallOff;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        fixed4 _EmissionColor;
        float _HighlightMultiplier;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(float, _SelectionFactor)
            UNITY_DEFINE_INSTANCED_PROP(float4, _HighlightColor)
        UNITY_INSTANCING_BUFFER_END(Props)
        
        void vert (inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input,o);
            
            o.heightFallOff = saturate(v.color.r);
        }
        
        inline half4 LightingIllustrated_Deferred (SurfaceOutputStandard s, half3 viewDir, UnityGI gi, out half4 outGBuffer0, out half4 outGBuffer1, out half4 outGBuffer2)
        {
            half oneMinusReflectivity;
            half3 specColor;
            s.Albedo = DiffuseAndSpecularFromMetallic (s.Albedo, s.Metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);
            
            half4 c = UNITY_BRDF_PBS (s.Albedo, specColor, oneMinusReflectivity, s.Smoothness, s.Normal, viewDir, gi.light, gi.indirect);
            c.rgb += UNITY_BRDF_GI (s.Albedo, specColor, oneMinusReflectivity, s.Smoothness, s.Normal, viewDir, s.Occlusion, gi);
            
            UnityStandardData data;
            data.diffuseColor	= s.Albedo;
            data.occlusion		= s.Occlusion;		
            data.specularColor	= specColor;
            data.smoothness		= s.Smoothness;	
            data.normalWorld	= s.Normal;
            
            UnityStandardDataToGbuffer(data, outGBuffer0, outGBuffer1, outGBuffer2);
            
            half4 emission = half4(s.Emission + c.rgb, 1);
            
//            float nDotL = saturate(dot(s.Normal, normalize(float3(-1, 0, 0.25))));
//            float threshold = .5;
//            float rim = saturate((nDotL - threshold) * 10 + threshold);
//            emission += rim * .25;
            
            return emission;
        }
        
        inline void LightingIllustrated_GI (
            SurfaceOutputStandard s,
            UnityGIInput data,
            inout UnityGI gi)
            {
            #if defined(UNITY_PASS_DEFERRED) && UNITY_ENABLE_REFLECTION_BUFFERS
            gi = UnityGlobalIllumination(data, s.Occlusion, s.Normal);
            #else
            Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(s.Smoothness, data.worldViewDir, s.Normal, lerp(unity_ColorSpaceDielectricSpec.rgb, s.Albedo, s.Metallic));
            gi = UnityGlobalIllumination(data, s.Occlusion, s.Normal, g);
            #endif
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
            
            float mask = IN.heightFallOff;
            
            half rim = 1.0 - saturate(dot (normalize(IN.viewDir), o.Normal));
            
            float nDotL = saturate(dot(o.Normal, normalize(float3(-1, 0, 0.25))));
            float threshold = .5;
            float rimLight = saturate((nDotL - threshold) * 10 + threshold) * mask;
            
            float4 highlightColor = 0;//UNITY_ACCESS_INSTANCED_PROP(Props, _HighlightColor);
            
            float selectionFactor = UNITY_ACCESS_INSTANCED_PROP(Props, _SelectionFactor) * mask;
            
            float rimPower = 3.2;
            //o.Emission = _EmissionColor;
            o.Emission = _EmissionColor * mask + highlightColor.rgb * _HighlightMultiplier * pow (rim, rimPower / (selectionFactor + 0.01)) * mask * selectionFactor + selectionFactor * highlightColor * 0.2 * _HighlightMultiplier;
            o.Emission += rimLight * (.25 + selectionFactor);
        }
        ENDCG
    }
    FallBack "Diffuse"
}
