Shader "Unlit/Simple"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_AAFactor("滤波系数",Range(0,20)) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _AAFactor;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				//fixed4 col = tex2D(_MainTex, i.uv,_AAFactor,_AAFactor);
				fixed2 uv = i.uv;
				//fixed4 col = tex2D(_MainTex, i.uv);
				uv.xy -= 0.5;
				fixed2 w = fwidth(uv);
				fixed4 col = tex2D(_MainTex, (floor(uv) + 0.5 + min(frac(uv) / min(w, 1.0), 1.0)) / float2(568,256));
				//float w = fwidth(0.5*d) * 2.0;
				//col = lerp(_OutlineColor.rgb, col, smoothstep(-w, w, d - _OutlineWidth));
				//col = lerp(_LineColor.rgb, col, smoothstep(-w, w, d));
				col = pow(col, fixed(1 / 2.2f));
				return col;
			}
			ENDCG
		}
	}
}
