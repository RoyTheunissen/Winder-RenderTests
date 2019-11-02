Shader "Watercolor/Cutout (Double-sided)"
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
        
        // Pass to render object as a shadow caster
        Pass {
            Name "Caster"
            Tags { "LightMode" = "ShadowCaster" }
                
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile_shadowcaster
            #include "..\Winder.cginc"
            #include "UnityCG.cginc"
            
            struct v2f { 
                V2F_SHADOW_CASTER;
                float2 uv : TEXCOORD1;
                float3 normal : NORMAL;
            };
            
            uniform float4 _MainTex_ST;
            
            v2f vert( appdata_base v )
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.normal = v.normal;
                
                return o;
            }
            
            uniform sampler2D _MainTex;
            uniform fixed _Cutoff;
            uniform fixed4 _Color;
            
            WINDING_FIELDS
            
            #include "Watercolor.cginc"
            
            float4 frag( v2f i ) : SV_Target
            {
                fixed4 texcol = tex2D( _MainTex, i.uv );
                
                clip( texcol.a*_Color.a - _Cutoff );
                
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        
        }

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf WaterColor fullforwardshadows alphatest:_Cutoff
        
        #include "..\Winder.cginc"
        
        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float3 viewDir;
            float3 worldPos;
            float4 screenPos;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        
        float4 _EmissionColor;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            WINDING_FIELDS_INSTANCED
        UNITY_INSTANCING_BUFFER_END(Props)

        #include "Watercolor.cginc"

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
            
            o.Emission = DarkenNearZero(IN.worldPos) + _EmissionColor;
        }
        ENDCG
    }
    FallBack "Transparent/Cutout/Diffuse"
}
