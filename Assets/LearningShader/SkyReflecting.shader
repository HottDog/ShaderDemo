// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/SkyReflecting"
{
	Properties
	{
		//_MainTex ("Texture", 2D) = "white" {}
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
			// #pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float3 worldRef : TEXCOORD0;
				// UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			// sampler2D _MainTex;
			// float4 _MainTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				//世界坐标
				float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
				//世界视角单位向量
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				//世界法向量
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				//世界视角的反射向量
				o.worldRef = reflect(-worldViewDir,worldNormal);
				// UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				
				fixed4 col = 0;
				//因为这里的CubeMap是当前环境的reflection probe cubemaps，被unity用特殊的方式保存，
				//所以要用特殊处理，而不能简单地用samplerCUBE和texCUBE
				half4 skyData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0,i.worldRef);
				//获取skyData的实际颜色
				half3 skyColor = DecodeHDR(skyData,unity_SpecCube0_HDR);
				col.rgb = skyColor;
				// apply fog
				// UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
