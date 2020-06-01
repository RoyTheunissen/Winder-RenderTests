// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/UvParallaxTest"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard vertex:vert fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0
        
        #include "..\Winder.cginc"

        sampler2D _MainTex;
        float2 _MainTex_ST;

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            WINDING_FIELDS_INSTANCED
        UNITY_INSTANCING_BUFFER_END(Props)
        
        #include "Watercolor.cginc"

        struct Input
        {
            float2 uv_MainTex;
            PLANAR_WORLD_UVS_INPUT
        };
        
        void vert (inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input,o);
            PLANAR_WORLD_UVS_VERTEX(v, o);
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float2 uvSpace = GetPlanarWorldSpaceUv(IN) * _MainTex_ST.xy;
            float2 uv = uvSpace / 1 + .5;
        
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, uv) * _Color;
            //c.rgb = positionOnPlane;
            
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Emission = o.Albedo;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
