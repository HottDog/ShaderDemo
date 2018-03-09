///菲尼尔效应的简单实现
Shader "Unlit/Fresnel"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	    _fresnelBase("frsnelBase",Range(0,1)) = 1
		_fresnelScale("fresnelScale",Range(0,1)) = 1
		_fresnelIndensity("fresnelIndensity",Range(0,5)) = 5
		_fresnelCol("fresnelCol",Color) = (1,1,1,1)
		//_Cubemap("Reflection Cubemap",Cube) = "_Skybox"{}
		//_fresnelColor("fresnelColor",Color)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			tags{ "lightmode="="forward" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
            #include "Lighting.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				//UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float3 L : TEXCOORD1;
				float3 N : TEXCOORD2;
				float3 V : TEXCOORD3;
				fixed3 worldRefl : TEXCOORD4;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			float _fresnelBase;
			float _fresnelScale;
			float _fresnelIndensity;
			float4 _fresnelCol;
			samplerCUBE _Cubemap;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				//UNITY_TRANSFER_FOG(o,o.vertex);
				//将法线转换到世界坐标
				o.N = mul(v.normal, (float3x3)unity_WorldToObject);
				//获取世界坐标的光向量,方向是从该点到光源
				o.L = WorldSpaceLightDir(v.vertex);
				//获取世界坐标的视角向量，方向是从该点到摄像机
				o.V = WorldSpaceViewDir(v.vertex);
				//获取摄像机射向顶点的反射向量
				o.worldRefl = reflect(-o.V, o.N);
				return o;
			}
			//主要思路：
			//将物体原来每个点的颜色和菲尔尼反射的颜色进行混合
			//--那么这里会有一个问题，就是怎么混合
			//----解决思路是线性混合，就是按原来的颜色和菲尼尔反射的颜色各占百分之多少进行简单的混合
			//------这里又有一个问题就是，如何确定各占的百分比
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				//提取立方贴图中的颜色值
				//fixed4 _fresnelCol = texCUBE(_Cubemap, i.worldRefl);
				//将向量转换成单元向量
				float3 N = normalize(i.N);
				float3 L = normalize(i.L);
				float3 V = normalize(i.V);
				//环境光的漫反射
				col.rgb *= saturate(dot(N, L))*_LightColor0.rgb;
				//计算菲尼尔系数，菲尼尔公式
				float fresnel = _fresnelBase + _fresnelScale*pow(1 - dot(N, V), _fresnelIndensity);
				//将要给物体的光照的颜色以菲尼尔系数和顶点颜色向混合，并乘上被混合光照颜色的透明度
				col.rgb = lerp(col.rgb, _fresnelCol, fresnel)*_fresnelCol.a;
				return col;
			}
			ENDCG
		}
	}
}
