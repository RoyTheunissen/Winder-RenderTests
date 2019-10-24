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
            
            float3 rgb2hsv(float3 c) {
              float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
              float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
              float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

              float d = q.x - min(q.w, q.y);
              float e = 1.0e-10;
              return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
            }

            float3 hsv2rgb(float3 c) {
              c = float3(c.x, clamp(c.yz, 0.0, 1.0));
              float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
              float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
              return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
            }
            
            float valueRamp(float value)
            {
                return tex2D (_ValueRampTex, float2(value, 0.5));
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                
                // just invert the colors
                //col.rgb = 1 - col.rgb;
                
                float3 hsv = rgb2hsv(col.rgb);
                //hsv.b = valueRamp(hsv.b);
                //hsv.b = saturate(hsv.b * 1);
                hsv.b = max(hsv.b, 0);
                hsv.b = .5 + (hsv.b - .5) * 2.0;
                col = fixed4(hsv2rgb(hsv), col.a);
                
                //col *= 1.5;
                
                float2 screenUv = i.uv.xy;
                float width = _ScreenParams.x / _ScreenParams.y;
                
                screenUv.x *= width;
                float2 uvOffset = float2(_WorldSpaceCameraPos.x, _WorldSpaceCameraPos.y) / 5;
                fixed3 paper = tex2D (_PaperTex, screenUv + uvOffset);
                
                col.rgb += (1 - paper.r) * 0.4 * (1 - hsv.b * .5);
                
                //col.rgb *= tex2D (_ValueRampTex, float2(value, 0.5));
                
                return col;
            }
            ENDCG
        }
    }
}
