Shader "Unlit/fire"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Noise("_Noise",2D) = "gray"{}
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
			sampler2D _Noise;
			float4 _Noise_ST;
			
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
				
				fixed4 noiseCol = tex2D(_Noise, i.uv);
				fixed2 offset = fixed2(noiseCol.r,noiseCol.g);
				//颜色值是(0,1),但是我们要的uv扰动值为(-1,1)，所以要从(0,1)变到(-1,1)
				offset = offset * 2 -1;
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv+offset);
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
