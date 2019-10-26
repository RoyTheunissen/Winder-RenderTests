﻿Shader "Watercolor/Grass"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
        _NearLightFactor ("Near Light Factor", Range(0,1)) = 1.0
        
        [HDR]
        _EmissionColor ("Emission", Color) = (0,0,0,1)
    }
    SubShader
    {
        Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
        LOD 200
        Cull Off

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf WaterColor fullforwardshadows vertex:vert alphatest:_Cutoff

        #include "Watercolor.cginc"
        
        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float3 viewDir;
            float3 worldPos;
            float4 screenPos;
            float3 vertexColor;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        
        float4 _EmissionColor;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            //UNITY_DEFINE_INSTANCED_PROP(float, _SelectionFactor)
        UNITY_INSTANCING_BUFFER_END(Props)
        
        void vert (inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input,o);
            
            o.vertexColor = v.color;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            NoisifyNormals(IN.screenPos, o);
        
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
            
            float darknessFactor = GetDarknessFactor(IN.worldPos, -1.0, 0.5);
            float darknessEmissionPenalty = darknessFactor * (1 - _NearLightFactor) * -1;
            o.Emission = darknessEmissionPenalty + _EmissionColor * IN.vertexColor;
        }
        ENDCG
    }
    FallBack "Transparent/Cutout/Diffuse"
}
