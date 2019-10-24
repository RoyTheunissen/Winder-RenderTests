Shader "DeepSky Haze/Example/Example (Surface)" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
	}
	SubShader{
		Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }

		CGPROGRAM
		// Add the vertex and finalcolor modifier functions to this line.
		#pragma surface surf Standard fullforwardshadows alpha:fade vertex:MyVertexFunc finalcolor:MyFinalColorFunc
		#pragma target 3.0

		// We want all the atmospheric effects to be applied to this shader.
		#define DS_HAZE_FULL

		// Now include the DeepSky Haze transparency library.
		#include "../../Resources/DS_TransparentLib.cginc"

		// The usual input structure, with added DeepSky Haze support.
		struct Input {
			float2 uv_MainTex;
			DEEPSKY_HAZE_DECLARE_INPUT;
		};

		// This is our custom vertex modifier function where we actually calculate the atmospherics.
		inline void MyVertexFunc(inout appdata_full vtx, out Input output)
		{
			UNITY_INITIALIZE_OUTPUT(Input, output);

			DEEPSKY_HAZE_VERTEX_MOD(vtx, output);
		}

		// This is where the atmospherics are finally composed with the scene.
		inline void MyFinalColorFunc(Input IN, SurfaceOutputStandard o, inout fixed4 color)
		{
			DEEPSKY_HAZE_FINAL_COLOR(IN, o, color);
		}

		// That's it! From here on the shader can do whatever you like as normal.
		sampler2D _MainTex;
		fixed4 _Color;

		void surf (Input IN, inout SurfaceOutputStandard o) {
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			o.Alpha = c.a;
		}
		ENDCG
	} 
	FallBack "Diffuse"
}




