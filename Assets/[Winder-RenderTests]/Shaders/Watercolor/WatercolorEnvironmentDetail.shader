﻿Shader "Watercolor/Environment Detail"
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
        _NearLightFactor ("Near Light Factor", Range(0,1)) = 1.0
        _WrapAroundLightFactor ("Wrap Around Light Factor", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Watercolor fullforwardshadows vertex:vert
        
        #include "../Winder.cginc"

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        uniform float4 _MainTex_ST;

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        fixed4 _EmissionColor;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            WINDING_FIELDS_INSTANCED
        UNITY_INSTANCING_BUFFER_END(Props)
        
        #include "Watercolor.cginc"

        struct Input
        {
            float3 viewDir;
            float4 screenPos;
            float3 worldPos;
            PLANAR_WORLD_UVS_INPUT
        };
        
        void vert (inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input,o);
            PLANAR_WORLD_UVS_VERTEX(v, o);
        }

        void surf (Input IN, inout SurfaceOutputWatercolor o)
        {
            NoisifyNormals(IN, o);
            
            // Albedo comes from a texture tinted by color
            float2 uv = IN.worldPos.xz;
            uv = TRANSFORM_TEX(uv, _MainTex);
            fixed4 c = tex2D (_MainTex, uv) * _Color;
            
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
            
            o.InverseLightFactor = GetDarknessFactor(IN.worldPos) - _NearLightFactor;
            
            AddNoisyLight(IN, o);
            
            o.Emission = _EmissionColor;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
