// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "DeepSky Haze/Example/Example (VertexFragment)"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }

		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			// We want all the atmospheric effects to be applied to this shader.
			#define DS_HAZE_FULL

			#include "UnityCG.cginc"

			// Now include the DeepSky Haze transparency library.
			#include "../../Resources/DS_TransparentLib.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;

				// We need two extra variables to pass the atmospherics between the vertex shader
				// where they are calculated, and the fragment shader where they are blended with
				// the scene.
				float3 air : TEXCOORD1;
				float3 hazeAndFog : TEXCOORD2;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Color;
			
			v2f vert (appdata v)
			{
				v2f o;
#if defined (UNITY_5_4_OR_NEWER)
				o.vertex = UnityObjectToClipPos(vtx.vertex.xyz);
#else
				o.vertex = UnityObjectToClipPos(v.vertex);
#endif
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				// Do the actual atmospheric calculations.
				DS_Haze_Per_Vertex(v.vertex, o.air, o.hazeAndFog);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv) * _Color;

				// Finally apply the atmospheric effects to our final colour. This should be
				// the last thing done in the shader before returning the colour.
				DS_Haze_Apply(i.air, i.hazeAndFog, col, col.a);
				return col;
			}
			ENDCG
		}
	}
}


