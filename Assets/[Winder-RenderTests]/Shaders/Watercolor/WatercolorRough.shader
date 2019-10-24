// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Watercolor/Rough"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
        
        _GrazingThreshold ("Grazing Threshold", Range(0,1)) = 0.5
        
        [HDR]
        _EmissionColor ("Emission", Color) = (0,0,0,1)
        
        _NearLightFactor ("Near Light Factor", Range(0,1)) = 1.0
    }
    SubShader
    {
        Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
        LOD 200   
        
        //Cull Off
        
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
                float3 viewDir : TEXCOORD2;
                float4 screenPos : TEXCOORD4;
            };
            
            uniform float4 _MainTex_ST;
            
            v2f vert( appdata_base v )
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                
                o.viewDir = ObjSpaceViewDir(v.vertex);
                o.normal = v.normal;
                o.screenPos = ComputeScreenPos(UnityObjectToClipPos (v.vertex));
                
                return o;
            }
            
            uniform sampler2D _MainTex;
            uniform fixed _Cutoff;
            uniform fixed4 _Color;
            float _GrazingThreshold;
            
            float4 frag( v2f i ) : SV_Target
            {
                fixed4 texcol = tex2D( _MainTex, i.uv );
                
                // TODO: Try to figure out screenspace fresnel noise
                half rim = 1.0 - saturate(dot (normalize(i.viewDir), normalize(i.normal)));
                float grazing =
                saturate((rim - _GrazingThreshold) / (1 - _GrazingThreshold))
                //saturate(pow(rim, 1))
                ;
                
                float2 screenUv = (i.screenPos.xy / max(0.0001, i.screenPos.w));
                float width = _ScreenParams.x / _ScreenParams.y;
                screenUv.x *= width;
                float2 uvOffset = float2(_WorldSpaceCameraPos.x, _WorldSpaceCameraPos.y) / 9.5;
                fixed3 perlin = tex2D (_PerlinTex, screenUv * 2 + uvOffset);
                
                float flaking = saturate(lerp(1, perlin, grazing));
                
                clip( texcol.a*_Color.a*flaking - _Cutoff );
                
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        
        }

        CGPROGRAM
        
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf WaterColor fullforwardshadows vertex:vert alphatest:_Cutoff

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0
        
        #include "Watercolor.cginc"

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float3 viewDir;
            float3 worldNormal;
            float3 worldPos;
            float4 screenPos;
            INTERNAL_DATA
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        float _GrazingThreshold;
        
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
            
            //o.dot = dot(v.normal, float3(0, 0, 1));
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            NoisifyNormals(IN.screenPos, o);
            
            half rim = 1.0 - saturate(dot (normalize(IN.viewDir), normalize(o.Normal)));
            float grazing =
                saturate((rim - _GrazingThreshold) / (1 - _GrazingThreshold))
                //saturate(pow(rim, 1))
                ;
            
            float2 screenUv = (IN.screenPos.xy / max(0.0001, IN.screenPos.w));
            float width = _ScreenParams.x / _ScreenParams.y;
            screenUv.x *= width;
            float2 uvOffset = float2(_WorldSpaceCameraPos.x, _WorldSpaceCameraPos.y) / 9.5;
            fixed3 perlin = tex2D (_PerlinTex, screenUv * 2 + uvOffset);
            
            float flaking = saturate(lerp(1, perlin, grazing));
                
            //o.Emission = _EmissionColor + flaking * float3(1, 0, 0);
            
            //NoisifyNormals(IN.screenPos, o);
            
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a * flaking;
            
            //clip(flaking - _GrazingThreshold);
        }
        ENDCG
    }
    
    
    
    //FallBack "Diffuse"
}
