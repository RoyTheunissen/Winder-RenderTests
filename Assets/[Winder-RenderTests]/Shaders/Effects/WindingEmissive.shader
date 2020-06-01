Shader "FX/Winding Emissive"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _WindingEmission ("Winding Emission", Range(0.0, 40.0)) = 9.0
        _WindingFactor ("Winding Factor", Range(0.0, 1.0)) = 1.0
        _WindingDirection ("Winding Direction", Range(-1.0, 1.0)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        
        #include "../Winder.cginc"
        
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Watercolor fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(float, _WindingEmission)
            WINDING_FIELDS_INSTANCED
        UNITY_INSTANCING_BUFFER_END(Props)
        
        #include "..\Watercolor\Watercolor.cginc"

        void surf (Input IN, inout SurfaceOutputWatercolor o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
            o.Emission = GetWindingTint(UNITY_ACCESS_INSTANCED_PROP(Props, _WindingDirection)) * _WindingEmission * UNITY_ACCESS_INSTANCED_PROP(Props, _WindingFactor);
        }
        ENDCG
    }
    FallBack "Diffuse"
}
