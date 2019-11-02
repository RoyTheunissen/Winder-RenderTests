﻿Shader "Particles/Glowing Lines"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _ThresholdStart ("Alpha cutoff (Start)", Range(0,1)) = 0.5
        _ThresholdEnd ("Alpha cutoff (End)", Range(0,4)) = 0.5
        _ScrollSpeed ("Scroll Speed", Vector) = (0,0,0,0)
        
        [HDR]
        _EmissionColor ("Emission", Color) = (0,0,0,1)
    }
    SubShader
    {
        Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
        LOD 200
        Cull Off
        ZTest Always
        
        // Pass to render object as a shadow caster
        Pass {
            Name "Caster"
            Tags { "LightMode" = "ShadowCaster" }
                
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"
            
            struct v2f { 
                V2F_SHADOW_CASTER;
                float2 uv : TEXCOORD1;
                float3 normal : NORMAL;
                float4 color : COLOR;
            };
            
            uniform float4 _MainTex_ST;
            
            float3 _ScrollSpeed;
            float _ThresholdStart;
            float _ThresholdEnd;
            
            v2f vert( appdata_full v )
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                float2 uvOffset = _ScrollSpeed.xy * _Time.y;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex) + uvOffset;
                o.normal = v.normal;
                o.color = v.color;
                
                return o;
            }
            
            uniform sampler2D _MainTex;
            uniform fixed4 _Color;
            
            float4 frag( v2f i ) : SV_Target
            {
                fixed4 c = tex2D( _MainTex, i.uv ) * _Color;
                
                float threshold = lerp(_ThresholdEnd, _ThresholdStart, i.color.a);
                clip( c.a - threshold );
                
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        
        }

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows vertex:vert alphatest:_Cutoff

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float4 vertexColor;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        
        float4 _EmissionColor;
        float3 _ScrollSpeed;
        float _ThresholdStart;
        float _ThresholdEnd;

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
            // Albedo comes from a texture tinted by color
            float2 uvOffset = _ScrollSpeed.xy * _Time.y;
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex + uvOffset) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
            
            float threshold = lerp(_ThresholdEnd, _ThresholdStart, IN.vertexColor.a);
            clip( o.Alpha - threshold );
            
            o.Emission = _EmissionColor;
        }
        ENDCG
    }
    //FallBack "Transparent/Cutout/Diffuse"
}
