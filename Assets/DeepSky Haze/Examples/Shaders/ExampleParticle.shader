// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

/*
This is very similar to Particle Alpha Blend from Unity's standard shaders, with added support for DeepSky Haze.
The setup is identical to the example DeepSky Haze Vertex/Fragment shader, but shows a more complex example of
integrating into an existing shader.

(For the original source, download the Built In Shaders zip, available on the Unity download page).
*/
Shader "DeepSky Haze/Example/Example (Particle)" {
	Properties{
		_MainTex("Particle Texture", 2D) = "white" {}
		_InvFade("Soft Particles Factor", Range(0.01,3.0)) = 1.0
	}

	Category{
		Tags{ "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
		Blend SrcAlpha OneMinusSrcAlpha
		ColorMask RGB
		Cull Off Lighting Off ZWrite Off

		SubShader{
			Pass{

				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile_particles

				// We want all the atmospheric effects to be applied to this shader.
				#define DS_HAZE_FULL

				#include "UnityCG.cginc"

				// Now include the DeepSky Haze transparency library.
				#include "../../Resources/DS_TransparentLib.cginc"

				sampler2D _MainTex;
				fixed4 _TintColor;

				struct appdata_t {
					float4 vertex : POSITION;
					fixed4 color : COLOR;
					float2 texcoord : TEXCOORD0;
				};

				struct v2f {
					float4 vertex : SV_POSITION;
					fixed4 color : COLOR;
					float2 texcoord : TEXCOORD0;

					// We need two extra variables to pass the atmospherics between the vertex shader
					// where they are calculated, and the fragment shader where they are blended with
					// the scene.
					float3 air : TEXCOORD1;
					float3 hazeAndFog : TEXCOORD2;

			#ifdef SOFTPARTICLES_ON
					// Note: in the original shader, projPos is passed as TEXCOORD1.
					float4 projPos : TEXCOORD3;
			#endif
				};

				float4 _MainTex_ST;

				v2f vert(appdata_t v)
				{
					v2f o;
			#if defined (UNITY_5_4_OR_NEWER)
					o.vertex = UnityObjectToClipPos(vtx.vertex.xyz);
			#else
					o.vertex = UnityObjectToClipPos(v.vertex);
			#endif
			#ifdef SOFTPARTICLES_ON
					o.projPos = ComputeScreenPos(o.vertex);
					COMPUTE_EYEDEPTH(o.projPos.z);
			#endif
					o.color = v.color;
					o.texcoord = TRANSFORM_TEX(v.texcoord,_MainTex);

					// Do the actual atmospheric calculations.
					DS_Haze_Per_Vertex(v.vertex, o.air, o.hazeAndFog);
					return o;
				}

				sampler2D_float _CameraDepthTexture;
				float _InvFade;

				fixed4 frag(v2f i) : SV_Target
				{
			#ifdef SOFTPARTICLES_ON
					float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
					float partZ = i.projPos.z;
					float fade = saturate(_InvFade * (sceneZ - partZ));
					i.color.a *= fade;
			#endif

					fixed4 col = i.color * tex2D(_MainTex, i.texcoord) * i.color.a;

					// Finally apply the atmospheric effects to our final colour. This should be
					// the last thing done in the shader before returning the colour.
					DS_Haze_Apply(i.air, i.hazeAndFog, col, col.a);
					return col;
				}
				ENDCG
			}
		}
	}
}
