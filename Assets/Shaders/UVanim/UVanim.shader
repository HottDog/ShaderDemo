Shader "Unlit/UVanim"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Noise("Noise",2D) = "gray"{}
		_xLeft("_xLeft",Range(0,1)) = 0.5
		_xRight("_xRight",Range(0,1)) = 0.5
		_yLeft("_yLeft",Range(0,1)) = 0.5
		_yRight("_yRight",Range(0,1)) = 0.5
		_posOffset("_posOffset",Vector) = (0,0,0,0)

		_Speed("Speed",float) = 0

		_HeatTime("火焰抖动的频率",Range(0,1.5)) = 1
		_HeatForce("火焰抖动的幅度",Range(0,0.1)) = 0.1
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
			float _xLeft;
			float _xRight;
			float _yLeft;
			float _yRight;
			float4 _posOffset;
			float _Speed;

			float _HeatTime;
			float _HeatForce;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.vertex += _posOffset;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed2 uv = i.uv;
				
				//uv.x += _Time.y/10;
				//uv += float2(_Speed*_Time.y,0);
				//float4 noiseTex = tex2D(_Noise, uv);
				/*float2 offsetUV = float2(noiseTex.r, noiseTex.g);
				offsetUV = (offsetUV - 0.5) * 2;
				offsetUV +=  _Time.y;*/
				half4 offsetColor1 = tex2D(_Noise, i.uv + _Time.xz*_HeatTime);   //偏向于向上抖动
				half4 offsetColor2 =tex2D(_Noise, i.uv - _Time.xy*_HeatTime);   //偏向于向下抖动
				//将两种区别的抖动方式叠加到一起
				i.uv.x += (offsetColor1.r + offsetColor2.r)*_HeatForce;
				i.uv.y += (offsetColor1.g + offsetColor2.g)*_HeatForce;

				                              
				fixed4 col = tex2D(_MainTex, i.uv);// +offsetUV);
				// apply fog
				if (_xLeft <= uv.x &&uv.x <= _xRight && _yLeft <= uv.y&&uv.y <= _yRight)
				{
					//col.rgb += fixed3(0.5, 0.5, 0.5);
					//col.b = 1;
					
				}
					
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
