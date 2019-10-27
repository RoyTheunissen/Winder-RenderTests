Shader "Watercolor/Grass"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _ColorBG ("Color BG", Color) = (1,1,1,1)
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
        _NearLightFactor ("Near Light Factor", Range(0,1)) = 1.0
        
        [HDR]
        _EmissionColor ("Emission", Color) = (0,0,0,1)
        _EmissionColorBG ("Emission BG", Color) = (0,0,0,1)
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
            #include "UnityCG.cginc"
            #include "Watercolor.cginc"
            
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
        #pragma surface surf WaterColor fullforwardshadows vertex:vert alphatest:_Cutoff

        #include "Watercolor.cginc"
        
        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        struct Input
        {
            float3 viewDir;
            float3 worldPos;
            float4 screenPos;
            float3 vertexColor;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        fixed4 _ColorBG;
        
        float4 _EmissionColor;
        float4 _EmissionColorBG;

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
            float bg = IN.worldPos.z / 10;
            fixed4 c = lerp(_Color, _ColorBG, bg);
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
            
            float darknessFactor = GetDarknessFactor(IN.worldPos, -1.0, 0.5);
            float darknessEmissionPenalty = darknessFactor * (1 - _NearLightFactor) * -1;
            o.Emission = darknessEmissionPenalty + lerp(_EmissionColor, _EmissionColorBG, bg) * IN.vertexColor;
        }
        ENDCG
    }
    FallBack "Transparent/Cutout/Diffuse"
}
