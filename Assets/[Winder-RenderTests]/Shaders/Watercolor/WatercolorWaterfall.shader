Shader "Watercolor/Waterfall"
{
    Properties
    {
        _ColorBase ("Color Base", Color) = (.25,.25,.25,1)
        _ColorFlecks ("Color Flecks", Color) = (.5,.5,.5,1)
        _ColorEdge ("Color Edge", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Edge ("Edge", Range(0,1)) = 0.1
        _Wobble ("Wobble", Range(0,1)) = 0.1
        _WobbleScale ("Wobble Scale", Vector) = (1, 1, 0, 0)
        _WobbleScroll ("Wobble Scroll", Vector) = (.5, .5, 0, 0)
        _Flecks ("Flecks", Range(0,1)) = 0.1
        _FlecksScale ("Flecks Scale", Vector) = (1, 1, 0, 0)
        _FlecksScroll ("Flecks Scroll", Vector) = (.5, .5, 0, 0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Watercolor fullforwardshadows
        
        #include "../Winder.cginc"

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        
        fixed4 _ColorBase;
        fixed4 _ColorFlecks;
        fixed4 _ColorEdge;
        
        float _Edge;
        float _Wobble;
        float2 _WobbleScale;
        float2 _WobbleScroll;
        float _Flecks;
        float2 _FlecksScale;
        float2 _FlecksScroll;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            WINDING_FIELDS_INSTANCED
        UNITY_INSTANCING_BUFFER_END(Props)
        
        #include "Watercolor.cginc"
        
        float scrunch(float value, float threshold, float amount)
        {
            return saturate((value - (1 - threshold)) * amount);
        }

        void surf (Input IN, inout SurfaceOutputWatercolor o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 mask = tex2D (_MainTex, IN.uv_MainTex);
            
            float c = 0;
            float crispEdge = scrunch(mask.r, _Edge, 100);
            float edge = saturate(c + crispEdge);
            edge = saturate(c + scrunch(tex2D (_PerlinTex, (IN.uv_MainTex / 10) * _WobbleScale + _Time.y * _WobbleScroll) * pow(mask.r, 6), _Wobble, 100));
            float flecks = saturate(c + scrunch(tex2D (_PerlinTex, (IN.uv_MainTex / 10) * _FlecksScale + _Time.y * _FlecksScroll), (1 - saturate(mask.g - mask.r)) * _Flecks, 100));
            
            o.Albedo = lerp(lerp(_ColorBase, _ColorFlecks, flecks), _ColorEdge, edge);
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Emission = edge / 8 + flecks / 5;
            //o.Emission = o.Albedo / 4;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
