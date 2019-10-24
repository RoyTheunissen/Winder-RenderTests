Shader "Watercolor/Default"
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
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #include "Watercolor.cginc"
        
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf WaterColor fullforwardshadows vertex:vert

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            //float2 uv_PaperTex;
            float2 uv_PerlinTex;
            float2 uv_LightRampTex;
            float3 viewDir;
            float4 screenPos;
            float3 worldPos;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        fixed4 _EmissionColor;
        float _HighlightMultiplier;
        float _NearLightFactor;

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
            
            //o.heightFallOff = saturate(v.color.r);
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            NoisifyNormals(IN.screenPos, o);
            
            //fixed3 paper = tex2D (_PaperTex, screenUv * 2 + uvOffset);
            
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
            
            float mask = 1;//IN.heightFallOff;
            
            half rim = 1.0 - saturate(dot (normalize(IN.viewDir), o.Normal));
            
            float nDotL = saturate(dot(o.Normal, normalize(float3(-1, 0, 0.25))));
            float threshold = .5;
            float rimLight = saturate((nDotL - threshold) * 10 + threshold) * mask;
            
            float4 highlightColor = UNITY_ACCESS_INSTANCED_PROP(Props, _HighlightColor);
            
            float selectionFactor = UNITY_ACCESS_INSTANCED_PROP(Props, _SelectionFactor) * mask;
            
            float rimPower = 3.2;
            
            o.Emission = lerp(min(0, (IN.worldPos.z - 10 + 1.5) / 10) * 1, 0, _NearLightFactor);
            
            // Moving paper texture to post effect
            //o.Emission += (1 - paper.r) * .5;
            
            //o.Emission = _EmissionColor;
            //o.Emission = _EmissionColor * mask + highlightColor.rgb * _HighlightMultiplier * pow (rim, rimPower / (selectionFactor + 0.01)) * mask * selectionFactor + selectionFactor * highlightColor * 0.2 * _HighlightMultiplier;
            //o.Emission += rimLight * (.25 + selectionFactor);
        }
        ENDCG
    }
    FallBack "Diffuse"
}
