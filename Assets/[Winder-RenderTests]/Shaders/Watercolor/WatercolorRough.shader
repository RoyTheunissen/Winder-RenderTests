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
        
        _GrazingThresholdStart ("Grazing Threshold Start", Range(0,2)) = 0.25
        _GrazingThresholdEnd ("Grazing Threshold End", Range(0,2)) = 1.0
        _FlakingOffsetStart ("Flaking Offset Start", Range(0,2)) = 0.25
        _FlakingOffsetEnd ("Flaking Offset End", Range(0,2)) = 1.0
        _FlakingDistanceStart ("Flaking Distance Start", Range(-100,100)) = -10
        _FlakingDistanceEnd ("Flaking Distance End", Range(0,1000)) = 30
        _FlakingSizeStart ("Flaking Size Start", Range(1,100)) = 16
        _FlakingSizeEnd ("Flaking Size End", Range(1,6000)) = 64
        
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
            #include "..\Winder.cginc"
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"
            
            uniform float4 _MainTex_ST;
            
            uniform sampler2D _MainTex;
            uniform fixed _Cutoff;
            uniform fixed4 _Color;
            
            WINDING_FIELDS
            
            #include "Flaking.cginc"
            
            struct v2f { 
                V2F_SHADOW_CASTER;
                float2 uv : TEXCOORD1;
                float3 normal : NORMAL;
                float3 viewDir : TEXCOORD2;
                float4 screenPos : TEXCOORD4;
                float3 worldPos : TEXCOORD5;
                float3 viewDirWorld : TEXCOORD6;
            };
            
            v2f vert( appdata_base v )
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                
                o.viewDir = ObjSpaceViewDir(v.vertex);
                o.normal = v.normal;
                o.screenPos = ComputeScreenPos(UnityObjectToClipPos (v.vertex));
                o.worldPos = mul (unity_ObjectToWorld, v.vertex);
                
                PLANAR_WORLD_UVS_VERTEX(v, o);
                
                return o;
            }
            
            float4 frag( v2f i ) : SV_Target
            {
                fixed4 texcol = tex2D( _MainTex, i.uv );
                
                float flaking = GetFlakingShadowPass(i);
                
                clip( texcol.a*_Color.a*flaking - _Cutoff );
                
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        
        }

        CGPROGRAM
        
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Watercolor fullforwardshadows vertex:vert alphatest:_Cutoff

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0
        
        #include "..\Winder.cginc"

        sampler2D _MainTex;

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
        
        #include "Flaking.cginc"

        struct Input
        {
            float2 uv_MainTex;
            float3 viewDir;
            float3 worldNormal;
            float3 worldPos;
            float4 screenPos;
            INTERNAL_DATA
            PLANAR_WORLD_UVS_INPUT
        };
        
        void vert (inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input,o);
            PLANAR_WORLD_UVS_VERTEX(v, o);
            
            //o.dot = dot(v.normal, float3(0, 0, 1));
        }

        void surf (Input IN, inout SurfaceOutputWatercolor o)
        {
            NoisifyNormals(IN, o);
            
            float flaking = GetFlaking(IN, o);
            
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            
            // This is for debugging flaking.
            //float objectZ = max(GetObjectPosition().z, 0);
            //float gz = pow((objectZ - _FlakingDistanceStart) / (_FlakingDistanceEnd - _FlakingDistanceStart), 1);
            //c.rgb = lerp(float3(1, 0, 0), float3(0, 0, 1), gz);
            
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a * flaking;
            
            o.InverseLightFactor = GetDarknessFactor(IN.worldPos) - _NearLightFactor;
            
            AddNoisyLight(IN, o);
            
            o.Emission = _EmissionColor;
        }
        ENDCG
    }
    
    
    
    //FallBack "Diffuse"
}
