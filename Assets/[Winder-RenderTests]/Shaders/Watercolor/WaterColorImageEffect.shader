Shader "Hidden/WaterColorImageEffect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ValueRampTex ("Value Ramp (RGB)", 2D) = "white" {}
        _PaperTex ("Paper (RGB)", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "..\Winder.cginc"

            #include "UnityCG.cginc"
            
            WINDING_FIELDS
            
            #include "Watercolor.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 viewDirWorld : TEXCOORD1;
            };

            sampler2D _MainTex;
            sampler2D _ValueRampTex;
            sampler2D _PaperTex;
            
            float4x4 _ViewToWorldMatrix;
            float4x4 _ProjectionToViewMatrix;

            v2f vert (appdata v)
            {
                v2f o;
                    
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                
                float4 clipPos = o.vertex;
                
                // This is needed because the projection matrix can be flipped... If we don't compensate for that here then if
                // another image effect is enabled, the view directions will be flipped.
                clipPos.y *= _ProjectionParams.x;
                
                // Transform the clip position into camera or 'view' space. Note that we need to multiply by w.
                float4 viewPos = mul(_ProjectionToViewMatrix, clipPos);
                viewPos = float4(viewPos.xyz * viewPos.w, 1);
                
                // Camera of 'view' space can then easily be transformed into world space.
                float3 worldPos = mul(_ViewToWorldMatrix, viewPos);
                
                // Now that we have a world position matching the screen vertex, it's business as usual.
                o.viewDirWorld = UnityWorldSpaceViewDir(worldPos);
                
                return o;
            }
            
            float push(float v)
            {
                return max(0, .5 + (v - .5) * 2.0);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                
                // Don't convert the color into HSV and back because that messes with HDR values.
                float3 hsv = rgb2hsv(col.rgb);
                //hsv.b = max(hsv.b, 0);
                //hsv.b = .5 + (hsv.b - .5) * 2.0;
                //col = fixed4(hsv2rgb(hsv), col.a);
                
                col = fixed4(push(col.r), push(col.g), push(col.b), col.a);
                
                // Apply a paper texture that is position on a plane at world-space z 0.
                float2 uv = GetPlanarWorldSpaceUvFromViewDirection(normalize(i.viewDirWorld), float3(0, 0, 0)) / 4;
                fixed3 paper = tex2D (_PaperTex, uv);
                
                float paperValue = (1 - paper.r) * lerp(.2, .9, saturate(hsv.b));
                col.rgb += paperValue;
                
                return col;
            }
            ENDCG
        }
    }
}
