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

            #include "UnityCG.cginc"
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
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            sampler2D _ValueRampTex;
            sampler2D _PaperTex;
            
            float push(float v)
            {
                return max(0, .5 + (v - .5) * 2.0);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                
                // just invert the colors
                //col.rgb = 1 - col.rgb;
                
                float3 hsv = rgb2hsv(col.rgb);
                //hsv.b = max(hsv.b, 0);
                //hsv.b = .5 + (hsv.b - .5) * 2.0;
                //col = fixed4(hsv2rgb(hsv), col.a);
                col = fixed4(push(col.r), push(col.g), push(col.b), col.a);
                
                //col *= 1.5;
                
                float2 uv = GetScreenAlignedUv(i.uv, 2);
                
                fixed3 paper = tex2D (_PaperTex, uv);
                
                col.rgb += (1 - paper.r) * 0.4 * (1 - saturate(hsv.b) * .5);
                
                //col.rgb *= tex2D (_ValueRampTex, float2(value, 0.5));
                
                return col;
            }
            ENDCG
        }
    }
}
