// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Watercolor/Grass (Surface)"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _GrassShapeTex ("Grass Shape (R)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
        
        _GrazingThreshold ("Grazing Threshold", Range(0,1)) = 0.5
        _NoiseParallax ("Noise Parallax", Range(0,1)) = 0.075
        
        [HDR]
        _EmissionColor ("Emission", Color) = (0,0,0,1)
        
        _NearLightFactor ("Near Light Factor", Range(0,1)) = 1.0
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
                float3 viewDir : TEXCOORD2;
                float4 screenPos : TEXCOORD4;
                float3 worldPos : TEXCOORD5;
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
                o.worldPos = mul (unity_ObjectToWorld, v.vertex);
                
                return o;
            }
            
            uniform sampler2D _MainTex;
            uniform sampler2D _GrassShapeTex;
            uniform fixed _Cutoff;
            uniform fixed4 _Color;
            float _GrazingThreshold;
            float _NoiseParallax;
            
            float4 frag( v2f i ) : SV_Target
            {
                fixed4 texcol = tex2D( _MainTex, i.uv );
                
                half rim = 1.0 - saturate(dot (normalize(i.viewDir), normalize(i.normal)));
                
                // Little experiment: modulate grazing threshold by distance.
                float gt = _GrazingThreshold;//lerp(_GrazingThreshold * .25, _GrazingThreshold, (i.worldPos.z - 10) / 40);
                float grazing = saturate((rim - (1 - gt)) / (gt));
                
                float2 uv =
                    //float2(i.worldPos.x, i.worldPos.y) / 2
                    GetWorldAlignedUvStepped(i.worldPos)
                    //GetScreenAlignedUv(i.screenPos, 2, _NoiseParallax)
                ;
                
                fixed3 perlin = tex2D (_GrassShapeTex, uv);
                float flaking = saturate(lerp(1, perlin - grazing, grazing));
                
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

        uniform sampler2D _MainTex;
        uniform sampler2D _GrassShapeTex;

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
        float _NoiseParallax;
        
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
            NoisifyNormals(IN.screenPos, o, 2 * 1, .175 * 1);
            
            half rim = 1.0 - saturate(dot (normalize(IN.viewDir), normalize(o.Normal)));
            
            // Little experiment: modulate grazing threshold by distance.
            float gt = _GrazingThreshold;//lerp(_GrazingThreshold * .25, _GrazingThreshold, (IN.worldPos.z - 10) / 40);
            float grazing = saturate((rim - (1 - gt)) / (gt));
            
            float2 uv =
                    //float2(IN.worldPos.x, IN.worldPos.y) / 2
                    GetWorldAlignedUvStepped(IN.worldPos)
                    //GetScreenAlignedUv(IN.screenPos, 2, _NoiseParallax)
                ;
            
            fixed3 perlin = tex2D (_GrassShapeTex, uv);
            float flaking = saturate(lerp(1, perlin - grazing, grazing));
                
            //o.Emission = _EmissionColor + flaking * float3(1, 0, 0);
            
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a * flaking;
            o.Emission = DarkenNearZero(IN.worldPos) + _EmissionColor;
        }
        ENDCG
    }
    
    
    
    //FallBack "Diffuse"
}
