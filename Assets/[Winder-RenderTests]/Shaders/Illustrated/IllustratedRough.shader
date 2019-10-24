﻿Shader "Illustrated/Rough"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _NoiseTex ("Noise (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _GrazingThreshold ("Grazing Threshold", Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "Queue"="Transparent" }
        LOD 200
        //ZWrite Off

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows vertex:vert

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _NoiseTex;

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_NoiseTex;
            float3 viewDir;
            float3 worldNormal;
            float3 worldPos;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        float _GrazingThreshold;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void vert (inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input,o);
            
            //o.dot = dot(v.normal, float3(0, 0, 1));
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            half rim = 1.0 - saturate(dot (normalize(float3(0, 0, -1)), normalize(IN.worldNormal)));
            //_GrazingThreshold = 0;
            float grazing =
                saturate((rim - _GrazingThreshold) / (1 - _GrazingThreshold))
                //saturate(pow(rim, 1))
                ;
                
            float mask =
                1 
                //abs(IN.worldPos.z / 15)
            ;
        
            float2 worldUv = (IN.worldPos.xy + IN.worldPos.z * .5) / 6;
//            float2 screenUv = (IN.screenPos.xy / IN.screenPos.w) * 2;
//            screenUv.x *= _ScreenParams.x / _ScreenParams.y;
            fixed noise = tex2D (_NoiseTex, worldUv).r;
            
            grazing *= mask * noise * 1;
        
            //o.Emission = grazing;
            
            if (grazing > 0.1)
                discard;
            
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
