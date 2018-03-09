Shader "Unlit/Show"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_NoiseTex("NoiseTex",2D) = "gray"{}
		_StartTime("StartTime",float) = 0
		_Speed("Speed(s)",float) = 1

		_EdgeColor("EdgeColor",Color) = (1,1,1,1)
		_EdgeWidth("EdgeWidth",Range(0,0.5)) = 0.1
	}
	SubShader
	{
		Tags{ "RenderType" = "Opaque" }
		LOD 100

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

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _NoiseTex;
			float _Speed;
			float _StartTime;

			float4 _EdgeColor;
			float _EdgeWidth;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				//溶解阈值：低于溶解阈值的部分都会被溶解，溶解阈值会随着时间不断变大
				float DissolveFactor = saturate((_Time.y - _StartTime) / _Speed);
				float noiseValue = tex2D(_NoiseTex, i.uv).r;  //取r通道
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				//对将要溶解的部分进行特殊颜色渲染
				//待溶解系数，越小临溶解越近
				float EdgeFactor = saturate((noiseValue - DissolveFactor) / (_EdgeWidth*DissolveFactor));
				float4 BlendColor = col * _EdgeColor;
				clip(1 - EdgeFactor - 0.01);
				return lerp(col, BlendColor,EdgeFactor);
				//return col;
			}
			ENDCG
		}
	}
}