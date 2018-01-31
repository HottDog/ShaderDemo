Shader "Unlit/SimpleDistortion"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Twist("Twist(旋转系数)",float) = 1
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
			//贴图上每个像素的尺寸
			float4 _MainTex_TexelSize;
			float _Twist;
			
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
				fixed2 tuv = i.uv;
				//uv坐标往中心点移动
				fixed2 uv = fixed2(tuv.x - 0.5, tuv.y - 0.5);
				//通过距离计算出当前点的旋转弧度 PI/180 = 0.1745
				//因为uv坐标被往中心点移动了，所以length(uv)其实算的是原来的uv坐标距离中心点的距离
				//如此，就算得的角度跟原uv坐标跟中心点的坐标成反比，距离越小，角度越大
				//根据后面的旋转矩阵，可以得出基本思路是，每个uv点的旋转程度跟uv点离中心点的距离有关，
				//距离越大，旋转角度越小，距离越小，旋转角度越大
				//_Twist是一个旋转系数，控制旋转的程度
				float angle = _Twist * 0.1745 / (length(uv) + 0.1);
				float sinval, cosval;
				sincos(angle, sinval, cosval);
				//这个旋转矩阵为什么是这样？这个旋转矩阵的确切效果是如何？
				//--旋转矩阵的效果是绕中心点画圆旋转
				float2x2 mat = float2x2(cosval, -sinval, sinval, cosval);
				//用旋转矩阵对点进行旋转，然后加回0.5，抵消一开始往中心点移动的效果
				uv = mul(mat, uv) + 0.5;
				fixed4 col = tex2D(_MainTex, uv);
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
